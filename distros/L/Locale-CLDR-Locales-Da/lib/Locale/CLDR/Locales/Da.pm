=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Da - Package for language Danish

=cut

package Locale::CLDR::Locales::Da;
# This file auto generated from Data\common\main\da.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-common','spellout-cardinal-neuter','spellout-ordinal-common','spellout-ordinal-neuter' ]},
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
					rule => q(og =%spellout-cardinal-common=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-common=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-common=),
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
		'ord-de-c' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(de),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' og =%spellout-ordinal-common=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' og =%spellout-ordinal-common=),
				},
			},
		},
		'ord-de-n' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(de),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' og =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' og =%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-e-c' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(e),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' og =%spellout-ordinal-common=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-ordinal-common=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-ordinal-common=),
				},
			},
		},
		'ord-e-n' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(e),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' og =%spellout-ordinal-neuter=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-te-c' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-common=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-common=),
				},
			},
		},
		'ord-te-n' => {
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
		'ord-teer-c' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-common=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-common=),
				},
			},
		},
		'ord-teer-n' => {
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
		'spellout-cardinal-common' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nul),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(en),
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
					rule => q(syv),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(otte),
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
					rule => q([→→­og­]tyve),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→→­og­]tredive),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→→­og­]fyrre),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→→­og­]halvtreds),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→→­og­]tres),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→→­og­]halvfjerds),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→→­og­]firs),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→→­og­]halvfems),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundrede[ og →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrede[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusinde[ →%%and-small→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusinde[ →%%and-small→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← millioner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← milliarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← billioner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(billiard[ →→]),
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
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nul),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(et),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-common=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundrede[ og →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrede[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusind[ →%%and-small-n→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusind[ →%%and-small-n→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(en million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-common← millioner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(en milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-common← milliarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(en billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-common← billioner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(en billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-common← billiarder[ →→]),
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
					rule => q(←←­hundrede[ og →→]),
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
		'spellout-ordinal-common' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulte),
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
					rule => q(anden),
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
					rule => q(syvende),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ottende),
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
					rule => q(=%spellout-numbering=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-numbering→­og­]tyvende),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-numbering→­og­]tredivte),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-numbering→­og­]fyrrende),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%spellout-numbering=indstyvende),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundrede→%%ord-de-c→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-numbering← hundrede→%%ord-de-c→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusind→%%ord-e-c→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← tusind→%%ord-e-c→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(million→%%ord-te-c→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-numbering← million→%%ord-teer-c→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(milliard→%%ord-te-c→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-numbering← milliard→%%ord-teer-c→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(billion→%%ord-te-c→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering← billion→%%ord-teer-c→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(billiard→%%ord-te-c→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-numbering← billiard→%%ord-teer-c→),
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
					rule => q(nulte),
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
					rule => q(andet),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-common=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→­og­]tyvende),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→­og­]tredivte),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→­og­]fyrrende),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=indstyvende),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundrede→%%ord-de-n→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter← hundrede→%%ord-de-n→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusinde→%%ord-e-n→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusind→%%ord-e-n→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(million→%%ord-teer-n→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← million→%%ord-teer-n→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(milliard→%%ord-te-n→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← milliard→%%ord-teer-n→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(billion→%%ord-te-n→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← billion→%%ord-teer-n→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(billiard→%%ord-te-n→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← billiard→%%ord-teer-n→),
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
 				'ady' => 'adyghe',
 				'ae' => 'avestan',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkadisk',
 				'ale' => 'aleutisk',
 				'alt' => 'sydaltaisk',
 				'am' => 'amharisk',
 				'an' => 'aragonsk',
 				'ang' => 'oldengelsk',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabisk',
 				'ar_001' => 'moderne standardarabisk',
 				'arc' => 'aramæisk',
 				'arn' => 'mapudungun',
 				'arp' => 'arapaho',
 				'ars' => 'Najd-arabisk',
 				'ars@alt=menu' => 'arabisk, najdi',
 				'arw' => 'arawak',
 				'as' => 'assamesisk',
 				'asa' => 'asu',
 				'ast' => 'asturisk',
 				'atj' => 'atikamekw',
 				'av' => 'avarisk',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'aserbajdsjansk',
 				'az@alt=short' => 'azeri',
 				'ba' => 'bashkir',
 				'bal' => 'baluchi',
 				'ban' => 'balinesisk',
 				'bas' => 'basaa',
 				'bax' => 'bamun',
 				'bbj' => 'ghomala',
 				'be' => 'belarusisk',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'bulgarsk',
 				'bgc' => 'harianvi',
 				'bgn' => 'vestbaluchi',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'blo' => 'anii',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetansk',
 				'br' => 'bretonsk',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosnisk',
 				'bss' => 'bakossi',
 				'bua' => 'buriatisk',
 				'bug' => 'buginesisk',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'catalansk',
 				'cad' => 'caddo',
 				'car' => 'caribisk',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'tjetjensk',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'chagatai',
 				'chk' => 'chuukese',
 				'chm' => 'mari',
 				'chn' => 'chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'sorani',
 				'ckb@alt=menu' => 'kurdisk, sorani',
 				'ckb@alt=variant' => 'centralkurdisk',
 				'clc' => 'chilcotin',
 				'co' => 'korsikansk',
 				'cop' => 'koptisk',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'krimtatarisk',
 				'crj' => 'sydøstcree',
 				'crk' => 'plains cree',
 				'crl' => 'nordøstcree',
 				'crm' => 'Moose-cree',
 				'crr' => 'carolina algonquisk',
 				'crs' => 'seselwa (kreol-fransk)',
 				'cs' => 'tjekkisk',
 				'csb' => 'kasjubisk',
 				'csw' => 'swampy cree',
 				'cu' => 'kirkeslavisk',
 				'cv' => 'tjuvasjisk',
 				'cy' => 'walisisk',
 				'da' => 'dansk',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'tysk',
 				'de_AT' => 'østrigsk tysk',
 				'de_CH' => 'schweizerhøjtysk',
 				'del' => 'delaware',
 				'den' => 'athapaskisk',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'nedersorbisk',
 				'dua' => 'duala',
 				'dum' => 'middelhollandsk',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'kiembu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'oldegyptisk',
 				'eka' => 'ekajuk',
 				'el' => 'græsk',
 				'elx' => 'elamitisk',
 				'en' => 'engelsk',
 				'en_AU' => 'australsk engelsk',
 				'en_CA' => 'canadisk engelsk',
 				'en_GB' => 'britisk engelsk',
 				'en_US' => 'amerikansk engelsk',
 				'enm' => 'middelengelsk',
 				'eo' => 'esperanto',
 				'es' => 'spansk',
 				'es_419' => 'latinamerikansk spansk',
 				'es_ES' => 'europæisk spansk',
 				'es_MX' => 'mexicansk spansk',
 				'et' => 'estisk',
 				'eu' => 'baskisk',
 				'ewo' => 'ewondo',
 				'fa' => 'persisk',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finsk',
 				'fil' => 'filippinsk',
 				'fj' => 'fijiansk',
 				'fo' => 'færøsk',
 				'fon' => 'fon',
 				'fr' => 'fransk',
 				'fr_CA' => 'canadisk fransk',
 				'fr_CH' => 'schweizisk fransk',
 				'frc' => 'cajunfransk',
 				'frm' => 'middelfransk',
 				'fro' => 'oldfransk',
 				'frr' => 'nordfrisisk',
 				'frs' => 'østfrisisk',
 				'fur' => 'friulisk',
 				'fy' => 'vestfrisisk',
 				'ga' => 'irsk',
 				'gaa' => 'ga',
 				'gag' => 'gagauzisk',
 				'gan' => 'gan-kinesisk',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'skotsk gælisk',
 				'gez' => 'geez',
 				'gil' => 'gilbertesisk',
 				'gl' => 'galicisk',
 				'gmh' => 'middelhøjtysk',
 				'gn' => 'guarani',
 				'goh' => 'oldhøjtysk',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotisk',
 				'grb' => 'grebo',
 				'grc' => 'oldgræsk',
 				'gsw' => 'schweizertysk',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'hakka-kinesisk',
 				'haw' => 'hawaiiansk',
 				'hax' => 'sydhaida',
 				'he' => 'hebraisk',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'hiligaynon',
 				'hit' => 'hittitisk',
 				'hmn' => 'hmong',
 				'ho' => 'hirimotu',
 				'hr' => 'kroatisk',
 				'hsb' => 'øvresorbisk',
 				'hsn' => 'xiang-kinesisk',
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
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiaq',
 				'ikt' => 'vestcanadisk inuktitut',
 				'ilo' => 'iloko',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandsk',
 				'it' => 'italiensk',
 				'iu' => 'inuktitut',
 				'ja' => 'japansk',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'jødisk-persisk',
 				'jrb' => 'jødisk-arabisk',
 				'jv' => 'javanesisk',
 				'ka' => 'georgisk',
 				'kaa' => 'karakalpakisk',
 				'kab' => 'kabylsk',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardian',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kapverdisk',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotanesisk',
 				'khq' => 'koyra-chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kasakhisk',
 				'kkj' => 'kako',
 				'kl' => 'grønlandsk',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreansk',
 				'koi' => 'komi-permjakisk',
 				'kok' => 'konkani',
 				'kos' => 'kosraean',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karatjai-balkar',
 				'krl' => 'karelsk',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurdisk',
 				'kum' => 'kymyk',
 				'kut' => 'kutenaj',
 				'kv' => 'komi',
 				'kw' => 'cornisk',
 				'kwk' => 'kwakʼwala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirgisisk',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxembourgsk',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgsk',
 				'lij' => 'ligurisk',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardisk',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'Louisiana-kreolsk',
 				'loz' => 'lozi',
 				'lrc' => 'nordluri',
 				'lsm' => 'saamia',
 				'lt' => 'litauisk',
 				'lu' => 'luba-Katanga',
 				'lua' => 'luba-Lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'lus' => 'lushai',
 				'luy' => 'luyana',
 				'lv' => 'lettisk',
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
 				'mfe' => 'morisyen',
 				'mg' => 'malagassisk',
 				'mga' => 'middelirsk',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta',
 				'mh' => 'marshallese',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedonsk',
 				'ml' => 'malayalam',
 				'mn' => 'mongolsk',
 				'mnc' => 'manchu',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malajisk',
 				'mt' => 'maltesisk',
 				'mua' => 'mundang',
 				'mul' => 'flere sprog',
 				'mus' => 'creek',
 				'mwl' => 'mirandesisk',
 				'mwr' => 'marwari',
 				'my' => 'burmesisk',
 				'mye' => 'myene',
 				'myv' => 'erzya',
 				'mzn' => 'mazenisk',
 				'na' => 'nauru',
 				'nan' => 'min-kinesisk',
 				'nap' => 'napolitansk',
 				'naq' => 'nama',
 				'nb' => 'bokmål',
 				'nd' => 'nordndebele',
 				'nds' => 'nedertysk',
 				'nds_NL' => 'plattysk (Holland)',
 				'ne' => 'nepalesisk',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueansk',
 				'nl' => 'nederlandsk',
 				'nl_BE' => 'flamsk',
 				'nmg' => 'kwasio',
 				'nn' => 'nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norsk',
 				'nog' => 'nogai',
 				'non' => 'oldislandsk',
 				'nqo' => 'n’ko',
 				'nr' => 'sydndebele',
 				'nso' => 'nordsotho',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'klassisk newarisk',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro-sprog',
 				'nzi' => 'nzima',
 				'oc' => 'occitansk',
 				'oj' => 'ojibwa',
 				'ojb' => 'nordvestojibwa',
 				'ojc' => 'centralojibwa',
 				'ojs' => 'oji-cree',
 				'ojw' => 'vestojibwa',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'ossetisk',
 				'osa' => 'osage',
 				'ota' => 'osmannisk tyrkisk',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauansk',
 				'pcm' => 'nigeriansk pidgin',
 				'peo' => 'oldpersisk',
 				'phn' => 'fønikisk',
 				'pi' => 'pali',
 				'pis' => 'pijin',
 				'pl' => 'polsk',
 				'pon' => 'ponape',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'preussisk',
 				'pro' => 'oldprovencalsk',
 				'ps' => 'pashto',
 				'ps@alt=variant' => 'pushto',
 				'pt' => 'portugisisk',
 				'pt_BR' => 'brasiliansk portugisisk',
 				'pt_PT' => 'europæisk portugisisk',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rhg' => 'rohingya',
 				'rm' => 'rætoromansk',
 				'rn' => 'rundi',
 				'ro' => 'rumænsk',
 				'ro_MD' => 'moldovisk',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'ru' => 'russisk',
 				'rup' => 'arumænsk',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakutisk',
 				'sam' => 'samaritansk aramæisk',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardinsk',
 				'scn' => 'siciliansk',
 				'sco' => 'skotsk',
 				'sd' => 'sindhi',
 				'sdh' => 'sydkurdisk',
 				'se' => 'nordsamisk',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sel' => 'selkupisk',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'oldirsk',
 				'sh' => 'serbokroatisk',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'tchadisk arabisk',
 				'si' => 'singalesisk',
 				'sid' => 'sidamo',
 				'sk' => 'slovakisk',
 				'sl' => 'slovensk',
 				'slh' => 'sydlushootseed',
 				'sm' => 'samoansk',
 				'sma' => 'sydsamisk',
 				'smj' => 'lulesamisk',
 				'smn' => 'enaresamisk',
 				'sms' => 'skoltesamisk',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdiansk',
 				'sq' => 'albansk',
 				'sr' => 'serbisk',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sydsotho',
 				'str' => 'straits salish',
 				'su' => 'sundanesisk',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerisk',
 				'sv' => 'svensk',
 				'sw' => 'swahili',
 				'sw_CD' => 'congolesisk swahili',
 				'swb' => 'comorisk',
 				'syc' => 'klassisk syrisk',
 				'syr' => 'syrisk',
 				'szl' => 'schlesisk',
 				'ta' => 'tamil',
 				'tce' => 'sydtutchone',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadsjikisk',
 				'tgx' => 'tagish',
 				'th' => 'thai',
 				'tht' => 'tahltan',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tiv' => 'tivi',
 				'tk' => 'turkmensk',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tmh' => 'tamashek',
 				'tn' => 'tswana',
 				'to' => 'tongansk',
 				'tog' => 'nyasa tongansk',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'tyrkisk',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshisk',
 				'tt' => 'tatarisk',
 				'ttm' => 'nordtutchone',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluansk',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiansk',
 				'tyv' => 'tuvinian',
 				'tzm' => 'centralmarokkansk tamazight',
 				'udm' => 'udmurt',
 				'ug' => 'uygurisk',
 				'ug@alt=variant' => 'uighurisk',
 				'uga' => 'ugaristisk',
 				'uk' => 'ukrainsk',
 				'umb' => 'umbundu',
 				'und' => 'ukendt sprog',
 				'ur' => 'urdu',
 				'uz' => 'usbekisk',
 				've' => 'venda',
 				'vec' => 'venetiansk',
 				'vi' => 'vietnamesisk',
 				'vmw' => 'makhuwa',
 				'vo' => 'volapyk',
 				'vot' => 'votisk',
 				'vun' => 'vunjo',
 				'wa' => 'vallonsk',
 				'wae' => 'walsertysk',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'walbiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu-kinesisk',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xnr' => 'kangri',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapese',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddisch',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantonesisk',
 				'yue@alt=menu' => 'kantonesisk (Kina)',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'blissymboler',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight',
 				'zh' => 'kinesisk',
 				'zh@alt=menu' => 'mandarin (Kina)',
 				'zh_Hans' => 'forenklet kinesisk',
 				'zh_Hant' => 'traditionelt kinesisk',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'intet sprogligt indhold',
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
 			'Arab' => 'arabisk',
 			'Arab@alt=variant' => 'persisk-arabisk',
 			'Aran' => 'nastaliq',
 			'Armi' => 'armi',
 			'Armn' => 'armensk',
 			'Avst' => 'avestansk',
 			'Bali' => 'balinesisk',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa',
 			'Batk' => 'batak',
 			'Beng' => 'bengali',
 			'Blis' => 'blissymboler',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'bramisk',
 			'Brai' => 'punktskrift',
 			'Bugi' => 'buginesisk',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'oprindelige canadiske symboler',
 			'Cari' => 'kariansk',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirt',
 			'Copt' => 'koptisk',
 			'Cprt' => 'cypriotisk',
 			'Cyrl' => 'kyrillisk',
 			'Cyrs' => 'kyrillisk - oldkirkeslavisk variant',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'Duploya-stenografi',
 			'Egyd' => 'egyptisk demotisk',
 			'Egyh' => 'egyptisk hieratisk',
 			'Egyp' => 'egyptiske hieroglyffer',
 			'Ethi' => 'etiopisk',
 			'Geok' => 'georgisk kutsuri',
 			'Geor' => 'georgisk',
 			'Glag' => 'glagolitisk',
 			'Goth' => 'gotisk',
 			'Gran' => 'grantha',
 			'Grek' => 'græsk',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han med bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'forenklet',
 			'Hans@alt=stand-alone' => 'forenklet han',
 			'Hant' => 'traditionelt',
 			'Hant@alt=stand-alone' => 'traditionelt han',
 			'Hebr' => 'hebraisk',
 			'Hira' => 'hiragana',
 			'Hluw' => 'anatolske hieroglyffer',
 			'Hmng' => 'pahawh hmong',
 			'Hrkt' => 'japanske skrifttegn',
 			'Hung' => 'oldungarsk',
 			'Inds' => 'indus',
 			'Ital' => 'Olditalisk',
 			'Jamo' => 'jamo',
 			'Java' => 'javanesisk',
 			'Jpan' => 'japansk',
 			'Jurc' => 'jurchen',
 			'Kali' => 'kaya li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshti',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khojki',
 			'Knda' => 'kannada',
 			'Kore' => 'koreansk',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kthi',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'latinsk - frakturvariant',
 			'Latg' => 'latinsk - gælisk variant',
 			'Latn' => 'latinsk',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineær A',
 			'Linb' => 'lineær B',
 			'Lisu' => 'lisu',
 			'Loma' => 'loma',
 			'Lyci' => 'lykisk',
 			'Lydi' => 'lydisk',
 			'Mand' => 'mandaisk',
 			'Mani' => 'manikæisk',
 			'Maya' => 'mayahieroglyffer',
 			'Mend' => 'mende',
 			'Merc' => 'metroitisk sammenhængende',
 			'Mero' => 'meroitisk',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolsk',
 			'Moon' => 'moon',
 			'Mroo' => 'mroo',
 			'Mtei' => 'meitei-mayek',
 			'Mymr' => 'burmesisk',
 			'Narb' => 'gammelt nordarabisk',
 			'Nbat' => 'nabateisk',
 			'Nkgb' => 'nakhi geba',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol-chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osma' => 'osmannisk',
 			'Palm' => 'palmyrensk',
 			'Perm' => 'oldpermisk',
 			'Phag' => 'phags-pa',
 			'Phli' => 'phli',
 			'Phlp' => 'phlp',
 			'Phlv' => 'pahlavi',
 			'Phnx' => 'fønikisk',
 			'Plrd' => 'pollardtegn',
 			'Prti' => 'prti',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongo-rongo',
 			'Runr' => 'runer',
 			'Samr' => 'samaritansk',
 			'Sara' => 'sarati',
 			'Sarb' => 'oldsørarabisk',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'tegnskrift',
 			'Shaw' => 'shavisk',
 			'Shrd' => 'sharada',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'singalesisk',
 			'Sora' => 'sora',
 			'Sund' => 'sundanesisk',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syrisk',
 			'Syre' => 'syrisk - estrangelovariant',
 			'Syrj' => 'vestsyrisk',
 			'Syrn' => 'østsyriakisk',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue',
 			'Taml' => 'tamilsk',
 			'Tang' => 'tangut',
 			'Tavt' => 'tavt',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandsk',
 			'Tibt' => 'tibetansk',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaritisk',
 			'Vaii' => 'vai',
 			'Visp' => 'synlig tale',
 			'Wara' => 'varang kshiti',
 			'Wole' => 'woleai',
 			'Xpeo' => 'oldpersisk',
 			'Xsux' => 'sumero-akkadisk cuneiform',
 			'Yiii' => 'yi',
 			'Zinh' => 'arvet',
 			'Zmth' => 'matematisk notation',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symboler',
 			'Zxxx' => 'uden skriftsprog',
 			'Zyyy' => 'fælles',
 			'Zzzz' => 'ukendt skriftsprog',

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
			'001' => 'Verden',
 			'002' => 'Afrika',
 			'003' => 'Nordamerika',
 			'005' => 'Sydamerika',
 			'009' => 'Oceanien',
 			'011' => 'Vestafrika',
 			'013' => 'Mellemamerika',
 			'014' => 'Østafrika',
 			'015' => 'Nordafrika',
 			'017' => 'Centralafrika',
 			'018' => 'Det sydlige Afrika',
 			'019' => 'Nord-, Mellem- og Sydamerika',
 			'021' => 'Det nordlige Amerika',
 			'029' => 'Caribien',
 			'030' => 'Østasien',
 			'034' => 'Sydasien',
 			'035' => 'Sydøstasien',
 			'039' => 'Sydeuropa',
 			'053' => 'Australasien',
 			'054' => 'Melanesien',
 			'057' => 'Mikronesiske område',
 			'061' => 'Polynesien',
 			'142' => 'Asien',
 			'143' => 'Centralasien',
 			'145' => 'Vestasien',
 			'150' => 'Europa',
 			'151' => 'Østeuropa',
 			'154' => 'Nordeuropa',
 			'155' => 'Vesteuropa',
 			'202' => 'Subsaharisk Afrika',
 			'419' => 'Latinamerika',
 			'AC' => 'Ascensionøen',
 			'AD' => 'Andorra',
 			'AE' => 'De Forenede Arabiske Emirater',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua og Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanien',
 			'AM' => 'Armenien',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerikansk Samoa',
 			'AT' => 'Østrig',
 			'AU' => 'Australien',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Aserbajdsjan',
 			'BA' => 'Bosnien-Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgien',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarien',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'De tidligere Nederlandske Antiller',
 			'BR' => 'Brasilien',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetøen',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Cocosøerne',
 			'CD' => 'Congo-Kinshasa',
 			'CD@alt=variant' => 'Den Demokratiske Republik Congo (DRC)',
 			'CF' => 'Den Centralafrikanske Republik',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'Republikken Congo',
 			'CH' => 'Schweiz',
 			'CI' => 'Elfenbenskysten',
 			'CK' => 'Cookøerne',
 			'CL' => 'Chile',
 			'CM' => 'Cameroun',
 			'CN' => 'Kina',
 			'CO' => 'Colombia',
 			'CP' => 'Clippertonøen',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Juleøen',
 			'CY' => 'Cypern',
 			'CZ' => 'Tjekkiet',
 			'CZ@alt=variant' => 'Den Tjekkiske Republik',
 			'DE' => 'Tyskland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominica',
 			'DO' => 'Den Dominikanske Republik',
 			'DZ' => 'Algeriet',
 			'EA' => 'Ceuta og Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egypten',
 			'EH' => 'Vestsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanien',
 			'ET' => 'Etiopien',
 			'EU' => 'Den Europæiske Union',
 			'EZ' => 'eurozonen',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsøerne',
 			'FK@alt=variant' => 'Falklandsøerne (Islas Malvinas)',
 			'FM' => 'Mikronesien',
 			'FO' => 'Færøerne',
 			'FR' => 'Frankrig',
 			'GA' => 'Gabon',
 			'GB' => 'Storbritannien',
 			'GD' => 'Grenada',
 			'GE' => 'Georgien',
 			'GF' => 'Fransk Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grønland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ækvatorialguinea',
 			'GR' => 'Grækenland',
 			'GS' => 'South Georgia og De Sydlige Sandwichøer',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'SAR Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard Island og McDonald Islands',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatien',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanariske øer',
 			'ID' => 'Indonesien',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'Indien',
 			'IO' => 'Det Britiske Territorium i Det Indiske Ocean',
 			'IO@alt=chagos' => 'Chagosøerne',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italien',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Cambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comorerne',
 			'KN' => 'Saint Kitts og Nevis',
 			'KP' => 'Nordkorea',
 			'KR' => 'Sydkorea',
 			'KW' => 'Kuwait',
 			'KY' => 'Caymanøerne',
 			'KZ' => 'Kasakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luxembourg',
 			'LV' => 'Letland',
 			'LY' => 'Libyen',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalløerne',
 			'MK' => 'Nordmakedonien',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongoliet',
 			'MO' => 'SAR Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nordmarianerne',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanien',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldiverne',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Ny Kaledonien',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederlandene',
 			'NO' => 'Norge',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransk Polynesien',
 			'PG' => 'Papua Ny Guinea',
 			'PH' => 'Filippinerne',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint Pierre og Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'De palæstinensiske områder',
 			'PS@alt=short' => 'Palæstina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Ydre Oceanien',
 			'RE' => 'Réunion',
 			'RO' => 'Rumænien',
 			'RS' => 'Serbien',
 			'RU' => 'Rusland',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi-Arabien',
 			'SB' => 'Salomonøerne',
 			'SC' => 'Seychellerne',
 			'SD' => 'Sudan',
 			'SE' => 'Sverige',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenien',
 			'SJ' => 'Svalbard og Jan Mayen',
 			'SK' => 'Slovakiet',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sydsudan',
 			'ST' => 'São Tomé og Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syrien',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicosøerne',
 			'TD' => 'Tchad',
 			'TF' => 'De Franske Besiddelser i Det Sydlige Indiske Ocean og Antarktis',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadsjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Østtimor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesien',
 			'TO' => 'Tonga',
 			'TR' => 'Tyrkiet',
 			'TT' => 'Trinidad og Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Amerikanske oversøiske øer',
 			'UN' => 'De Forenede Nationer',
 			'UN@alt=short' => 'FN',
 			'US' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanstaten',
 			'VC' => 'Saint Vincent og Grenadinerne',
 			'VE' => 'Venezuela',
 			'VG' => 'De Britiske Jomfruøer',
 			'VI' => 'De Amerikanske Jomfruøer',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis og Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudo-accenter',
 			'XB' => 'pseudo-bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sydafrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Ukendt område',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'traditionel tysk retskrivning',
 			'1994' => 'standardiseret Resi-ortografi',
 			'1996' => 'tysk retskrivning fra 1996',
 			'1606NICT' => 'sen middelfransk frem til 1606',
 			'1694ACAD' => 'tidlig moderne fransk',
 			'1959ACAD' => 'akademisk',
 			'ALALC97' => 'ALA-LC-romanisering fra 1997',
 			'ALUKU' => 'aluku-dialekt',
 			'AREVELA' => 'østarmensk',
 			'AREVMDA' => 'vestarmensk',
 			'BAKU1926' => 'forenet tyrkisk-latinsk alfabet',
 			'BAUDDHA' => 'bauddha',
 			'BISCAYAN' => 'biscayisk',
 			'BISKE' => 'San Giorgio-/Bila-dialekt',
 			'BOHORIC' => 'Bohorič-alfabet',
 			'BOONT' => 'boontling',
 			'DAJNKO' => 'Dajnko-alfabet',
 			'EMODENG' => 'tidlig moderne engelsk',
 			'FONIPA' => 'det internationale fonetiske alfabet',
 			'FONUPA' => 'det uraliske fonetiske alfabet',
 			'FONXSAMP' => 'fonxsamp',
 			'HEPBURN' => 'Hepburn-romanisering',
 			'HOGNORSK' => 'høgnorsk',
 			'ITIHASA' => 'itihasa',
 			'JAUER' => 'jauer',
 			'JYUTPING' => 'jyutping',
 			'KKCOR' => 'almindelig ortografi',
 			'KSCOR' => 'standardortografi',
 			'LAUKIKA' => 'laukika',
 			'LIPAW' => 'lipovaz',
 			'METELKO' => 'Metelko-alfabet',
 			'MONOTON' => 'monotonisk',
 			'NDYUKA' => 'Ndyuka-dialekt',
 			'NEDIS' => 'Natisone-dialekt',
 			'NJIVA' => 'Gniva-/Nijva-dialekt',
 			'NULIK' => 'moderne volapük',
 			'OSOJS' => 'Oseacco-/Osojane-dialekt',
 			'PAMAKA' => 'Pamaka-dialekt',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonisk',
 			'POSIX' => 'computer',
 			'REVISED' => 'revideret retskrivning',
 			'RIGIK' => 'klassisk volapük',
 			'ROZAJ' => 'Resi',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'skotsk standardengelsk',
 			'SCOUSE' => 'scouse',
 			'SURMIRAN' => 'surmiran',
 			'SURSILV' => 'sursilv',
 			'SUTSILV' => 'sutsilv',
 			'TARASK' => 'Taraskievica-ortografi',
 			'UCCOR' => 'forenet ortografi',
 			'UCRCOR' => 'forenet revideret ortografi',
 			'ULSTER' => 'ulster',
 			'VAIDIKA' => 'vaidika',
 			'VALENCIA' => 'valenciansk',
 			'VALLADER' => 'vallader',
 			'WADEGILE' => 'Wade-Giles',

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
 			'colalternate' => 'Ignorer symboler under sortering',
 			'colbackwards' => 'Omvendt sortering efter accenter',
 			'colcasefirst' => 'Sortering efter store/små bogstaver',
 			'colcaselevel' => 'Sortering med forskel på små og store bogstaver',
 			'collation' => 'sorteringsrækkefølge',
 			'colnormalization' => 'Normaliseret sortering',
 			'colnumeric' => 'Numerisk sortering',
 			'colstrength' => 'Sorteringsstyrke',
 			'currency' => 'valuta',
 			'hc' => 'timeur (12 vs. 24)',
 			'lb' => 'linjeskift',
 			'ms' => 'målesystem',
 			'numbers' => 'tal',
 			'timezone' => 'Tidszone',
 			'va' => 'Sprogvariant',
 			'x' => 'Privatbrug',

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
 				'dangi' => q{dangi-kalender},
 				'ethiopic' => q{etiopisk kalender},
 				'ethiopic-amete-alem' => q{etiopisk amete-alem-kalender},
 				'gregorian' => q{gregoriansk kalender},
 				'hebrew' => q{jødisk kalender},
 				'indian' => q{indisk nationalkalender},
 				'islamic' => q{hijri-kalender},
 				'islamic-civil' => q{verdslig hijri-kalender},
 				'islamic-rgsa' => q{islamisk kalender (Saudi-Arabien, observation)},
 				'islamic-tbla' => q{islamisk kalender (tabellarisk, astronomisk epoke)},
 				'islamic-umalqura' => q{hijri-kalender (Umm al-Qura)},
 				'iso8601' => q{ISO-8601-kalender},
 				'japanese' => q{japansk kalender},
 				'persian' => q{persisk kalender},
 				'roc' => q{kalender for Republikken Kina},
 			},
 			'cf' => {
 				'account' => q{format for regnskabsvaluta},
 				'standard' => q{format for standardvaluta},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sortér efter symboler},
 				'shifted' => q{Sortér, og ignorer symboler},
 			},
 			'colbackwards' => {
 				'no' => q{Sortér efter accenter i normal rækkefølge},
 				'yes' => q{Sortér efter accenter i omvendt rækkefølge},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sortér med små bogstaver først},
 				'no' => q{Sortér efter store og små bogstaver i almindelig rækkefølge},
 				'upper' => q{Sortér med store bogstaver først},
 			},
 			'colcaselevel' => {
 				'no' => q{Sortér uden forskel på store og små bogstaver},
 				'yes' => q{Sortér med skelnen mellem store og små bogstaver},
 			},
 			'collation' => {
 				'big5han' => q{sorteringsrækkefølge uforkortet kinesisk - Big5},
 				'compat' => q{tidligere sorteringsrækkefølge, kompatibilitet},
 				'dictionary' => q{sorteringsrækkefølge for ordbog},
 				'ducet' => q{Unicode-standardsorteringsrækkefølge},
 				'eor' => q{europæisk sorteringsrækkefølge},
 				'gb2312han' => q{sorteringsrækkefølge forkortet kinesisk - GB2312},
 				'phonebook' => q{sorteringsrækkefølge i telefonbøger},
 				'phonetic' => q{fonetisk sorteringsrækkefølge},
 				'pinyin' => q{pinyin-baseret sorteringsrækkefølge},
 				'search' => q{generel søgning},
 				'searchjl' => q{sortér efter den første konsonant i hangul},
 				'standard' => q{standardsorteringsrækkefølge},
 				'stroke' => q{stregbaseret sorteringsrækkefølge},
 				'traditional' => q{traditionel sorteringsrækkefølge},
 				'unihan' => q{sortering efter streger i rodtegn},
 				'zhuyin' => q{zhuyin-sorteringsrækkefølge},
 			},
 			'colnormalization' => {
 				'no' => q{Sortér uden normalisering},
 				'yes' => q{Sortér Unicode efter første normalisering},
 			},
 			'colnumeric' => {
 				'no' => q{Sortér efter individuelle cifre},
 				'yes' => q{Sortér tal numerisk},
 			},
 			'colstrength' => {
 				'identical' => q{Sortér alt},
 				'primary' => q{Sortér kun efter basisbogstaver},
 				'quaternary' => q{Sortér efter accenter/små og store bogstaver/bredde/kana},
 				'secondary' => q{Sortér efter accenter},
 				'tertiary' => q{Sortér efter accenter/store og små bogstaver/bredde},
 			},
 			'd0' => {
 				'fwidth' => q{fuld bredde},
 				'hwidth' => q{halv bredde},
 				'npinyin' => q{Numerisk},
 			},
 			'hc' => {
 				'h11' => q{12-timersur (0-11)},
 				'h12' => q{12-timersur (1-12)},
 				'h23' => q{24-timersur (0-23)},
 				'h24' => q{24-timersur (1-24)},
 			},
 			'lb' => {
 				'loose' => q{løst linjeskift},
 				'normal' => q{normalt linjeskift},
 				'strict' => q{hårdt linjeskift},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{metersystem},
 				'uksystem' => q{britisk målesystem},
 				'ussystem' => q{amerikansk målesystem},
 			},
 			'numbers' => {
 				'arab' => q{hindu-arabiske tal},
 				'arabext' => q{udvidede hindu-arabiske tal},
 				'armn' => q{armenske tal},
 				'armnlow' => q{armenske tal med små bogstaver},
 				'bali' => q{Balinesiske tal},
 				'beng' => q{bengali tal},
 				'brah' => q{Brahmi-tal},
 				'cakm' => q{chakma-tal},
 				'cham' => q{Cham-tal},
 				'deva' => q{devanagariske tal},
 				'ethi' => q{etiopiske tal},
 				'finance' => q{Finansielle tal},
 				'fullwide' => q{tal i fuld bredde},
 				'geor' => q{georgiske tal},
 				'grek' => q{græske tal},
 				'greklow' => q{græske tal med små bogstaver},
 				'gujr' => q{gujarati tal},
 				'guru' => q{gurmukhi tal},
 				'hanidec' => q{kinesiske decimaltal},
 				'hans' => q{forenklede kinesiske tal},
 				'hansfin' => q{forenklede kinesiske finansielle tal},
 				'hant' => q{traditionelle kinesiske tal},
 				'hantfin' => q{traditionelle kinesiske finansielle tal},
 				'hebr' => q{hebraiske tal},
 				'java' => q{javanesiske tal},
 				'jpan' => q{japanske tal},
 				'jpanfin' => q{japanske finansielle tal},
 				'kali' => q{Kayah Li-tal},
 				'khmr' => q{khmer tal},
 				'knda' => q{kannada tal},
 				'lana' => q{Tai Tham Hora-tal},
 				'lanatham' => q{Tai Tham Tahm-tal},
 				'laoo' => q{laotiske tal},
 				'latn' => q{arabertal},
 				'lepc' => q{Lepcha-tal},
 				'limb' => q{Limbu-tal},
 				'mlym' => q{malayalamske tal},
 				'mong' => q{Mongolske tal},
 				'mtei' => q{Meetei Mayek-tal},
 				'mymr' => q{Myanmar-tal},
 				'mymrshan' => q{Myanmar Shan-tal},
 				'native' => q{nationale tal},
 				'nkoo' => q{N’Ko-tal},
 				'olck' => q{ol chiki-tal},
 				'orya' => q{oriya-tal},
 				'osma' => q{Osmanya-tal},
 				'roman' => q{romertal},
 				'romanlow' => q{romertal med små bogstaver},
 				'saur' => q{Saurashtra-tal},
 				'shrd' => q{Sharada-tal},
 				'sora' => q{Sora Sompeng-tal},
 				'sund' => q{Sundanesiske tal},
 				'takr' => q{Takri-tal},
 				'talu' => q{Nye Tai Lue-tal},
 				'taml' => q{traditionelle tamilske tal},
 				'tamldec' => q{tamilske tal},
 				'telu' => q{telugu-tal},
 				'thai' => q{thailandske tal},
 				'tibt' => q{tibetanske tal},
 				'traditional' => q{Traditionelle tal},
 				'vaii' => q{vai-tal},
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
			'metric' => q{det metriske system},
 			'UK' => q{de britiske målesystemer},
 			'US' => q{de amerikanske målesystemer},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Sprog: {0}',
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
			auxiliary => qr{[áàâ ç éèêë íîï ñ óô œ úùû ÿü ä ǿö]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z æ ø å]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'], };
},
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
						'name' => q(kompasretning),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kompasretning),
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
						'1' => q(common),
						'one' => q({0} G-kraft),
						'other' => q({0} G-kraft),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(common),
						'one' => q({0} G-kraft),
						'other' => q({0} G-kraft),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(common),
						'name' => q(meter pr. sekund²),
						'one' => q({0} meter pr. sekund²),
						'other' => q({0} meter pr. sekund²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(common),
						'name' => q(meter pr. sekund²),
						'one' => q({0} meter pr. sekund²),
						'other' => q({0} meter pr. sekund²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(neuter),
						'name' => q(bueminutter),
						'one' => q({0} bueminut),
						'other' => q({0} bueminutter),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(neuter),
						'name' => q(bueminutter),
						'one' => q({0} bueminut),
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
						'1' => q(common),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(common),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(common),
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(common),
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(common),
						'name' => q(omdrejninger),
						'one' => q({0} omdrejning),
						'other' => q({0} omdrejninger),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(common),
						'name' => q(omdrejninger),
						'one' => q({0} omdrejning),
						'other' => q({0} omdrejninger),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(common),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(common),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(common),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(common),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(common),
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(common),
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrattommer),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommer),
						'per' => q({0} pr. kvadrattomme),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrattommer),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommer),
						'per' => q({0} pr. kvadrattomme),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(common),
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} pr. kvadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(common),
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} pr. kvadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(common),
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(common),
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(common),
						'name' => q(kvadrat-engelske mil),
						'one' => q({0} kvadrat-engelsk mil),
						'other' => q({0} kvadrat-engelske mil),
						'per' => q({0} pr. kvadrat-engelske mil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(common),
						'name' => q(kvadrat-engelske mil),
						'one' => q({0} kvadrat-engelsk mil),
						'other' => q({0} kvadrat-engelske mil),
						'per' => q({0} pr. kvadrat-engelske mil),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(kvadrat-engelske yard),
						'one' => q({0} kvadrat-engelsk yard),
						'other' => q({0} kvadrat-engelske yard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(kvadrat-engelske yard),
						'one' => q({0} kvadrat-engelsk yard),
						'other' => q({0} kvadrat-engelske yard),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(common),
						'name' => q(enheder),
						'one' => q({0} enhed),
						'other' => q({0} enheder),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(common),
						'name' => q(enheder),
						'one' => q({0} enhed),
						'other' => q({0} enheder),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(common),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(common),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(neuter),
						'name' => q(milligram pr. deciliter),
						'one' => q({0} milligram pr. deciliter),
						'other' => q({0} milligram pr. deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(neuter),
						'name' => q(milligram pr. deciliter),
						'one' => q({0} milligram pr. deciliter),
						'other' => q({0} milligram pr. deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(neuter),
						'name' => q(millimol pr. liter),
						'one' => q({0} millimol pr. liter),
						'other' => q({0} millimol pr. liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(neuter),
						'name' => q(millimol pr. liter),
						'one' => q({0} millimol pr. liter),
						'other' => q({0} millimol pr. liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(common),
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(common),
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(common),
						'name' => q(procent),
						'one' => q({0} procent),
						'other' => q({0} procent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(common),
						'name' => q(procent),
						'one' => q({0} procent),
						'other' => q({0} procent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(common),
						'name' => q(promille),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(common),
						'name' => q(promille),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(common),
						'name' => q(parts per million),
						'one' => q({0} part per million),
						'other' => q({0} parts per million),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(common),
						'name' => q(parts per million),
						'one' => q({0} part per million),
						'other' => q({0} parts per million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(common),
						'name' => q(milliardtedele),
						'one' => q({0} milliardtedel),
						'other' => q({0} milliardtedele),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(common),
						'name' => q(milliardtedele),
						'one' => q({0} milliardtedel),
						'other' => q({0} milliardtedele),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(liter pr. 100 kilometer),
						'one' => q({0} liter pr. 100 kilometer),
						'other' => q({0} liter pr. 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(liter pr. 100 kilometer),
						'one' => q({0} liter pr. 100 kilometer),
						'other' => q({0} liter pr. 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(common),
						'name' => q(liter pr. kilometer),
						'one' => q({0} liter pr. kilometer),
						'other' => q({0} liter pr. kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(common),
						'name' => q(liter pr. kilometer),
						'one' => q({0} liter pr. kilometer),
						'other' => q({0} liter pr. kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(common),
						'name' => q(mil pr. gallon),
						'one' => q(mil pr. gallon),
						'other' => q({0} mil pr. gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(common),
						'name' => q(mil pr. gallon),
						'one' => q(mil pr. gallon),
						'other' => q({0} mil pr. gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(common),
						'name' => q(mil pr. engelsk gallon),
						'one' => q({0} mil pr. engelsk gallon),
						'other' => q({0} mil pr. engelsk gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(common),
						'name' => q(mil pr. engelsk gallon),
						'one' => q({0} mil pr. engelsk gallon),
						'other' => q({0} mil pr. engelsk gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} øst),
						'north' => q({0} nord),
						'south' => q({0} syd),
						'west' => q({0} vest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} øst),
						'north' => q({0} nord),
						'south' => q({0} syd),
						'west' => q({0} vest),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(common),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(common),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(common),
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(common),
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(common),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(common),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(common),
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(common),
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(common),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(common),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(common),
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(common),
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(common),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(common),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(common),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(common),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(common),
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(common),
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(common),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(common),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(common),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(common),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'name' => q(århundreder),
						'one' => q({0} århundrede),
						'other' => q({0} århundreder),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'name' => q(århundreder),
						'one' => q({0} århundrede),
						'other' => q({0} århundreder),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(common),
						'one' => q({0} dag),
						'other' => q({0} dage),
						'per' => q({0} pr. dag),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(common),
						'one' => q({0} dag),
						'other' => q({0} dage),
						'per' => q({0} pr. dag),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'name' => q(årtier),
						'one' => q({0} årti),
						'other' => q({0} årtier),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'name' => q(årtier),
						'one' => q({0} årti),
						'other' => q({0} årtier),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(common),
						'one' => q({0} time),
						'other' => q({0} timer),
						'per' => q({0} pr. time),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(common),
						'one' => q({0} time),
						'other' => q({0} timer),
						'per' => q({0} pr. time),
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
						'one' => q({0} minut),
						'other' => q({0} minutter),
						'per' => q({0} pr. min.),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(neuter),
						'one' => q({0} minut),
						'other' => q({0} minutter),
						'per' => q({0} pr. min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(common),
						'one' => q({0} måned),
						'other' => q({0} måneder),
						'per' => q({0} pr. måned),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(common),
						'one' => q({0} måned),
						'other' => q({0} måneder),
						'per' => q({0} pr. måned),
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
						'1' => q(common),
						'name' => q(nætter),
						'one' => q({0} nat),
						'other' => q({0} nætter),
						'per' => q({0} pr. nat),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(common),
						'name' => q(nætter),
						'one' => q({0} nat),
						'other' => q({0} nætter),
						'per' => q({0} pr. nat),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'one' => q({0} kvartal),
						'other' => q({0} kvartaler),
						'per' => q({0} pr. kvartal),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'one' => q({0} kvartal),
						'other' => q({0} kvartaler),
						'per' => q({0} pr. kvartal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(neuter),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} pr. sekund),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(neuter),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} pr. sekund),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(common),
						'one' => q({0} uge),
						'other' => q({0} uger),
						'per' => q({0} pr. uge),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(common),
						'one' => q({0} uge),
						'other' => q({0} uger),
						'per' => q({0} pr. uge),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(neuter),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0} om året),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(neuter),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0} om året),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(common),
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(common),
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(common),
						'name' => q(milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(common),
						'name' => q(milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(common),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(common),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(common),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(common),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(common),
						'name' => q(kalorier),
						'one' => q({0} kalorie),
						'other' => q({0} kalorier),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(common),
						'name' => q(kalorier),
						'one' => q({0} kalorie),
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
						'1' => q(common),
						'name' => q(kalorier),
						'one' => q({0} kalorie),
						'other' => q({0} kalorier),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(common),
						'name' => q(kalorier),
						'one' => q({0} kalorie),
						'other' => q({0} kalorier),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(common),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(common),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(common),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorier),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(common),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorier),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(common),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(common),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(common),
						'name' => q(kilowatt-timer),
						'one' => q({0} kilowatt-time),
						'other' => q({0} kilowatt-timer),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(common),
						'name' => q(kilowatt-timer),
						'one' => q({0} kilowatt-time),
						'other' => q({0} kilowatt-timer),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(kilowatt-time per 100 kilometer),
						'one' => q({0} kilowatt-time per 100 kilometer),
						'other' => q({0} kilowatt-timer per 100 kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(kilowatt-time per 100 kilometer),
						'one' => q({0} kilowatt-time per 100 kilometer),
						'other' => q({0} kilowatt-timer per 100 kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(common),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(common),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(common),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(common),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(common),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(common),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(common),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(common),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(common),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(common),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} prik),
						'other' => q({0} prikker),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} prik),
						'other' => q({0} prikker),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(prikker per centimeter),
						'one' => q({0} prik per centimeter),
						'other' => q({0} prikker per centimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(prikker per centimeter),
						'one' => q({0} prik per centimeter),
						'other' => q({0} prikker per centimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(prikker per tomme),
						'one' => q({0} prik per tomme),
						'other' => q({0} prikker per tomme),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(prikker per tomme),
						'one' => q({0} prik per tomme),
						'other' => q({0} prikker per tomme),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(common),
						'name' => q(geviert),
						'one' => q({0} geviert),
						'other' => q({0} geviert),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(common),
						'name' => q(geviert),
						'one' => q({0} geviert),
						'other' => q({0} geviert),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(common),
						'name' => q(megapixels),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(common),
						'name' => q(megapixels),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(common),
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(common),
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(common),
						'name' => q(pixels per centimeter),
						'one' => q({0} pixel per centimeter),
						'other' => q({0} pixels per centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(common),
						'name' => q(pixels per centimeter),
						'one' => q({0} pixel per centimeter),
						'other' => q({0} pixels per centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels per tomme),
						'one' => q({0} pixel per tomme),
						'other' => q({0} pixels per tomme),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels per tomme),
						'one' => q({0} pixel per tomme),
						'other' => q({0} pixels per tomme),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiske enheder),
						'one' => q({0} astronomisk enhed),
						'other' => q({0} astronomiske enheder),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiske enheder),
						'one' => q({0} astronomisk enhed),
						'other' => q({0} astronomiske enheder),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(common),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} pr. centimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(common),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} pr. centimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(common),
						'name' => q(decimeter),
						'one' => q({0} decimeter),
						'other' => q({0} decimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(common),
						'name' => q(decimeter),
						'one' => q({0} decimeter),
						'other' => q({0} decimeter),
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
					'length-foot' => {
						'1' => q(common),
						'per' => q({0} pr. fod),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(common),
						'per' => q({0} pr. fod),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(common),
						'per' => q({0} pr. tomme),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(common),
						'per' => q({0} pr. tomme),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(common),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} pr. kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(common),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} pr. kilometer),
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
						'1' => q(common),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} pr. meter),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(common),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} pr. meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(common),
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(common),
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(common),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(common),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(common),
						'name' => q(svenske mil),
						'one' => q({0} svensk mil),
						'other' => q({0} svenske mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(common),
						'name' => q(svenske mil),
						'one' => q({0} svensk mil),
						'other' => q({0} svenske mil),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(common),
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(common),
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(common),
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(common),
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0} sømil),
						'other' => q({0} sømil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0} sømil),
						'other' => q({0} sømil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(common),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(common),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(common),
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(common),
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(neuter),
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(neuter),
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(common),
						'one' => q({0} solradius),
						'other' => q({0} solradier),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(common),
						'one' => q({0} solradius),
						'other' => q({0} solradier),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(common),
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(common),
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(common),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(common),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(common),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(common),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(common),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(common),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(common),
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(common),
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(common),
						'name' => q(Jordmasser),
						'one' => q({0} jordmasse),
						'other' => q({0} jordmasser),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(common),
						'name' => q(Jordmasser),
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
						'per' => q({0} pr. gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} pr. gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(neuter),
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} pr. kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(neuter),
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} pr. kg),
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
						'1' => q(common),
						'name' => q(ounces),
						'one' => q({0} ounce),
						'other' => q({0} ounces),
						'per' => q({0} pr. ounce),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(common),
						'name' => q(ounces),
						'one' => q({0} ounce),
						'other' => q({0} ounces),
						'per' => q({0} pr. ounce),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ounces),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounces),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ounces),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounces),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(neuter),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} pr. pund),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(neuter),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} pr. pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(common),
						'one' => q({0} solmasse),
						'other' => q({0} solmasser),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(common),
						'one' => q({0} solmasse),
						'other' => q({0} solmasser),
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
						'name' => q(short ton),
						'one' => q({0} short ton),
						'other' => q({0} short ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(short ton),
						'one' => q({0} short ton),
						'other' => q({0} short ton),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(neuter),
						'name' => q(tons),
						'one' => q({0} ton),
						'other' => q({0} tons),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(neuter),
						'name' => q(tons),
						'one' => q({0} ton),
						'other' => q({0} tons),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pr. {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pr. {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(common),
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(common),
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hestekræfter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekræfter),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hestekræfter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekræfter),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(common),
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(common),
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(common),
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(common),
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(common),
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(common),
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(common),
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(common),
						'name' => q(watt),
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
						'1' => q(kubik{0}),
						'one' => q(kubik{0}),
						'other' => q(kubik{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kubik{0}),
						'one' => q(kubik{0}),
						'other' => q(kubik{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(common),
						'name' => q(atmosfære),
						'one' => q({0} atmosfære),
						'other' => q({0} atmosfære),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(common),
						'name' => q(atmosfære),
						'one' => q({0} atmosfære),
						'other' => q({0} atmosfære),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(common),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(common),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(common),
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(common),
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tommer kviksølv),
						'one' => q({0} tomme kviksølv),
						'other' => q({0} tommer kviksølv),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tommer kviksølv),
						'one' => q({0} tomme kviksølv),
						'other' => q({0} tommer kviksølv),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(common),
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(common),
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(common),
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(common),
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(common),
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(common),
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'1' => q(common),
						'name' => q(millimeter kviksølv),
						'one' => q({0} millimeter kviksølv),
						'other' => q({0} millimeter kviksølv),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(common),
						'name' => q(millimeter kviksølv),
						'one' => q({0} millimeter kviksølv),
						'other' => q({0} millimeter kviksølv),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(common),
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(common),
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pounds pr. kvadrattomme),
						'one' => q({0} pound pr. kvadrattomme),
						'other' => q({0} pounds pr. kvadrattomme),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pounds pr. kvadrattomme),
						'one' => q({0} pound pr. kvadrattomme),
						'other' => q({0} pounds pr. kvadrattomme),
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
						'1' => q(common),
						'name' => q(kilometer i timen),
						'one' => q({0} kilometer i timen),
						'other' => q({0} kilometer i timen),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(common),
						'name' => q(kilometer i timen),
						'one' => q({0} kilometer i timen),
						'other' => q({0} kilometer i timen),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(common),
						'name' => q(meter pr. sekund),
						'one' => q({0} meter i sekundet),
						'other' => q({0} meter i sekundet),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(common),
						'name' => q(meter pr. sekund),
						'one' => q({0} meter i sekundet),
						'other' => q({0} meter i sekundet),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(common),
						'name' => q(engelske mil i timen),
						'one' => q({0} engelsk mil i timen),
						'other' => q({0} engelske mil i timen),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(common),
						'name' => q(engelske mil i timen),
						'one' => q({0} engelsk mil i timen),
						'other' => q({0} engelske mil i timen),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(common),
						'name' => q(grader celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grader celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(common),
						'name' => q(grader celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grader celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(common),
						'name' => q(grader fahrenheit),
						'one' => q({0} grad fahrenheit),
						'other' => q({0} grader fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(common),
						'name' => q(grader fahrenheit),
						'one' => q({0} grad fahrenheit),
						'other' => q({0} grader fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(common),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(common),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(common),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(common),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(common),
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(common),
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-fod),
						'one' => q({0} acre-fod),
						'other' => q({0} acre-fod),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-fod),
						'one' => q({0} acre-fod),
						'other' => q({0} acre-fod),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(tønder),
						'one' => q({0} tønde),
						'other' => q({0} tønder),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tønder),
						'one' => q({0} tønde),
						'other' => q({0} tønder),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skæpper),
						'one' => q({0} skæppe),
						'other' => q({0} skæpper),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skæpper),
						'one' => q({0} skæppe),
						'other' => q({0} skæpper),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(common),
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(common),
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(common),
						'name' => q(kubikcentimeter),
						'one' => q({0} kubikcentimeter),
						'other' => q({0} kubikcentimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(common),
						'name' => q(kubikcentimeter),
						'one' => q({0} kubikcentimeter),
						'other' => q({0} kubikcentimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(common),
						'name' => q(kubikfod),
						'one' => q({0} kubikfod),
						'other' => q({0} kubikfod),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(common),
						'name' => q(kubikfod),
						'one' => q({0} kubikfod),
						'other' => q({0} kubikfod),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubiktommer),
						'one' => q({0} kubiktomme),
						'other' => q({0} kubiktommer),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubiktommer),
						'one' => q({0} kubiktomme),
						'other' => q({0} kubiktommer),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(common),
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(common),
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(common),
						'name' => q(kubikmeter),
						'one' => q({0} kubikmeter),
						'other' => q({0} kubikmeter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(common),
						'name' => q(kubikmeter),
						'one' => q({0} kubikmeter),
						'other' => q({0} kubikmeter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(common),
						'name' => q(kubik-engelske mil),
						'one' => q({0} kubik-engelsk mil),
						'other' => q({0} kubik-engelske mil),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(common),
						'name' => q(kubik-engelske mil),
						'one' => q({0} kubik-engelsk mil),
						'other' => q({0} kubik-engelske mil),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubik-engelske yard),
						'one' => q({0} kubik-engelske yard),
						'other' => q({0} kubik-engelske yard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubik-engelske yard),
						'one' => q({0} kubik-engelske yard),
						'other' => q({0} kubik-engelske yard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(common),
						'one' => q({0} cup),
						'other' => q({0} cups),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(common),
						'one' => q({0} cup),
						'other' => q({0} cups),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(common),
						'name' => q(metriske kopper),
						'one' => q({0} metrisk kop),
						'other' => q({0} metriske kopper),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(common),
						'name' => q(metriske kopper),
						'one' => q({0} metrisk kop),
						'other' => q({0} metriske kopper),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(common),
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(common),
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(common),
						'name' => q(dessertske),
						'one' => q({0} dessertske),
						'other' => q({0} dessertskeer),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(common),
						'name' => q(dessertske),
						'one' => q({0} dessertske),
						'other' => q({0} dessertskeer),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(common),
						'name' => q(britisk dessertske),
						'one' => q({0} britisk dessertske),
						'other' => q({0} britiske dessertskeer),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(common),
						'name' => q(britisk dessertske),
						'one' => q({0} britisk dessertske),
						'other' => q({0} britiske dessertskeer),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(common),
						'name' => q(britisk flydende dram),
						'one' => q({0} britisk flydende dram),
						'other' => q({0} britiske flydende dramme),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(common),
						'name' => q(britisk flydende dram),
						'one' => q({0} britisk flydende dram),
						'other' => q({0} britiske flydende dramme),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(common),
						'name' => q(engelske fluid ounces),
						'one' => q({0} engelsk fluid ounce),
						'other' => q({0} engelske fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(common),
						'name' => q(engelske fluid ounces),
						'one' => q({0} engelsk fluid ounce),
						'other' => q({0} engelske fluid ounces),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(common),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(common),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounces),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(common),
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(common),
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(common),
						'name' => q(engelske gallons),
						'one' => q({0} engelsk gallon),
						'other' => q({0} engelske gallons),
						'per' => q({0}/engelsk gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(common),
						'name' => q(engelske gallons),
						'one' => q({0} engelsk gallon),
						'other' => q({0} engelske gallons),
						'per' => q({0}/engelsk gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(common),
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(common),
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(common),
						'one' => q({0} liter),
						'other' => q({0} liter),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(common),
						'one' => q({0} liter),
						'other' => q({0} liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(common),
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(common),
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(common),
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(common),
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(common),
						'name' => q(knivspids),
						'one' => q({0} knivspids),
						'other' => q({0} knivspidser),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(common),
						'name' => q(knivspids),
						'one' => q({0} knivspids),
						'other' => q({0} knivspidser),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(common),
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(common),
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(common),
						'name' => q(metriske pints),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriske pints),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(common),
						'name' => q(metriske pints),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriske pints),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(common),
						'name' => q(engelske quarts),
						'one' => q({0} engelsk quart),
						'other' => q({0} engelske quarts),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(common),
						'name' => q(engelske quarts),
						'one' => q({0} engelsk quart),
						'other' => q({0} engelske quarts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(common),
						'name' => q(britisk quart),
						'one' => q({0} britisk quart),
						'other' => q({0} britiske quarts),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(common),
						'name' => q(britisk quart),
						'one' => q({0} britisk quart),
						'other' => q({0} britiske quarts),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(common),
						'name' => q(spiseskeer),
						'one' => q({0} spiseske),
						'other' => q({0} spiseskeer),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(common),
						'name' => q(spiseskeer),
						'one' => q({0} spiseske),
						'other' => q({0} spiseskeer),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(common),
						'name' => q(teskeer),
						'one' => q({0} teske),
						'other' => q({0} teskeer),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(common),
						'name' => q(teskeer),
						'one' => q({0} teske),
						'other' => q({0} teskeer),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gr.),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gr.),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
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
					'area-square-foot' => {
						'name' => q(fod²),
						'one' => q({0} fod²),
						'other' => q({0} fod²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fod²),
						'one' => q({0} fod²),
						'other' => q({0} fod²),
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
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0}mpgUK),
						'other' => q({0}mpgUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mpgUK),
						'other' => q({0}mpgUK),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dag),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dag),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(time),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(time),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
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
						'name' => q(ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
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
						'name' => q(nætter),
						'one' => q({0}nat),
						'other' => q({0}nætter),
						'per' => q({0}/nat),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nætter),
						'one' => q({0}nat),
						'other' => q({0}nætter),
						'per' => q({0}/nat),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kvartal),
						'per' => q({0}/kvt.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kvartal),
						'per' => q({0}/kvt.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(uge),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(uge),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
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
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0}kWh/100km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0}kWh/100km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(prik),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(prik),
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
					'length-fathom' => {
						'name' => q(favn),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(favn),
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
					'length-light-year' => {
						'name' => q(ly),
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'one' => q({0} lysår),
						'other' => q({0} lysår),
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
						'name' => q(mile),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mile),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sv. mil),
						'one' => q({0}sv. mil),
						'other' => q({0}sv. mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sv. mil),
						'one' => q({0}sv. mil),
						'other' => q({0}sv. mil),
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
						'name' => q(sm),
						'one' => q({0} sømil),
						'other' => q({0} sømil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sm),
						'one' => q({0} sømil),
						'other' => q({0} sømil),
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
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
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
					'mass-pound' => {
						'one' => q({0} pund),
						'other' => q({0} pund),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} pund),
						'other' => q({0} pund),
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
						'name' => q(watt),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
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
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} km/t),
						'other' => q({0} km/t),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} km/t),
						'other' => q({0} km/t),
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
					'volume-barrel' => {
						'name' => q(td.),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(td.),
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
						'one' => q({0} fod³),
						'other' => q({0} fod³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0} fod³),
						'other' => q({0} fod³),
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
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}brit.dsk.),
						'other' => q({0}brit.dsk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}brit.dsk.),
						'other' => q({0}brit.dsk.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0}br.fl.dr.),
						'other' => q({0}br.fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0}br.fl.dr.),
						'other' => q({0}br.fl.dr.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0} br. qt.),
						'other' => q({0} br. qt.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} br. qt.),
						'other' => q({0} br. qt.),
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
						'name' => q(G-kraft),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G-kraft),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(buemin.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(buemin.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(buesek.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(buesek.),
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
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianer),
						'one' => q({0} radian),
						'other' => q({0} radian),
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
						'name' => q(kvadratfod),
						'one' => q({0} kvadratfod),
						'other' => q({0} kvadratfod),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadratfod),
						'one' => q({0} kvadratfod),
						'other' => q({0} kvadratfod),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(enhed),
						'one' => q({0} enhed),
						'other' => q({0} enheder),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(enhed),
						'one' => q({0} enhed),
						'other' => q({0} enheder),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
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
						'name' => q(pct.),
						'one' => q({0} pct.),
						'other' => q({0} pct.),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(pct.),
						'one' => q({0} pct.),
						'other' => q({0} pct.),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(dele/milliard),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(dele/milliard),
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
						'name' => q(mil/eng. gal),
						'one' => q({0} eng. mpg),
						'other' => q({0} eng. mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/eng. gal),
						'one' => q({0} eng. mpg),
						'other' => q({0} eng. mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Ø),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Ø),
						'west' => q({0}V),
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
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
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
						'name' => q(dage),
						'one' => q({0} dag),
						'other' => q({0} dage),
						'per' => q({0}/dag),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dage),
						'one' => q({0} dag),
						'other' => q({0} dage),
						'per' => q({0}/dag),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(årti),
						'one' => q({0} årti),
						'other' => q({0} årtier),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(årti),
						'one' => q({0} årti),
						'other' => q({0} årtier),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(timer),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(timer),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisek.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisek.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutter),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutter),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(måneder),
						'one' => q({0} md.),
						'other' => q({0} mdr.),
						'per' => q({0}/md.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(måneder),
						'one' => q({0} md.),
						'other' => q({0} mdr.),
						'per' => q({0}/md.),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(nætter),
						'one' => q({0} nat),
						'other' => q({0} nætter),
						'per' => q({0}/nat),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nætter),
						'one' => q({0} nat),
						'other' => q({0} nætter),
						'per' => q({0}/nat),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kvartaler),
						'one' => q({0} kvt.),
						'other' => q({0} kvt.),
						'per' => q({0} pr. kvt.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kvartaler),
						'one' => q({0} kvt.),
						'other' => q({0} kvt.),
						'per' => q({0} pr. kvt.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekunder),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekunder),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(uger),
						'one' => q({0} uge),
						'other' => q({0} uger),
						'per' => q({0}/uge),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(uger),
						'one' => q({0} uge),
						'other' => q({0} uger),
						'per' => q({0}/uge),
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
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
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
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh pr. 100 km),
						'other' => q({0} kWh pr. 100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh pr. 100 km),
						'other' => q({0} kWh pr. 100 km),
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
					'graphics-dot' => {
						'name' => q(prikker),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(prikker),
						'one' => q({0} p),
						'other' => q({0} p),
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
						'name' => q(favne),
						'one' => q({0} favn),
						'other' => q({0} favne),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(favne),
						'one' => q({0} favn),
						'other' => q({0} favne),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fod),
						'one' => q({0} fod),
						'other' => q({0} fod),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fod),
						'one' => q({0} fod),
						'other' => q({0} fod),
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
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(miles),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sømil),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sømil),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pkt.),
						'one' => q({0} pkt.),
						'other' => q({0} pkt.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pkt.),
						'one' => q({0} pkt.),
						'other' => q({0} pkt.),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(solradier),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(solradier),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(engelske yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(engelske yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kt.),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kt.),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} gran),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} gran),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pund),
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
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(# Hg),
						'one' => q({0} # Hg),
						'other' => q({0} # Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(# Hg),
						'one' => q({0} # Hg),
						'other' => q({0} # Hg),
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
						'name' => q(bft),
						'one' => q(bft {0}),
						'other' => q(bft {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(bft),
						'one' => q(bft {0}),
						'other' => q(bft {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0} km/t.),
						'other' => q({0} km/t.),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0} km/t.),
						'other' => q({0} km/t.),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knob),
						'one' => q({0} knob),
						'other' => q({0} knob),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knob),
						'one' => q({0} knob),
						'other' => q({0} knob),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(engelske mil/timen),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(engelske mil/timen),
						'one' => q({0} mph),
						'other' => q({0} mph),
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
					'volume-barrel' => {
						'name' => q(tønde),
						'one' => q({0} td.),
						'other' => q({0} tdr.),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tønde),
						'one' => q({0} td.),
						'other' => q({0} tdr.),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skp.),
						'one' => q({0} skp.),
						'other' => q({0} skp.),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skp.),
						'one' => q({0} skp.),
						'other' => q({0} skp.),
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
						'name' => q(cups),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cups),
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
						'name' => q(dsk.),
						'one' => q({0} dsk.),
						'other' => q({0} dsk.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsk.),
						'one' => q({0} dsk.),
						'other' => q({0} dsk.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(brit. dsk.),
						'one' => q({0} brit. dsk.),
						'other' => q({0} brit. dsk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(brit. dsk.),
						'one' => q({0} brit. dsk.),
						'other' => q({0} brit. dsk.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(br. fl. dr.),
						'one' => q({0} br. fl. dr.),
						'other' => q({0} br. fl. dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(br. fl. dr.),
						'one' => q({0} br. fl. dr.),
						'other' => q({0} br. fl. dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dråbe),
						'one' => q({0} dråbe),
						'other' => q({0} dråber),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dråbe),
						'one' => q({0} dråbe),
						'other' => q({0} dråber),
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
						'name' => q(eng. gal),
						'one' => q({0} eng. gal),
						'other' => q({0} eng. gal),
						'per' => q({0} eng. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(eng. gal),
						'one' => q({0} eng. gal),
						'other' => q({0} eng. gal),
						'per' => q({0} eng. gal),
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
						'name' => q(knsp.),
						'one' => q({0} knsp.),
						'other' => q({0} knsp.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(knsp.),
						'one' => q({0} knsp.),
						'other' => q({0} knsp.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q(mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q(mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(britisk qt),
						'one' => q({0} britisk qt),
						'other' => q({0} britiske qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(britisk qt),
						'one' => q({0} britisk qt),
						'other' => q({0} britiske qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(spsk.),
						'one' => q({0} spsk.),
						'other' => q({0} spsk.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(spsk.),
						'one' => q({0} spsk.),
						'other' => q({0} spsk.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsk.),
						'one' => q({0} tsk.),
						'other' => q({0} tsk.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsk.),
						'one' => q({0} tsk.),
						'other' => q({0} tsk.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nej|n)$' }
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
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
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
					'one' => '0 tusind',
					'other' => '0 tusind',
				},
				'10000' => {
					'one' => '00 tusind',
					'other' => '00 tusind',
				},
				'100000' => {
					'one' => '000 tusind',
					'other' => '000 tusind',
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
					'one' => '0 t',
					'other' => '0 t',
				},
				'10000' => {
					'one' => '00 t',
					'other' => '00 t',
				},
				'100000' => {
					'one' => '000 t',
					'other' => '000 t',
				},
				'1000000' => {
					'one' => '0 mio'.'',
					'other' => '0 mio'.'',
				},
				'10000000' => {
					'one' => '00 mio'.'',
					'other' => '00 mio'.'',
				},
				'100000000' => {
					'one' => '000 mio'.'',
					'other' => '000 mio'.'',
				},
				'1000000000' => {
					'one' => '0 mia'.'',
					'other' => '0 mia'.'',
				},
				'10000000000' => {
					'one' => '00 mia'.'',
					'other' => '00 mia'.'',
				},
				'100000000000' => {
					'one' => '000 mia'.'',
					'other' => '000 mia'.'',
				},
				'1000000000000' => {
					'one' => '0 bio'.'',
					'other' => '0 bio'.'',
				},
				'10000000000000' => {
					'one' => '00 bio'.'',
					'other' => '00 bio'.'',
				},
				'100000000000000' => {
					'one' => '000 bio'.'',
					'other' => '000 bio'.'',
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
				'currency' => q(Andorransk peseta),
				'one' => q(Andorransk peseta),
				'other' => q(Andorranske pesetas),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham fra de Forenede Arabiske Emirater),
				'one' => q(FAE-dirham),
				'other' => q(FAE-dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghansk afghani \(1927–2002\)),
				'one' => q(Afghansk afghani \(1927–2002\)),
				'other' => q(Afghanske afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghansk afghani),
				'one' => q(afghansk afghani),
				'other' => q(afghanske afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albansk lek \(1946–1965\)),
				'one' => q(albansk lek \(1946–1965\)),
				'other' => q(albanske lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albansk lek),
				'one' => q(albansk lek),
				'other' => q(albanske lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armensk dram),
				'one' => q(armensk dram),
				'other' => q(armenske dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Nederlandske Antiller-gylden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolansk kwanza),
				'one' => q(angolansk kwanza),
				'other' => q(angolanske kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolansk kwanza \(1977–1990\)),
				'one' => q(Angolansk kwanza \(1977–1990\)),
				'other' => q(Angolanske kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolansk nye kwanza \(1990–2000\)),
				'one' => q(Angolansk nye kwanza \(1990–2000\)),
				'other' => q(Angolanske nye kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolansk kwanza \(1995–1999\)),
				'one' => q(Angolansk kwanza \(1995–1999\)),
				'other' => q(Angolanske kwanza \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentinsk austral),
				'one' => q(Argentinsk austral),
				'other' => q(Argentinske austral),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentinsk peso ley \(1970–1983\)),
				'one' => q(argentinsk peso ley \(1970–1983\)),
				'other' => q(argentinske peso ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentinsk peso \(1881–1970\)),
				'one' => q(argentinsk peso \(1881–1970\)),
				'other' => q(argentinske pesos \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentinsk peso \(1983–1985\)),
				'one' => q(Argentinsk pesos \(1983–1985\)),
				'other' => q(Argentinske pesos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinsk peso),
				'one' => q(argentinsk peso),
				'other' => q(argentinske pesos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Østrigsk schilling),
				'one' => q(Østrigsk schilling),
				'other' => q(Østrigske schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(australsk dollar),
				'one' => q(australsk dollar),
				'other' => q(australske dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubansk florin),
				'one' => q(arubansk florin),
				'other' => q(arubanske floriner),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Aserbajdsjansk manat \(1993–2006\)),
				'one' => q(Aserbajdsjansk manat \(1993–2006\)),
				'other' => q(Aserbajdsjanske manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(aserbajdsjansk manat),
				'one' => q(aserbajdsjansk manat),
				'other' => q(aserbajdsjanske manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnien-Hercegovinsk dinar),
				'one' => q(Bosnien-Hercegovinsk dinar),
				'other' => q(Bosnien-Hercegovinske dinarer),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosnien-hercegovinsk konvertibel mark),
				'one' => q(bosnien-hercegovinsk konvertibel mark),
				'other' => q(bosnien-hercegovinske konvertible mark),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(ny bosnien-hercegovinsk dinar \(1994–1997\)),
				'one' => q(ny bosnien-hercegovinsk dinar \(1994–1997\)),
				'other' => q(nye bosnien-hercegovinske dinarer \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadisk dollar),
				'one' => q(barbadisk dollar),
				'other' => q(barbadiske dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshisk taka),
				'one' => q(bangladeshisk taka),
				'other' => q(bangladeshiske taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgisk franc \(konvertibel\)),
				'one' => q(Belgisk franc \(konvertibel\)),
				'other' => q(Belgiske franc \(konvertible\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgisk franc),
				'one' => q(Belgisk franc),
				'other' => q(Belgiske franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgisk franc \(financial\)),
				'one' => q(Belgisk franc \(financial\)),
				'other' => q(Belgiske franc \(financial\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgarsk hard lev),
				'one' => q(Bulgarsk hard lev),
				'other' => q(Bulgarske hard lev),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bulgarsk socialistisk lev),
				'one' => q(bulgarsk socialistisk lev),
				'other' => q(bulgarske socialistiske leva),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgarsk lev),
				'one' => q(bulgarsk lev),
				'other' => q(bulgarske leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulgarsk lev \(1879–1952\)),
				'one' => q(bulgarsk lev \(1879–1952\)),
				'other' => q(bulgarske leva \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainsk dinar),
				'one' => q(bahrainsk dinar),
				'other' => q(bahrainske dinarer),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundisk franc),
				'one' => q(burundisk franc),
				'other' => q(burundiske franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudansk dollar),
				'one' => q(bermudansk dollar),
				'other' => q(bermudanske dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneisk dollar),
				'one' => q(bruneisk dollar),
				'other' => q(bruneiske dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviansk boliviano),
				'one' => q(boliviansk boliviano),
				'other' => q(bolivianske boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviansk boliviano \(1863–1963\)),
				'one' => q(boliviansk boliviano \(1863–1963\)),
				'other' => q(bolivianske bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Boliviansk peso),
				'one' => q(Boliviansk peso),
				'other' => q(Bolivianske pesos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Boliviansk mvdol),
				'one' => q(Boliviansk mvdol),
				'other' => q(Bolivianske mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brasiliansk cruzeiro novo \(1967–1986\)),
				'one' => q(Brasiliansk cruzeiro novo \(1967–1986\)),
				'other' => q(Brasilianske cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brasiliansk cruzado \(1986–1989\)),
				'one' => q(Brasiliansk cruzado \(1986–1989\)),
				'other' => q(Brasilianske cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brasiliansk cruzeiro \(1990–1993\)),
				'one' => q(Brasiliansk cruzeiro \(1990–1993\)),
				'other' => q(Brasilianske cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brasiliansk real),
				'one' => q(brasiliansk real),
				'other' => q(brasilianske realer),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brasiliansk cruzado novo \(1989–1990\)),
				'one' => q(Brasiliansk cruzado novo \(1989–1990\)),
				'other' => q(Brasilianske cruzado novo \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brasiliansk cruzeiro \(1993–1994\)),
				'one' => q(Brasiliansk cruzeiro \(1993–1994\)),
				'other' => q(Brasilianske cruzeiro \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro \(1942–1967\)),
				'one' => q(brasiliansk cruzeiro \(1942–1967\)),
				'other' => q(brasilianske cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamansk dollar),
				'one' => q(bahamansk dollar),
				'other' => q(bahamanske dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutansk ngultrum),
				'one' => q(bhutansk ngultrum),
				'other' => q(bhutanske ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmesisk kyat),
				'one' => q(Burmesisk kyat),
				'other' => q(Burmesiske kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswansk pula),
				'one' => q(botswansk pula),
				'other' => q(botswanske pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Hviderussisk rubel \(1994–1999\)),
				'one' => q(Hviderussisk rubel \(1994–1999\)),
				'other' => q(Hviderussiske rubler \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'Br.',
			display_name => {
				'currency' => q(hviderussisk rubel),
				'one' => q(hviderussisk rubel),
				'other' => q(hviderussiske rubler),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(hviderussisk rubel \(2000–2016\)),
				'one' => q(hviderussisk rubel \(2000–2016\)),
				'other' => q(hviderussiske rubler \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizisk dollar),
				'one' => q(belizisk dollar),
				'other' => q(beliziske dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(canadisk dollar),
				'one' => q(canadisk dollar),
				'other' => q(canadiske dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(congolesisk franc),
				'one' => q(congolesisk franc),
				'other' => q(congolesiske franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(schweizerfranc),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franc),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(chilensk escudo),
				'one' => q(chilensk escudo),
				'other' => q(chilenske escudos),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilensk peso),
				'one' => q(chilensk peso),
				'other' => q(chilenske pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kinesisk yuan \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kinesisk yuan),
				'one' => q(kinesisk yuan),
				'other' => q(kinesiske yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(colombiansk peso),
				'one' => q(colombiansk peso),
				'other' => q(colombianske pesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(costaricansk colón),
				'one' => q(costaricansk colón),
				'other' => q(costaricanske colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbisk dinar \(2002–2006\)),
				'one' => q(Serbisk dinar \(2002–2006\)),
				'other' => q(Serbiske dinar \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tjekkoslovakisk hard koruna),
				'one' => q(Tjekkoslovakisk hard koruna),
				'other' => q(Tjekkoslovakiske hard koruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(cubansk konvertibel peso),
				'one' => q(cubansk konvertibel peso),
				'other' => q(cubanske konvertible pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(cubansk peso),
				'one' => q(cubansk peso),
				'other' => q(cubanske pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdisk escudo),
				'one' => q(kapverdisk escudo),
				'other' => q(kapverdiske escudos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Cypriotisk pund),
				'one' => q(Cypriotisk pund),
				'other' => q(Cypriotiske pund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tjekkisk koruna),
				'one' => q(tjekkisk koruna),
				'other' => q(tjekkiske korunaer),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Østtysk mark),
				'one' => q(Østtysk mark),
				'other' => q(Østtyske mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Tysk mark),
				'one' => q(Tysk mark),
				'other' => q(Tyske mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(djiboutisk franc),
				'one' => q(djiboutisk franc),
				'other' => q(djiboutiske franc),
			},
		},
		'DKK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(dansk krone),
				'one' => q(dansk krone),
				'other' => q(danske kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikansk peso),
				'one' => q(dominikansk peso),
				'other' => q(dominikanske pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algerisk dinar),
				'one' => q(algerisk dinar),
				'other' => q(algeriske dinarer),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadoriansk sucre),
				'one' => q(Ecuadoriansk sucre),
				'other' => q(Ecuadorianske sucre),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estisk kroon),
				'one' => q(Estisk kroon),
				'other' => q(Estiske kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptisk pund),
				'one' => q(egyptisk pund),
				'other' => q(egyptiske pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreisk nakfa),
				'one' => q(eritreisk nakfa),
				'other' => q(eritreiske nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Spansk peseta \(A–konto\)),
				'one' => q(Spansk peseta \(A–konto\)),
				'other' => q(Spanske peseta \(A–konto\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Spansk peseta \(konvertibel konto\)),
				'one' => q(Spansk peseta \(konvertibel konto\)),
				'other' => q(Spanske peseta \(konvertibel konto\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spansk peseta),
				'one' => q(Spansk pesetas),
				'other' => q(Spanske pesetas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopisk birr),
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
				'currency' => q(Finsk mark),
				'one' => q(Finsk mark),
				'other' => q(Finske mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fijiansk dollar),
				'one' => q(fijiansk dollar),
				'other' => q(fijianske dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(pund fra Falklandsøerne),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Fransk franc),
				'one' => q(Fransk franc),
				'other' => q(Franske franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britisk pund),
				'one' => q(britisk pund),
				'other' => q(britiske pund),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgisk kupon larit),
				'one' => q(Georgisk kupon larit),
				'other' => q(Georgiske kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgisk lari),
				'one' => q(georgisk lari),
				'other' => q(georgiske lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanesisk cedi \(1979–2007\)),
				'one' => q(Ghanesisk cedi \(1979–2007\)),
				'other' => q(Ghanesiske cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanesisk cedi),
				'one' => q(ghanesisk cedi),
				'other' => q(ghanesiske cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarisk pund),
				'one' => q(gibraltarisk pund),
				'other' => q(gibraltariske pund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambisk dalasi),
				'one' => q(gambisk dalasi),
				'other' => q(gambiske dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineansk franc),
				'one' => q(guineansk franc),
				'other' => q(guineanske franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guineansk syli),
				'one' => q(Guineansk syli),
				'other' => q(Guineanske syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ækvatorialguineask ekwele),
				'one' => q(Ækvatorialguineask ekwele),
				'other' => q(Ækvatorialguineaske ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Græsk drakme),
				'one' => q(Græsk drakmer),
				'other' => q(Græske drakmer),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalansk quetzal),
				'one' => q(guatemalansk quetzal),
				'other' => q(guatemalanske quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugisisk guinea escudo),
				'one' => q(Portugisiske guinea escudo),
				'other' => q(Portugisiske guinea escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guineansk peso),
				'one' => q(Guinea-Bissau-peso),
				'other' => q(Guinea-Bissau-pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyansk dollar),
				'one' => q(guyansk dollar),
				'other' => q(guyanske dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(hongkongsk dollar),
				'one' => q(hongkongsk dollar),
				'other' => q(hongkongske dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduransk lempira),
				'one' => q(honduransk lempira),
				'other' => q(honduranske lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroatisk dinar),
				'one' => q(Kroatisk dinar),
				'other' => q(Kroatiske dinarer),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kroatisk kuna),
				'one' => q(kroatisk kuna),
				'other' => q(kroatiske kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitisk gourde),
				'one' => q(haitisk gourde),
				'other' => q(haitiske gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ungarsk forint),
				'one' => q(ungarsk forint),
				'other' => q(ungarske forinter),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonesisk rupiah),
				'one' => q(indonesisk rupiah),
				'other' => q(indonesiske rupiah),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irsk pund),
				'one' => q(Irsk pund),
				'other' => q(Irske pund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israelsk pund),
				'one' => q(Israelsk pund),
				'other' => q(Israelske pund),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(israelsk shekel \(1980–1985\)),
				'one' => q(israelsk shekel \(1980–1985\)),
				'other' => q(israelske shekel \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(ny israelsk shekel),
				'one' => q(ny israelsk shekel),
				'other' => q(nye israelske shekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indisk rupee),
				'one' => q(indisk rupee),
				'other' => q(indiske rupees),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakisk dinar),
				'one' => q(irakisk dinar),
				'other' => q(irakiske dinarer),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iransk rial),
				'one' => q(iransk rial),
				'other' => q(iranske rialer),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(islandsk krone \(1918–1981\)),
				'one' => q(islandsk krone \(1918–1981\)),
				'other' => q(islandske kroner \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(islandsk krone),
				'one' => q(islandsk krone),
				'other' => q(islandske kroner),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italiensk lire),
				'one' => q(Italiensk lire),
				'other' => q(Italienske lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaicansk dollar),
				'one' => q(jamaicansk dollar),
				'other' => q(jamaicanske dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordansk dinar),
				'one' => q(jordansk dinar),
				'other' => q(jordanske dinarer),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japansk yen),
				'one' => q(japansk yen),
				'other' => q(japanske yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyansk shilling),
				'one' => q(kenyansk shilling),
				'other' => q(kenyanske shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgisisk som),
				'one' => q(kirgisisk som),
				'other' => q(kirgisiske som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(cambodjansk riel),
				'one' => q(cambodjansk riel),
				'other' => q(cambodjanske riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(comorisk franc),
				'one' => q(comorisk franc),
				'other' => q(comoriske franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(nordkoreansk won),
				'one' => q(nordkoreansk won),
				'other' => q(nordkoreanske won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(sydkoreansk hwan \(1953–1962\)),
				'one' => q(sydkoreansk hwan \(1953–1962\)),
				'other' => q(sydkoreanske hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(sydkoreansk won \(1945–1953\)),
				'one' => q(sydkoreansk won \(1945–1953\)),
				'other' => q(sydkoreanske won \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(sydkoreansk won),
				'one' => q(sydkoreansk won),
				'other' => q(sydkoreanske won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitisk dinar),
				'one' => q(kuwaitisk dinar),
				'other' => q(kuwaitiske dinarer),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(caymansk dollar),
				'one' => q(caymansk dollar),
				'other' => q(caymanske dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kasakhisk tenge),
				'one' => q(kasakhisk tenge),
				'other' => q(kasakhiske tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laotisk kip),
				'one' => q(laotisk kip),
				'other' => q(laotiske kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanesisk pund),
				'one' => q(libanesisk pund),
				'other' => q(libanesiske pund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srilankansk rupee),
				'one' => q(srilankansk rupee),
				'other' => q(srilankanske rupee),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberisk dollar),
				'one' => q(liberisk dollar),
				'other' => q(liberiske dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothisk loti),
				'one' => q(lesothisk loti),
				'other' => q(lesothiske loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litauisk litas),
				'one' => q(Litauisk litas),
				'other' => q(Litauiske litai),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litauisk talonas),
				'one' => q(Litauisk talonas),
				'other' => q(Litauiske talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxembourgsk konvertibel franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxembourgsk franc),
				'one' => q(Luxembourgsk franc),
				'other' => q(Luxembourgske franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxembourgsk finansiel franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lettisk lat),
				'one' => q(Lettisk lat),
				'other' => q(Lettiske lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lettisk rubel),
				'one' => q(Lettisk rubel),
				'other' => q(Lettiske rubler),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libysk dinar),
				'one' => q(libysk dinar),
				'other' => q(libyske dinarer),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkansk dirham),
				'one' => q(marokkansk dirham),
				'other' => q(marokkanske dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkansk franc),
				'one' => q(Marokkansk franc),
				'other' => q(Marokkanske franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monegaskisk franc),
				'one' => q(monegaskisk franc),
				'other' => q(monegaskiske franc),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldovisk cupon),
				'one' => q(moldovisk cupon),
				'other' => q(moldoviske cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovisk leu),
				'one' => q(moldovisk leu),
				'other' => q(moldoviske lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskisk ariary),
				'one' => q(madagaskisk ariary),
				'other' => q(madagaskiske ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskisk franc),
				'one' => q(Madagaskisk franc),
				'other' => q(Madagaskiske franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonsk denar),
				'one' => q(makedonsk denar),
				'other' => q(makedonske denarer),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedonsk denar \(1992–1993\)),
				'one' => q(makedonsk denar \(1992–1993\)),
				'other' => q(makedonske denarer \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malisk franc),
				'one' => q(Malisk franc),
				'other' => q(Maliske franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarsk kyat),
				'one' => q(myanmarsk kyat),
				'other' => q(myanmarske kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolsk tugrik),
				'one' => q(mongolsk tugrik),
				'other' => q(mongolske tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macaosk pataca),
				'one' => q(macaosk pataca),
				'other' => q(macaoske pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauritansk ouguiya \(1973–2017\)),
				'one' => q(mauritansk ouguiya \(1973–2017\)),
				'other' => q(mauritanske ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritansk ouguiya),
				'one' => q(mauritansk ouguiya),
				'other' => q(mauritanske ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltesisk lira),
				'one' => q(Maltesisk lira),
				'other' => q(Maltesiske lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltesisk pund),
				'one' => q(Maltesisk pund),
				'other' => q(Maltesiske pund),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritisk rupee),
				'one' => q(mauritisk rupee),
				'other' => q(mauritiske rupees),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(maldivisk rupi \(1947–1981\)),
				'one' => q(maldivisk rupi \(1947–1981\)),
				'other' => q(maldiviske rupier \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivisk rufiyaa),
				'one' => q(maldivisk rufiyaa),
				'other' => q(maldiviske rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawisk kwacha),
				'one' => q(malawisk kwacha),
				'other' => q(malawiske kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexicansk peso),
				'one' => q(mexicansk peso),
				'other' => q(mexicanske pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexicansk silver peso \(1861–1992\)),
				'one' => q(Mexicansk silver peso \(1861–1992\)),
				'other' => q(Mexicanske silver peso \(1861–1992\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysisk ringgit),
				'one' => q(malaysisk ringgit),
				'other' => q(malaysiske ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambiquisk escudo),
				'one' => q(Mozambiquisk escudo),
				'other' => q(Mozambiquiske escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambiquisk metical \(1980–2006\)),
				'one' => q(Mozambiquisk metical \(1980–2006\)),
				'other' => q(Mozambiquiske metical \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambiquisk metical),
				'one' => q(mozambiquisk metical),
				'other' => q(mozambiquiske metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibisk dollar),
				'one' => q(namibisk dollar),
				'other' => q(namibiske dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigeriansk naira),
				'one' => q(nigeriansk naira),
				'other' => q(nigerianske naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguansk cordoba \(1988–1991\)),
				'one' => q(Nicaraguansk cordoba \(1988–1991\)),
				'other' => q(Nicaraguanske cordoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguansk cordoba),
				'one' => q(nicaraguansk cordoba),
				'other' => q(nicaraguanske cordoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollandsk guilder),
				'one' => q(Hollandsk gylden),
				'other' => q(Hollandske gylden),
			},
		},
		'NOK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(norsk krone),
				'one' => q(norsk krone),
				'other' => q(norske kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalesisk rupee),
				'one' => q(nepalesisk rupee),
				'other' => q(nepalesiske rupees),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(newzealandsk dollar),
				'one' => q(newzealandsk dollar),
				'other' => q(newzealandske dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omansk rial),
				'one' => q(omansk rial),
				'other' => q(omanske rialer),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamansk balboa),
				'one' => q(panamansk balboa),
				'other' => q(panamanske balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruviansk inti),
				'one' => q(peruviansk inti),
				'other' => q(peruvianske inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruansk sol),
				'one' => q(peruansk sol),
				'other' => q(peruanske soles),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruviansk sol \(1863–1965\)),
				'one' => q(peruviansk sol \(1863–1965\)),
				'other' => q(peruvianske sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuansk kina),
				'one' => q(papuansk kina),
				'other' => q(papuanske kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filippinsk peso),
				'one' => q(filippinsk peso),
				'other' => q(filippinske pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistansk rupee),
				'one' => q(pakistansk rupee),
				'other' => q(pakistanske rupee),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polsk zloty),
				'one' => q(polsk zloty),
				'other' => q(polske zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polsk zloty \(1950–1995\)),
				'one' => q(Polsk zloty \(1950–1995\)),
				'other' => q(Polske zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugisisk escudo),
				'one' => q(Portugisisk escudo),
				'other' => q(Portugisiske escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguaysk guarani),
				'one' => q(paraguaysk guarani),
				'other' => q(paraguayske guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(qatarsk rial),
				'one' => q(qatarsk rial),
				'other' => q(qatarske rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesisk dollar),
				'one' => q(rhodesisk dollar),
				'other' => q(rhodesiske dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumænsk leu \(1952–2006\)),
				'one' => q(Rumænsk leu \(1952–2006\)),
				'other' => q(Rumænske leu \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(rumænsk leu),
				'one' => q(rumænsk leu),
				'other' => q(rumænske lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbisk dinar),
				'one' => q(serbisk dinar),
				'other' => q(serbiske dinarer),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(russisk rubel),
				'one' => q(russisk rubel),
				'other' => q(russiske rubler),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russisk rubel \(1991–1998\)),
				'one' => q(Russisk rubel \(1991–1998\)),
				'other' => q(Russiske rubler \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandisk franc),
				'one' => q(rwandisk franc),
				'other' => q(rwandiske franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudiarabisk riyal),
				'one' => q(saudiarabisk riyal),
				'other' => q(saudiarabiske riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomonsk dollar),
				'one' => q(salomonsk dollar),
				'other' => q(salomonske dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychellisk rupee),
				'one' => q(seychellisk rupee),
				'other' => q(seychelliske rupees),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudansk dinar \(1992–2007\)),
				'one' => q(Sudansk dinar \(1992–2007\)),
				'other' => q(Sudanske dinar \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudansk pund),
				'one' => q(sudansk pund),
				'other' => q(sudanske pund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudansk pund \(1957–1998\)),
				'one' => q(Sudanske pund \(1957–1998\)),
				'other' => q(Sudanske pund \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(svensk krone),
				'one' => q(svensk krone),
				'other' => q(svenske kroner),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singaporeansk dollar),
				'one' => q(singaporeansk dollar),
				'other' => q(singaporeanske dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(pund fra Saint Helena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovensk tolar),
				'one' => q(Slovensk tolar),
				'other' => q(Slovenske tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovakisk koruna),
				'one' => q(Slovakisk koruna),
				'other' => q(Slovakiske koruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierraleonsk leone),
				'one' => q(sierraleonsk leone),
				'other' => q(sierraleonske leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonsk leone \(1964—2022\)),
				'one' => q(sierraleonsk leone \(1964—2022\)),
				'other' => q(sierraleonske leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somalisk shilling),
				'one' => q(somalisk shilling),
				'other' => q(somaliske shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamsk dollar),
				'one' => q(surinamsk dollar),
				'other' => q(surinamske dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamsk guilder),
				'one' => q(Surinamsk guilder),
				'other' => q(Surinamske guilder),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sydsudansk pund),
				'one' => q(sydsudansk pund),
				'other' => q(sydsudanske pund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra fra Sao Tome og Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra fra Sao Tome og Principe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovjetisk rubel),
				'one' => q(Sovjetisk rubel),
				'other' => q(Sovjetiske rubler),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadoransk colon),
				'one' => q(Salvadoransk colon),
				'other' => q(Salvadoranske colon),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syrisk pund),
				'one' => q(syrisk pund),
				'other' => q(syriske pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swazilandsk lilangeni),
				'one' => q(swazilandsk lilangeni),
				'other' => q(swazilandske lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(thailandsk baht),
				'one' => q(thailandsk baht),
				'other' => q(thailandske baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadsjikisk rubel),
				'one' => q(Tadsjikisk rubel),
				'other' => q(Tadsjikiske rubel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadsjikisk somoni),
				'one' => q(tadsjikisk somoni),
				'other' => q(tadsjikiske somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmensk manat \(1993–2009\)),
				'one' => q(Turkmensk manat \(1993–2009\)),
				'other' => q(Turkmenske manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmensk manat),
				'one' => q(turkmensk manat),
				'other' => q(turkmenske manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunesisk dinar),
				'one' => q(tunesisk dinar),
				'other' => q(tunesiske dinarer),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongansk paʻanga),
				'one' => q(tongansk paʻanga),
				'other' => q(tonganske paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Escudo fra Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Tyrkisk lire \(1922–2005\)),
				'one' => q(Tyrkisk lire \(1922–2005\)),
				'other' => q(Tyrkiske lire \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(tyrkisk lira),
				'one' => q(tyrkisk lira),
				'other' => q(tyrkiske lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidadisk dollar),
				'one' => q(trinidadisk dollar),
				'other' => q(trinidadiske dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(ny taiwansk dollar),
				'one' => q(ny taiwansk dollar),
				'other' => q(nye taiwanske dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanisk shilling),
				'one' => q(tanzanisk shilling),
				'other' => q(tanzaniske shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainsk grynia),
				'one' => q(ukrainsk grynia),
				'other' => q(ukrainske grynia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrainsk karbovanetz),
				'one' => q(Ukrainsk karbovanetz),
				'other' => q(Ukrainske karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandisk shilling \(1966–1987\)),
				'one' => q(Ugandisk shilling \(1966–1987\)),
				'other' => q(Ugandiske shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandisk shilling),
				'one' => q(ugandisk shilling),
				'other' => q(ugandiske shilling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(amerikansk dollar),
				'one' => q(amerikansk dollar),
				'other' => q(amerikanske dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Amerikansk dollar \(næste dag\)),
				'one' => q(Amerikansk dollar \(næste dag\)),
				'other' => q(Amerikanske dollar \(næste dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Amerikansk dollar \(samme dag\)),
				'one' => q(Amerikansk dollar \(samme dag\)),
				'other' => q(Amerikanske dollar \(samme dag\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayansk peso \(1975–1993\)),
				'one' => q(Uruguayansk peso \(1975–1993\)),
				'other' => q(Uruguayanske peso \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayansk peso),
				'one' => q(uruguayansk peso),
				'other' => q(uruguayanske pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(usbekisk sum),
				'one' => q(usbekisk sum),
				'other' => q(usbekiske sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelansk bolivar \(1871–2008\)),
				'one' => q(Venezuelansk bolivar \(1871–2008\)),
				'other' => q(Venezuelanske bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelansk bolivar \(2008–2018\)),
				'one' => q(venezuelansk bolivar \(2008–2018\)),
				'other' => q(venezuelanske bolivarer \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelansk bolivar),
				'one' => q(venezuelansk bolivar),
				'other' => q(venezuelanske bolivarer),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vietnamesisk dong),
				'one' => q(vietnamesisk dong),
				'other' => q(vietnamesiske dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamesisk dong \(1978–1985\)),
				'one' => q(vietnamesisk dong \(1978–1985\)),
				'other' => q(vietnamesiske dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuaisk vatu),
				'one' => q(vanuaisk vatu),
				'other' => q(vanuaiske vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoansk tala),
				'one' => q(samoansk tala),
				'other' => q(samoanske tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-franc \(BEAC\)),
				'one' => q(centralafrikansk CFA-franc),
				'other' => q(CFA-franc \(BEAC\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Sølv),
				'one' => q(troy ounce sølv),
				'other' => q(troy ounces sølv),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Guld),
				'one' => q(troy ounce guld),
				'other' => q(troy ounces guld),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(EURCO),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(EMU),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(østkaribisk dollar),
				'one' => q(østkaribisk dollar),
				'other' => q(østkaribiske dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(SDR),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(ECU),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Fransk guldfranc),
				'one' => q(Fransk guldfranc),
				'other' => q(Franske guldfranc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Fransk UIC-franc),
				'one' => q(Fransk UIC-franc),
				'other' => q(Franske UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-franc BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
				'one' => q(troy ounce palladium),
				'other' => q(troy ounces palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platin),
				'one' => q(troy ounce platin),
				'other' => q(troy ounces platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-fond),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(testvalutakode),
				'one' => q(testvaluta),
				'other' => q(testvaluta),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ukendt valuta),
				'one' => q(\(ukendt valuta\)),
				'other' => q(\(ukendt valuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Yemenitisk dinar),
				'one' => q(Yemenitisk dinar),
				'other' => q(Yemenitiske dinarer),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(yemenitisk rial),
				'one' => q(yemenitisk rial),
				'other' => q(yemenitiske rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslavisk hard dinar \(1966–1990\)),
				'one' => q(Jugoslavisk hard dinar \(1966–1990\)),
				'other' => q(Jugoslaviske hard dinar \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslavisk noviy dinar \(1994–2002\)),
				'one' => q(Jugoslavisk noviy dinar \(1994–2002\)),
				'other' => q(Jugoslaviske noviy dinar \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslavisk konvertibel dinar \(1990–1992\)),
				'one' => q(Jugoslavisk konvertibel dinar \(1990–1992\)),
				'other' => q(Jugoslaviske konvertibel dinar \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(jugoslavisk reformeret dinar \(1992–1993\)),
				'one' => q(jugoslavisk reformeret dinar \(1992–1993\)),
				'other' => q(jugoslaviske reformerede dinarer \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Sydafrikansk rand \(financial\)),
				'one' => q(Sydafrikansk rand \(financial\)),
				'other' => q(Sydafrikanske rand \(financial\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sydafrikansk rand),
				'one' => q(sydafrikansk rand),
				'other' => q(sydafrikanske rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambisk kwacha \(1968–2012\)),
				'one' => q(Zambisk kwacha \(1968–2012\)),
				'other' => q(Zambiske kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambisk kwacha),
				'one' => q(zambisk kwacha),
				'other' => q(zambiske kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Ny zairisk zaire \(1993–1998\)),
				'one' => q(Ny zairisk zaire \(1993–1998\)),
				'other' => q(Ny zairiske zaire \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairisk zaire \(1971–1993\)),
				'one' => q(Zairisk zaire \(1971–1993\)),
				'other' => q(Zairiske zaire \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwisk dollar \(1980–2008\)),
				'one' => q(Zimbabwisk dollar \(1980–2008\)),
				'other' => q(Zimbabwiske dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwisk dollar \(2009\)),
				'one' => q(Zimbabwisk dollar \(2009\)),
				'other' => q(Zimbabwiske dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwisk dollar \(2008\)),
				'one' => q(Zimbabwisk dollar \(2008\)),
				'other' => q(Zimbabwiske dollar \(2008\)),
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
							'tut',
							'babah',
							'hatur',
							'kiyahk',
							'tubah',
							'amshir',
							'baramhat',
							'baramundah',
							'bashans',
							'ba’unah',
							'abib',
							'misra',
							'nasi'
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
							'mar.',
							'apr.',
							'maj',
							'jun.',
							'jul.',
							'aug.',
							'sep.',
							'okt.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januar',
							'februar',
							'marts',
							'april',
							'maj',
							'juni',
							'juli',
							'august',
							'september',
							'oktober',
							'november',
							'december'
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
							'dhuʻl-Qiʻdah',
							'dhuʻl-Hijjah'
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
						tue => 'tirs.',
						wed => 'ons.',
						thu => 'tors.',
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
					abbreviated => {0 => '1. kvt.',
						1 => '2. kvt.',
						2 => '3. kvt.',
						3 => '4. kvt.'
					},
					wide => {0 => '1. kvartal',
						1 => '2. kvartal',
						2 => '3. kvartal',
						3 => '4. kvartal'
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
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					'afternoon1' => q{om eftermiddagen},
					'evening1' => q{om aftenen},
					'midnight' => q{midnat},
					'morning1' => q{om morgenen},
					'morning2' => q{om formiddagen},
					'night1' => q{om natten},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{eftermiddag},
					'evening1' => q{aften},
					'morning1' => q{morgen},
					'morning2' => q{formiddag},
					'night1' => q{nat},
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
		'coptic' => {
			abbreviated => {
				'0' => '0. tidsr.',
				'1' => '1. tidsr.'
			},
			narrow => {
				'0' => '0. t.',
				'1' => '1. t.'
			},
			wide => {
				'0' => '0. tidsregning',
				'1' => '1. tidsregning'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => '0. tidsr.',
				'1' => '1. tidsr.'
			},
			narrow => {
				'0' => '0. t.',
				'1' => '1. t.'
			},
			wide => {
				'0' => '0. tidsregning',
				'1' => '1. tidsregning'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			narrow => {
				'0' => 'fKr',
				'1' => 'eKr'
			},
			wide => {
				'0' => 'før Kristus',
				'1' => 'efter Kristus'
			},
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
			abbreviated => {
				'0' => 'før R.O.C.',
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d.M.y},
		},
		'gregorian' => {
			'full' => q{EEEE 'den' d. MMMM y},
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
			'short' => q{d/M/y},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH.mm.ss zzzz},
			'long' => q{HH.mm.ss z},
			'medium' => q{HH.mm.ss},
			'short' => q{HH.mm},
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
		'coptic' => {
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
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E 'd'. d.},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			M => q{M},
			MEd => q{E d.M},
			MMM => q{MMM},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M},
			d => q{d.},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y G},
			yyyyMEd => q{E d.M.y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E 'den' d.},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			Hmsv => q{HH.mm.ss v},
			Hmv => q{HH.mm v},
			M => q{M},
			MEd => q{E d.M},
			MMM => q{MMM},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E d. MMMM},
			MMMMW => q{W. 'uge' 'i' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{dd.MM},
			Md => q{d.M},
			d => q{d.},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss a v},
			hmv => q{h.mm a v},
			ms => q{mm.ss},
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
			yw => q{'uge' w 'i' Y},
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
				B => q{h B–h B},
			},
			Bhm => {
				B => q{h.mm B–h.mm B},
				h => q{h.mm–h.mm B},
				m => q{h.mm–h.mm B},
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
				G => q{E 'den' dd.MM.y GGGGG–E 'den' dd.MM.y GGGGG},
				M => q{E 'den' dd.MM.y–E 'den' dd.MM.y GGGGG},
				d => q{E 'den' dd.MM.y–E 'den' dd.MM.y GGGGG},
				y => q{E 'den' dd.MM.y–E 'den' dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E 'den' d. MMM y G–E 'den' d. MMM y G},
				M => q{E 'den' d. MMM–E 'den' d. MMM y G},
				d => q{E 'den' d. MMM–E 'den' d. MMM y G},
				y => q{E 'den' d. MMM y–E 'den' d. MMM y G},
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
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd.MM–E dd.MM},
				d => q{E dd.MM–E dd.MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E 'den' d. MMM–E 'den' d. MMM},
				d => q{E 'den' d.–E 'den' d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}-{1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y–MM.y G},
				y => q{MM.y–MM.y G},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y G},
				d => q{E dd.MM.y–E dd.MM.y G},
				y => q{E dd.MM.y–E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			yMMMEd => {
				M => q{E 'den' d. MMM–E 'den' d. MMM y G},
				d => q{E 'den' d.–E 'den' d. MMM y G},
				y => q{E 'den' d. MMM y–E 'den' d. MMM y G},
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
				M => q{dd.MM.y–dd.MM.y G},
				d => q{dd.MM.y–dd.MM.y G},
				y => q{dd.MM.y–dd.MM.y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B–h B},
			},
			Bhm => {
				B => q{h.mm B–h.mm B},
				h => q{h.mm–h.mm B},
				m => q{h.mm–h.mm B},
			},
			Gy => {
				G => q{y G – y G},
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
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd.MM–E dd.MM},
				d => q{E dd.MM–E dd.MM},
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
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}-{1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h.mm a–h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a–h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH.mm;-HH.mm),
		regionFormat => q({0}-tid),
		regionFormat => q({0}-sommertid),
		regionFormat => q({0}-normaltid),
		'Acre' => {
			long => {
				'daylight' => q#Acre-sommertid#,
				'generic' => q#Acre-tid#,
				'standard' => q#Acre-normaltid#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghansk tid#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Centralafrikansk tid#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Østafrikansk tid#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Sydafrikansk tid#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Vestafrikansk sommertid#,
				'generic' => q#Vestafrikansk tid#,
				'standard' => q#Vestafrikansk normaltid#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-sommertid#,
				'generic' => q#Alaska-tid#,
				'standard' => q#Alaska-normaltid#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almaty-sommertid#,
				'generic' => q#Almaty-tid#,
				'standard' => q#Almaty-normaltid#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonas-sommertid#,
				'generic' => q#Amazonas-tid#,
				'standard' => q#Amazonas-normaltid#,
			},
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caymanøerne#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central-sommertid#,
				'generic' => q#Central-tid#,
				'standard' => q#Central-normaltid#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern-sommertid#,
				'generic' => q#Eastern-tid#,
				'standard' => q#Eastern-normaltid#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain-sommertid#,
				'generic' => q#Mountain-tid#,
				'standard' => q#Mountain-normaltid#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific-sommertid#,
				'generic' => q#Pacific-tid#,
				'standard' => q#Pacific-normaltid#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr-sommertid#,
				'generic' => q#Anadyr-tid#,
				'standard' => q#Anadyr-normaltid#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia-sommertid#,
				'generic' => q#Apia-tid#,
				'standard' => q#Apia-normaltid#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtau-sommertid#,
				'generic' => q#Aqtau-tid#,
				'standard' => q#Aqtau-normaltid#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtobe-sommertid#,
				'generic' => q#Aqtobe-tid#,
				'standard' => q#Aqtobe-normaltid#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabisk sommertid#,
				'generic' => q#Arabisk tid#,
				'standard' => q#Arabisk normaltid#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinsk sommertid#,
				'generic' => q#Argentisk tid#,
				'standard' => q#Argentinsk normaltid#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Vestargentinsk sommertid#,
				'generic' => q#Vestargentinsk tid#,
				'standard' => q#Vestargentinsk normaltid#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armensk sommertid#,
				'generic' => q#Armensk tid#,
				'standard' => q#Armensk normaltid#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
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
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusjanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtjatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokusnetsk#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh City#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
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
				'daylight' => q#Atlantic-sommertid#,
				'generic' => q#Atlantic-tid#,
				'standard' => q#Atlantic-normaltid#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorerne#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#De Kanariske Øer#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Færøerne#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Centralaustralsk sommertid#,
				'generic' => q#Centralaustralsk tid#,
				'standard' => q#Centralaustralsk normaltid#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Vestlig centralaustralsk sommertid#,
				'generic' => q#Vestlig centralaustralsk tid#,
				'standard' => q#Vestlig centralaustralsk normaltid#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Østaustralsk sommertid#,
				'generic' => q#Østaustralsk tid#,
				'standard' => q#Østaustralsk normaltid#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Vestaustralsk sommertid#,
				'generic' => q#Vestaustralsk tid#,
				'standard' => q#Vestaustralsk normaltid#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbajdsjansk sommertid#,
				'generic' => q#Aserbajdsjansk tid#,
				'standard' => q#Aserbajdsjansk normaltid#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorerne-sommertid#,
				'generic' => q#Azorerne-tid#,
				'standard' => q#Azorerne-normaltid#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesh-sommertid#,
				'generic' => q#Bangladesh-tid#,
				'standard' => q#Bangladesh-normaltid#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan-tid#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliviansk tid#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasiliansk sommertid#,
				'generic' => q#Brasiliansk tid#,
				'standard' => q#Brasiliansk normaltid#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam-tid#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kap Verde-sommertid#,
				'generic' => q#Kap Verde-tid#,
				'standard' => q#Kap Verde-normaltid#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-tid#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham-sommertid#,
				'generic' => q#Chatham-tid#,
				'standard' => q#Chatham-normaltid#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilensk sommertid#,
				'generic' => q#Chilensk tid#,
				'standard' => q#Chilensk normaltid#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kinesisk sommertid#,
				'generic' => q#Kinesisk tid#,
				'standard' => q#Kinesisk normaltid#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Juleøen-normaltid#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocosøerne-normaltid#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombiansk sommertid#,
				'generic' => q#Colombiansk tid#,
				'standard' => q#Colombiansk normaltid#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookøerne-sommertid#,
				'generic' => q#Cookøerne-tid#,
				'standard' => q#Cookøerne-normaltid#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cubansk sommertid#,
				'generic' => q#Cubansk tid#,
				'standard' => q#Cubansk normaltid#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis-tid#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville-tid#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Østtimor-tid#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Påskeøen-sommertid#,
				'generic' => q#Påskeøen-tid#,
				'standard' => q#Påskeøen-normaltid#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadoriansk tid#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordineret universaltid#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ukendt by#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#København#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irsk normaltid#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britisk sommertid#,
			},
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanet#,
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
				'daylight' => q#Centraleuropæisk sommertid#,
				'generic' => q#Centraleuropæisk tid#,
				'standard' => q#Centraleuropæisk normaltid#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Østeuropæisk sommertid#,
				'generic' => q#Østeuropæisk tid#,
				'standard' => q#Østeuropæisk normaltid#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Fjernøsteuropæisk tid#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Vesteuropæisk sommertid#,
				'generic' => q#Vesteuropæisk tid#,
				'standard' => q#Vesteuropæisk normaltid#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandsøerne-sommertid#,
				'generic' => q#Falklandsøerne-tid#,
				'standard' => q#Falklandsøerne-normaltid#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fijiansk sommertid#,
				'generic' => q#Fijiansk tid#,
				'standard' => q#Fijiansk normaltid#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Fransk Guyana-tid#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Franske Sydlige og Antarktiske Territorier-tid#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos-tid#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier-tid#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgisk sommertid#,
				'generic' => q#Georgisk tid#,
				'standard' => q#Georgisk normaltid#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbertøerne-tid#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Østgrønlandsk sommertid#,
				'generic' => q#Østgrønlandsk tid#,
				'standard' => q#Østgrønlandsk normaltid#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Vestgrønlandsk sommertid#,
				'generic' => q#Vestgrønlandsk tid#,
				'standard' => q#Vestgrønlandsk normaltid#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam-normaltid#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golflandene-normaltid#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana-tid#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian-sommertid#,
				'generic' => q#Hawaii-Aleutian-tid#,
				'standard' => q#Hawaii-Aleutian-normaltid#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkong-sommertid#,
				'generic' => q#Hongkong-tid#,
				'standard' => q#Hongkong-normaltid#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd-sommertid#,
				'generic' => q#Hovd-tid#,
				'standard' => q#Hovd-normaltid#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indisk normaltid#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Juleøen#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comorerne#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiverne#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiske Ocean-normaltid#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokina-tid#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Centralindonesisk tid#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Østindonesisk tid#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Vestindonesisk tid#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iransk sommertid#,
				'generic' => q#Iransk tid#,
				'standard' => q#Iransk normaltid#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk-sommertid#,
				'generic' => q#Irkutsk-tid#,
				'standard' => q#Irkutsk-normaltid#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelsk sommertid#,
				'generic' => q#Israelsk tid#,
				'standard' => q#Israelsk normaltid#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japansk sommertid#,
				'generic' => q#Japansk tid#,
				'standard' => q#Japansk normaltid#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamchatski sommertid#,
				'generic' => q#Petropavlovsk-Kamchatski tid#,
				'standard' => q#Petropavlovsk-Kamchatski normaltid#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kasakhstansk tid#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Østkasakhstansk tid#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Vestkasakhstansk tid#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreansk sommertid#,
				'generic' => q#Koreansk tid#,
				'standard' => q#Koreansk normaltid#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae-tid#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk-sommertid#,
				'generic' => q#Krasnojarsk-tid#,
				'standard' => q#Krasnojarsk-normaltid#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisisk tid#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Langa tid#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Linjeøerne-tid#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe-sommertid#,
				'generic' => q#Lord Howe-tid#,
				'standard' => q#Lord Howe-normaltid#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macao-sommertid#,
				'generic' => q#Macao-tid#,
				'standard' => q#Macao-normaltid#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan-sommertid#,
				'generic' => q#Magadan-tid#,
				'standard' => q#Magadan-normaltid#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysia-tid#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldiverne-tid#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas-tid#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshalløerne-tid#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius-sommertid#,
				'generic' => q#Mauritius-tid#,
				'standard' => q#Mauritius-normaltid#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson-tid#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexicansk Pacific-sommertid#,
				'generic' => q#Mexicansk Pacific-tid#,
				'standard' => q#Mexicansk Pacific-normaltid#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Bator-sommertid#,
				'generic' => q#Ulan Bator-tid#,
				'standard' => q#Ulan Bator-normaltid#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva-sommertid#,
				'generic' => q#Moskva-tid#,
				'standard' => q#Moskva-normaltid#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar-tid#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru-tid#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalesisk tid#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ny Kaledonien-sommertid#,
				'generic' => q#Ny Kaledonien-tid#,
				'standard' => q#Ny Kaledonien-normaltid#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Newzealandsk sommertid#,
				'generic' => q#Newzealandsk tid#,
				'standard' => q#Newzealandsk normaltid#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundlandsk sommertid#,
				'generic' => q#Newfoundlandsk tid#,
				'standard' => q#Newfoundlandsk normaltid#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue-tid#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Island-sommertid#,
				'generic' => q#Norfolk Island-tid#,
				'standard' => q#Norfolk Island-normaltid#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha-sommertid#,
				'generic' => q#Fernando de Noronha-tid#,
				'standard' => q#Fernando de Noronha-normaltid#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Nordmarianerne-tid#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk-sommertid#,
				'generic' => q#Novosibirsk-tid#,
				'standard' => q#Novosibirsk-normaltid#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk-sommertid#,
				'generic' => q#Omsk-tid#,
				'standard' => q#Omsk-normaltid#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Påskeøen#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistansk sommertid#,
				'generic' => q#Pakistansk tid#,
				'standard' => q#Pakistansk normaltid#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau-tid#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Ny Guinea-tid#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayansk sommertid#,
				'generic' => q#Paraguayansk tid#,
				'standard' => q#Paraguayansk normaltid#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruviansk sommertid#,
				'generic' => q#Peruviansk tid#,
				'standard' => q#Peruviansk normaltid#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippinsk sommertid#,
				'generic' => q#Filippinsk tid#,
				'standard' => q#Filippinsk normaltid#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixøen-tid#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint Pierre- og Miquelon-sommertid#,
				'generic' => q#Saint Pierre- og Miquelon-tid#,
				'standard' => q#Saint Pierre- og Miquelon-normaltid#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn-tid#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape-tid#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang-tid#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylorda-sommertid#,
				'generic' => q#Qyzylorda-tid#,
				'standard' => q#Qyzylorda-normaltid#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunion-tid#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera-tid#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin-sommertid#,
				'generic' => q#Sakhalin-tid#,
				'standard' => q#Sakhalin-normaltid#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara-sommertid#,
				'generic' => q#Samara-tid#,
				'standard' => q#Samara-normaltid#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoansk sommertid#,
				'generic' => q#Samoansk tid#,
				'standard' => q#Samoansk normaltid#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychellisk tid#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapore-tid#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonøerne-tid#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#South Georgia-tid#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam-tid#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa-tid#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti-tid#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei-sommertid#,
				'generic' => q#Taipei-tid#,
				'standard' => q#Taipei-normaltid#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadsjikisk tid#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-tid#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongansk sommertid#,
				'generic' => q#Tongansk tid#,
				'standard' => q#Tongansk normaltid#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk-tid#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmensk sommertid#,
				'generic' => q#Turkmensk tid#,
				'standard' => q#Turkmensk normaltid#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu-tid#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayansk sommertid#,
				'generic' => q#Uruguayansk tid#,
				'standard' => q#Uruguayansk normaltid#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekisk sommertid#,
				'generic' => q#Usbekisk tid#,
				'standard' => q#Usbekisk normaltid#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu-sommertid#,
				'generic' => q#Vanuatu-tid#,
				'standard' => q#Vanuatu-normaltid#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelansk tid#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok-sommertid#,
				'generic' => q#Vladivostok-tid#,
				'standard' => q#Vladivostok-normaltid#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd-sommertid#,
				'generic' => q#Volgograd-tid#,
				'standard' => q#Volgograd-normaltid#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok-tid#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Island-tid#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis og Futuna-tid#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk-sommertid#,
				'generic' => q#Jakutsk-tid#,
				'standard' => q#Jakutsk-normaltid#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg-sommertid#,
				'generic' => q#Jekaterinburg-tid#,
				'standard' => q#Jekaterinburg-normaltid#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon-tid#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
