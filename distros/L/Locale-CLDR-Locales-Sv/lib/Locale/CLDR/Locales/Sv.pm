=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sv - Package for language Swedish

=cut

package Locale::CLDR::Locales::Sv;
# This file auto generated from Data\common\main\sv.xml
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
has 'WordBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$MidLetter' => '\p{Word_Break=MidLetter}',
	]}
);
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-neuter','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-reale','spellout-ordinal-neuter','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-reale','digits-ordinal-neuter','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal-reale','digits-ordinal' ]},
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
					rule => q(=%digits-ordinal-feminine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-feminine=),
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
					rule => q(=#,##0=$(ordinal,one{:a}other{:e})$),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{:a}other{:e})$),
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
					rule => q(=#,##0=:e),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=:e),
				},
			},
		},
		'digits-ordinal-neuter' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-feminine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-feminine=),
				},
			},
		},
		'digits-ordinal-reale' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-feminine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-feminine=),
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
					rule => q(nde),
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
					rule => q(nde),
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
		'spellout-cardinal-feminine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-neuter' => {
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
		'spellout-cardinal-reale' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(noll),
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
					rule => q(=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjugo[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trettio[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fyrtio[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femtio[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextio[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjuttio[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åttio[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nittio[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundra[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ettusen[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-reale←­tusen[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(en miljon[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-reale← miljoner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(en miljard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-reale← miljarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(en biljon[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-reale← biljoner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(en biljard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-reale← biljarder[ →→]),
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
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(noll),
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
					rule => q(två),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fyra),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fem),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sex),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sju),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åtta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nio),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tio),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elva),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolv),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretton),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjorton),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(femton),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sexton),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sjutton),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(arton),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nitton),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjugo[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trettio[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fyrtio[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femtio[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextio[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjuttio[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åttio[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nittio[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundra[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-t←­tusen[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(en miljon[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-reale← miljoner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(en miljard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-reale← miljarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(en biljon[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-reale← biljoner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(en biljard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-reale← biljarder[ →→]),
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
		'spellout-numbering-t' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(et),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(två),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fyra),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fem),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sex),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sju),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åtta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nio),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tio),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elva),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolv),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretton),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjorton),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(femton),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sexton),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sjutton),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(arton),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nitton),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjugo[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trettio[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fyrtio[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femtio[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextio[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjuttio[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åttio[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nittio[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundra[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ERROR),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ERROR),
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
					rule => q(←←­hundra[­→→]),
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-neuter=),
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
					rule => q(nollte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(förste),
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
					rule => q(fjärde),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(femte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sjätte),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjunde),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åttonde),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nionde),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tionde),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elfte),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolfte),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjugo→%%ord-masc-nde→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trettio→%%ord-masc-nde→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fyrtio→%%ord-masc-nde→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femtio→%%ord-masc-nde→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextio→%%ord-masc-nde→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjuttio→%%ord-masc-nde→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åttio→%%ord-masc-nde→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nittio→%%ord-masc-nde→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundra→%%ord-masc-de→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-t←­tusen→%%ord-masc-de→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(en miljon→%%ord-masc-te→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-reale← miljon→%%ord-masc-teer→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(en miljard→%%ord-masc-te→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-reale← miljard→%%ord-masc-teer→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(en biljon→%%ord-masc-te→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-reale← biljon→%%ord-masc-teer→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(en biljard→%%ord-masc-te→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-reale← biljard→%%ord-masc-teer→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=':e),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=':e),
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
					rule => q(nollte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(första),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(andra),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjugo→%%ord-fem-nde→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trettio→%%ord-fem-nde→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fyrtio→%%ord-fem-nde→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femtio→%%ord-fem-nde→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextio→%%ord-fem-nde→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjuttio→%%ord-fem-nde→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åttio→%%ord-fem-nde→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nittio→%%ord-fem-nde→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundra→%%ord-fem-de→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-t←­tusen→%%ord-fem-de→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(en miljon→%%ord-fem-te→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-reale← miljon→%%ord-fem-teer→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(en miljard→%%ord-fem-te→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-reale← miljard→%%ord-fem-teer→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(en biljon→%%ord-fem-te→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-reale← biljon→%%ord-fem-teer→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(en biljard→%%ord-fem-te→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-reale← biljard→%%ord-fem-teer→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=':e),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=':e),
				},
			},
		},
		'spellout-ordinal-reale' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-neuter=),
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
 				'ab' => 'abchaziska',
 				'ace' => 'acehnesiska',
 				'ach' => 'acholi',
 				'ada' => 'adangme',
 				'ady' => 'adygeiska',
 				'ae' => 'avestiska',
 				'aeb' => 'tunisisk arabiska',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkadiska',
 				'akz' => 'Alabama-muskogee',
 				'ale' => 'aleutiska',
 				'aln' => 'gegiska',
 				'alt' => 'sydaltaiska',
 				'am' => 'amhariska',
 				'an' => 'aragonesiska',
 				'ang' => 'fornengelska',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabiska',
 				'ar_001' => 'modern standardarabiska',
 				'arc' => 'arameiska',
 				'arn' => 'mapudungun',
 				'aro' => 'araoniska',
 				'arp' => 'arapaho',
 				'arq' => 'algerisk arabiska',
 				'ars' => 'najdiarabiska',
 				'ars@alt=menu' => 'arabiska (najdi)',
 				'arw' => 'arawakiska',
 				'ary' => 'marockansk arabiska',
 				'arz' => 'egyptisk arabiska',
 				'as' => 'assamesiska',
 				'asa' => 'asu',
 				'ase' => 'amerikanskt teckenspråk',
 				'ast' => 'asturiska',
 				'atj' => 'atikamekw',
 				'av' => 'avariska',
 				'avk' => 'kotava',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbajdzjanska',
 				'az@alt=short' => 'azeriska',
 				'ba' => 'basjkiriska',
 				'bal' => 'baluchiska',
 				'ban' => 'balinesiska',
 				'bar' => 'bayerska',
 				'bas' => 'basa',
 				'bax' => 'bamunska',
 				'bbc' => 'batak-toba',
 				'bbj' => 'ghomala',
 				'be' => 'belarusiska',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bew' => 'betawiska',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'bagada',
 				'bg' => 'bulgariska',
 				'bgc' => 'hariyanvi',
 				'bgn' => 'västbaluchiska',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bjn' => 'banjariska',
 				'bkm' => 'bamekon',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetanska',
 				'bpy' => 'bishnupriya',
 				'bqi' => 'bakhtiari',
 				'br' => 'bretonska',
 				'bra' => 'braj',
 				'brh' => 'brahuiska',
 				'brx' => 'bodo',
 				'bs' => 'bosniska',
 				'bss' => 'bakossi',
 				'bua' => 'burjätiska',
 				'bug' => 'buginesiska',
 				'bum' => 'boulou',
 				'byn' => 'blin',
 				'byv' => 'bagangte',
 				'ca' => 'katalanska',
 				'cad' => 'caddo',
 				'car' => 'karibiska',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'tjetjenska',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'chagatai',
 				'chk' => 'chuukesiska',
 				'chm' => 'mariska',
 				'chn' => 'chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokesiska',
 				'chy' => 'cheyenne',
 				'ckb' => 'centralkurdiska',
 				'ckb@alt=menu' => 'kurdiska (sorani)',
 				'ckb@alt=variant' => 'soranisk kurdiska',
 				'clc' => 'chilcotin',
 				'co' => 'korsikanska',
 				'cop' => 'koptiska',
 				'cps' => 'kapisnon',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'krimtatariska',
 				'crj' => 'sydostcree',
 				'crk' => 'slättcree',
 				'crl' => 'nordost-cree',
 				'crm' => 'moose cree',
 				'crr' => 'Carolina-algonkinska',
 				'crs' => 'seychellisk kreol',
 				'cs' => 'tjeckiska',
 				'csb' => 'kasjubiska',
 				'csw' => 'träskcree',
 				'cu' => 'kyrkslaviska',
 				'cv' => 'tjuvasjiska',
 				'cy' => 'walesiska',
 				'da' => 'danska',
 				'dak' => 'dakota',
 				'dar' => 'darginska',
 				'dav' => 'taita',
 				'de' => 'tyska',
 				'de_AT' => 'österrikisk tyska',
 				'de_CH' => 'schweizisk högtyska',
 				'del' => 'delaware',
 				'den' => 'slavej',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'lågsorbiska',
 				'dtp' => 'centraldusun',
 				'dua' => 'duala',
 				'dum' => 'medelnederländska',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egl' => 'emiliska',
 				'egy' => 'fornegyptiska',
 				'eka' => 'ekajuk',
 				'el' => 'grekiska',
 				'elx' => 'elamitiska',
 				'en' => 'engelska',
 				'en_AU' => 'australisk engelska',
 				'en_CA' => 'kanadensisk engelska',
 				'en_GB' => 'brittisk engelska',
 				'en_US' => 'amerikansk engelska',
 				'enm' => 'medelengelska',
 				'eo' => 'esperanto',
 				'es' => 'spanska',
 				'es_419' => 'latinamerikansk spanska',
 				'es_ES' => 'europeisk spanska',
 				'es_MX' => 'mexikansk spanska',
 				'esu' => 'centralalaskisk jupiska',
 				'et' => 'estniska',
 				'eu' => 'baskiska',
 				'ewo' => 'ewondo',
 				'ext' => 'extremaduriska',
 				'fa' => 'persiska',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulani',
 				'fi' => 'finska',
 				'fil' => 'filippinska',
 				'fit' => 'meänkieli',
 				'fj' => 'fijianska',
 				'fo' => 'färöiska',
 				'fon' => 'fonspråket',
 				'fr' => 'franska',
 				'fr_CA' => 'kanadensisk franska',
 				'fr_CH' => 'schweizisk franska',
 				'frc' => 'cajun-franska',
 				'frm' => 'medelfranska',
 				'fro' => 'fornfranska',
 				'frp' => 'frankoprovensalska',
 				'frr' => 'nordfrisiska',
 				'frs' => 'östfrisiska',
 				'fur' => 'friulianska',
 				'fy' => 'västfrisiska',
 				'ga' => 'iriska',
 				'gaa' => 'gã',
 				'gag' => 'gagauziska',
 				'gan' => 'gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gbz' => 'zoroastrisk dari',
 				'gd' => 'skotsk gäliska',
 				'gez' => 'etiopiska',
 				'gil' => 'gilbertiska',
 				'gl' => 'galiciska',
 				'glk' => 'gilaki',
 				'gmh' => 'medelhögtyska',
 				'gn' => 'guaraní',
 				'goh' => 'fornhögtyska',
 				'gom' => 'Goa-konkani',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotiska',
 				'grb' => 'grebo',
 				'grc' => 'forngrekiska',
 				'gsw' => 'schweizertyska',
 				'gu' => 'gujarati',
 				'guc' => 'wayuu',
 				'gur' => 'farefare',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'hakka',
 				'haw' => 'hawaiiska',
 				'hax' => 'sydhaida',
 				'he' => 'hebreiska',
 				'hi' => 'hindi',
 				'hi_Latn' => 'hindi (latinsk)',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hif' => 'Fiji-hindi',
 				'hil' => 'hiligaynon',
 				'hit' => 'hettitiska',
 				'hmn' => 'hmongspråk',
 				'ho' => 'hirimotu',
 				'hr' => 'kroatiska',
 				'hsb' => 'högsorbiska',
 				'hsn' => 'xiang',
 				'ht' => 'haitiska',
 				'hu' => 'ungerska',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armeniska',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'ibanska',
 				'ibb' => 'ibibio',
 				'id' => 'indonesiska',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'szezuan i',
 				'ik' => 'inupiak',
 				'ikt' => 'inuktun',
 				'ilo' => 'iloko',
 				'inh' => 'ingusjiska',
 				'io' => 'ido',
 				'is' => 'isländska',
 				'it' => 'italienska',
 				'iu' => 'inuktitut',
 				'izh' => 'ingriska',
 				'ja' => 'japanska',
 				'jam' => 'jamaikansk engelsk kreol',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'kimashami',
 				'jpr' => 'judisk persiska',
 				'jrb' => 'judisk arabiska',
 				'jut' => 'jylländska',
 				'jv' => 'javanesiska',
 				'ka' => 'georgiska',
 				'kaa' => 'karakalpakiska',
 				'kab' => 'kabyliska',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardinska',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kapverdiska',
 				'ken' => 'kenjang',
 				'kfo' => 'koro',
 				'kg' => 'kikongo',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotanesiska',
 				'khq' => 'Timbuktu-songhai',
 				'khw' => 'khowar',
 				'ki' => 'kikuyu',
 				'kiu' => 'kirmanjki',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakiska',
 				'kkj' => 'mkako',
 				'kl' => 'grönländska',
 				'kln' => 'kalenjin',
 				'km' => 'kambodjanska',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreanska',
 				'koi' => 'komi-permjakiska',
 				'kok' => 'konkani',
 				'kos' => 'kosreanska',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'kri' => 'krio',
 				'krj' => 'kinaray-a',
 				'krl' => 'karelska',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiriska',
 				'ksb' => 'kisambaa',
 				'ksf' => 'bafia',
 				'ksh' => 'kölniska',
 				'ku' => 'kurdiska',
 				'kum' => 'kumykiska',
 				'kut' => 'kutenaj',
 				'kv' => 'kome',
 				'kw' => 'korniska',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'kirgiziska',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgiska',
 				'lez' => 'lezghien',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'luganda',
 				'li' => 'limburgiska',
 				'lij' => 'liguriska',
 				'lil' => 'lillooet',
 				'liv' => 'livoniska',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardiska',
 				'ln' => 'lingala',
 				'lo' => 'laotiska',
 				'lol' => 'mongo',
 				'lou' => 'louisiana-kreol',
 				'loz' => 'lozi',
 				'lrc' => 'nordluri',
 				'lsm' => 'saamia',
 				'lt' => 'litauiska',
 				'ltg' => 'lettgalliska',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseño',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'luhya',
 				'lv' => 'lettiska',
 				'lzh' => 'litterär kineiska',
 				'lzz' => 'laziska',
 				'mad' => 'maduresiska',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mande',
 				'mas' => 'massajiska',
 				'mde' => 'maba',
 				'mdf' => 'moksja',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauritansk kreol',
 				'mg' => 'malagassiska',
 				'mga' => 'medeliriska',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshalliska',
 				'mi' => 'maori',
 				'mic' => 'mi’kmaq',
 				'min' => 'minangkabau',
 				'mk' => 'makedonska',
 				'ml' => 'malayalam',
 				'mn' => 'mongoliska',
 				'mnc' => 'manchuriska',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'mrj' => 'västmariska',
 				'ms' => 'malajiska',
 				'mt' => 'maltesiska',
 				'mua' => 'mundang',
 				'mul' => 'flera språk',
 				'mus' => 'muskogee',
 				'mwl' => 'mirandesiska',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'my' => 'burmesiska',
 				'mye' => 'myene',
 				'myv' => 'erjya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauruanska',
 				'nan' => 'min nan',
 				'nap' => 'napolitanska',
 				'naq' => 'nama',
 				'nb' => 'norskt bokmål',
 				'nd' => 'nordndebele',
 				'nds' => 'lågtyska',
 				'nds_NL' => 'lågsaxiska',
 				'ne' => 'nepalesiska',
 				'new' => 'newariska',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueanska',
 				'njo' => 'ao-naga',
 				'nl' => 'nederländska',
 				'nl_BE' => 'flamländska',
 				'nmg' => 'kwasio',
 				'nn' => 'nynorska',
 				'nnh' => 'bamileké-ngiemboon',
 				'no' => 'norska',
 				'nog' => 'nogai',
 				'non' => 'fornnordiska',
 				'nov' => 'novial',
 				'nqo' => 'n-kå',
 				'nr' => 'sydndebele',
 				'nso' => 'nordsotho',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nwc' => 'klassisk newariska',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitanska',
 				'oj' => 'odjibwa',
 				'ojb' => 'nordvästojibwa',
 				'ojc' => 'ojibwa',
 				'ojs' => 'oji-cree',
 				'ojw' => 'västojibwe',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'ossetiska',
 				'osa' => 'osage',
 				'ota' => 'ottomanska',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'medelpersiska',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palau',
 				'pcd' => 'pikardiska',
 				'pcm' => 'nigeriansk pidgin',
 				'pdc' => 'Pennsylvaniatyska',
 				'pdt' => 'mennonitisk lågtyska',
 				'peo' => 'fornpersiska',
 				'pfl' => 'Pfalz-tyska',
 				'phn' => 'feniciska',
 				'pi' => 'pali',
 				'pis' => 'pidginspråk',
 				'pl' => 'polska',
 				'pms' => 'piemontesiska',
 				'pnt' => 'pontiska',
 				'pon' => 'pohnpeiska',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'fornpreussiska',
 				'pro' => 'fornprovensalska',
 				'ps' => 'afghanska',
 				'ps@alt=variant' => 'pashto',
 				'pt' => 'portugisiska',
 				'pt_BR' => 'brasiliansk portugisiska',
 				'pt_PT' => 'europeisk portugisiska',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'qug' => 'Chimborazo-höglandskichwa',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonganska',
 				'rgn' => 'romagnol',
 				'rhg' => 'ruáingga',
 				'rif' => 'riffianska',
 				'rm' => 'rätoromanska',
 				'rn' => 'rundi',
 				'ro' => 'rumänska',
 				'ro_MD' => 'moldaviska',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'rtm' => 'rotumänska',
 				'ru' => 'ryska',
 				'rue' => 'rusyn',
 				'rug' => 'rovianska',
 				'rup' => 'arumänska',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakutiska',
 				'sam' => 'samaritanska',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'saz' => 'saurashtra',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardinska',
 				'scn' => 'sicilianska',
 				'sco' => 'skotska',
 				'sd' => 'sindhi',
 				'sdc' => 'sassaresisk sardiska',
 				'sdh' => 'sydkurdiska',
 				'se' => 'nordsamiska',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sei' => 'seri',
 				'sel' => 'selkup',
 				'ses' => 'songhai',
 				'sg' => 'sango',
 				'sga' => 'forniriska',
 				'sgs' => 'samogitiska',
 				'sh' => 'serbokroatiska',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'Tchad-arabiska',
 				'si' => 'singalesiska',
 				'sid' => 'sidamo',
 				'sk' => 'slovakiska',
 				'sl' => 'slovenska',
 				'slh' => 'sydlushootseed',
 				'sli' => 'lågsilesiska',
 				'sly' => 'selayar',
 				'sm' => 'samoanska',
 				'sma' => 'sydsamiska',
 				'smj' => 'lulesamiska',
 				'smn' => 'enaresamiska',
 				'sms' => 'skoltsamiska',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somaliska',
 				'sog' => 'sogdiska',
 				'sq' => 'albanska',
 				'sr' => 'serbiska',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sydsotho',
 				'stq' => 'saterfrisiska',
 				'str' => 'sundsalishanska',
 				'su' => 'sundanesiska',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeriska',
 				'sv' => 'svenska',
 				'sw' => 'swahili',
 				'sw_CD' => 'Kongo-swahili',
 				'swb' => 'shimaoré',
 				'syc' => 'klassisk syriska',
 				'syr' => 'syriska',
 				'szl' => 'silesiska',
 				'ta' => 'tamil',
 				'tce' => 'sydtutchone',
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadzjikiska',
 				'tgx' => 'tagish',
 				'th' => 'thailändska',
 				'tht' => 'tahltan',
 				'ti' => 'tigrinja',
 				'tig' => 'tigré',
 				'tiv' => 'tivi',
 				'tk' => 'turkmeniska',
 				'tkl' => 'tokelauiska',
 				'tkr' => 'tsakhur',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonska',
 				'tli' => 'tlingit',
 				'tly' => 'talysh',
 				'tmh' => 'tamashek',
 				'tn' => 'tswana',
 				'to' => 'tonganska',
 				'tog' => 'nyasatonganska',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turkiska',
 				'tru' => 'turoyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakodiska',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatariska',
 				'ttm' => 'nordtutchone',
 				'ttt' => 'muslimsk tatariska',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluanska',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiska',
 				'tyv' => 'tuviniska',
 				'tzm' => 'centralmarockansk tamazight',
 				'udm' => 'udmurtiska',
 				'ug' => 'uiguriska',
 				'ug@alt=variant' => 'östturkiska',
 				'uga' => 'ugaritiska',
 				'uk' => 'ukrainska',
 				'umb' => 'umbundu',
 				'und' => 'obestämt språk',
 				'ur' => 'urdu',
 				'uz' => 'uzbekiska',
 				'vai' => 'vaj',
 				've' => 'venda',
 				'vec' => 'venetianska',
 				'vep' => 'veps',
 				'vi' => 'vietnamesiska',
 				'vls' => 'västflamländska',
 				'vmf' => 'Main-frankiska',
 				'vo' => 'volapük',
 				'vot' => 'votiska',
 				'vro' => 'võru',
 				'vun' => 'vunjo',
 				'wa' => 'vallonska',
 				'wae' => 'walsertyska',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu',
 				'xal' => 'kalmuckiska',
 				'xh' => 'xhosa',
 				'xmf' => 'mingrelianska',
 				'xog' => 'lusoga',
 				'yao' => 'kiyao',
 				'yap' => 'japetiska',
 				'yav' => 'yangben',
 				'ybb' => 'bamileké-jemba',
 				'yi' => 'jiddisch',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantonesiska',
 				'za' => 'zhuang',
 				'zap' => 'zapotek',
 				'zbl' => 'blissymboler',
 				'zea' => 'zeeländska',
 				'zen' => 'zenaga',
 				'zgh' => 'marockansk standard-tamazight',
 				'zh' => 'kinesiska',
 				'zh@alt=menu' => 'mandarin',
 				'zh_Hans' => 'förenklad kinesiska',
 				'zh_Hant' => 'traditionell kinesiska',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'inget språkligt innehåll',
 				'zza' => 'zazaiska',

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
			'Adlm' => 'adlamiska',
 			'Afak' => 'afakiska',
 			'Aghb' => 'kaukasiska albanska',
 			'Ahom' => 'ahom',
 			'Arab' => 'arabiska',
 			'Aran' => 'nastaliq',
 			'Armi' => 'imperisk arameiska',
 			'Armn' => 'armeniska',
 			'Avst' => 'avestiska',
 			'Bali' => 'balinesiska',
 			'Bamu' => 'bamunska',
 			'Bass' => 'bassaiska vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengaliska',
 			'Bhks' => 'bhaiksukiska',
 			'Blis' => 'blissymboler',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brami',
 			'Brai' => 'punktskrift',
 			'Bugi' => 'buginesiska',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'kanadensiska stavelsetecken',
 			'Cari' => 'kariska',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Chrs' => 'khwarezmiska',
 			'Cirt' => 'cirt',
 			'Copt' => 'koptiska',
 			'Cpmn' => 'cypro-minoisk skrift',
 			'Cprt' => 'cypriotiska',
 			'Cyrl' => 'kyrilliska',
 			'Cyrs' => 'fornkyrkoslavisk kyrilliska',
 			'Deva' => 'devanagari',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogriska',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'Duployéstenografiska',
 			'Egyd' => 'demotiska',
 			'Egyh' => 'hieratiska',
 			'Egyp' => 'egyptiska hieroglyfer',
 			'Elba' => 'elbasiska',
 			'Elym' => 'elymaiska',
 			'Ethi' => 'etiopiska',
 			'Geok' => 'kutsuri',
 			'Geor' => 'georgiska',
 			'Glag' => 'glagolitiska',
 			'Gong' => 'gunjalgondiska',
 			'Gonm' => 'masaram-gondi',
 			'Goth' => 'gotiska',
 			'Gran' => 'gammaltamilska',
 			'Grek' => 'grekiska',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhiska',
 			'Hanb' => 'han med bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunó’o',
 			'Hans' => 'förenklad',
 			'Hans@alt=stand-alone' => 'förenklade han-tecken',
 			'Hant' => 'traditionell',
 			'Hant@alt=stand-alone' => 'traditionella han-tecken',
 			'Hatr' => 'hatran',
 			'Hebr' => 'hebreiska',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hittitiska hieroglyfer',
 			'Hmng' => 'pahaw mong',
 			'Hmnp' => 'nyiakeng puachue hmong',
 			'Hrkt' => 'katakana/hiragana',
 			'Hung' => 'fornungerska',
 			'Inds' => 'indus',
 			'Ital' => 'fornitaliska',
 			'Jamo' => 'jamo',
 			'Java' => 'javanska',
 			'Jpan' => 'japanska',
 			'Jurc' => 'jurchenska',
 			'Kali' => 'kaya li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshti',
 			'Khmr' => 'khmeriska',
 			'Khoj' => 'khojkiska',
 			'Kits' => 'khitanska',
 			'Knda' => 'kanaresiska',
 			'Kore' => 'koreanska',
 			'Kpel' => 'kpellé',
 			'Kthi' => 'kaithiska',
 			'Lana' => 'lanna',
 			'Laoo' => 'laotiska',
 			'Latf' => 'frakturlatin',
 			'Latg' => 'gaeliskt latin',
 			'Latn' => 'latinska',
 			'Lepc' => 'rong',
 			'Limb' => 'limbu',
 			'Lina' => 'linjär A',
 			'Linb' => 'linjär B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'loma',
 			'Lyci' => 'lykiska',
 			'Lydi' => 'lydiska',
 			'Mahj' => 'mahajaniska',
 			'Maka' => 'makasariska',
 			'Mand' => 'mandaéiska',
 			'Mani' => 'manikeanska',
 			'Marc' => 'marchenska',
 			'Maya' => 'mayahieroglyfer',
 			'Medf' => 'medefaidrin',
 			'Mend' => 'mende',
 			'Merc' => 'kursiv-meroitiska',
 			'Mero' => 'meroitiska',
 			'Mlym' => 'malayalam',
 			'Modi' => 'modiska',
 			'Mong' => 'mongoliska',
 			'Moon' => 'moon',
 			'Mroo' => 'mru',
 			'Mtei' => 'meitei-mayek',
 			'Mult' => 'multaniska',
 			'Mymr' => 'burmesiska',
 			'Nand' => 'nandinagari',
 			'Narb' => 'fornnordarabiska',
 			'Nbat' => 'nabateiska',
 			'Newa' => 'newariska',
 			'Nkgb' => 'naxi geba',
 			'Nkoo' => 'n-kå',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol-chiki',
 			'Orkh' => 'orkon',
 			'Orya' => 'oriya',
 			'Osge' => 'osage',
 			'Osma' => 'osmanja',
 			'Palm' => 'palmyreniska',
 			'Pauc' => 'Pau Cin Hau-skrift',
 			'Perm' => 'fornpermiska',
 			'Phag' => 'phags-pa',
 			'Phli' => 'tidig pahlavi',
 			'Phlp' => 'psaltaren-pahlavi',
 			'Phlv' => 'bokpahlavi',
 			'Phnx' => 'feniciska',
 			'Plrd' => 'pollardtecken',
 			'Prti' => 'tidig parthianska',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifiska',
 			'Roro' => 'rongo-rongo',
 			'Runr' => 'runor',
 			'Samr' => 'samaritiska',
 			'Sara' => 'sarati',
 			'Sarb' => 'fornsydarabiska',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'teckningsskrift',
 			'Shaw' => 'shawiska',
 			'Shrd' => 'sharada',
 			'Sidd' => 'siddhamska',
 			'Sind' => 'sindhiska',
 			'Sinh' => 'singalesiska',
 			'Sogd' => 'sogdiska',
 			'Sogo' => 'gammalsogdiska',
 			'Sora' => 'sora sompeng',
 			'Soyo' => 'soyombo',
 			'Sund' => 'sundanesiska',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syriska',
 			'Syre' => 'estrangelosyriska',
 			'Syrj' => 'västsyriska',
 			'Syrn' => 'östsyriska',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takritiska',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue',
 			'Taml' => 'tamilska',
 			'Tang' => 'tangutiska',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinaghiska',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'taana',
 			'Thai' => 'thailändska',
 			'Tibt' => 'tibetanska',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaritiska',
 			'Vaii' => 'vaj',
 			'Visp' => 'synligt tal',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wancho',
 			'Wole' => 'woleai',
 			'Xpeo' => 'fornpersiska',
 			'Xsux' => 'sumero-akkadisk kilskrift',
 			'Yezi' => 'yazidiska',
 			'Yiii' => 'yi',
 			'Zanb' => 'zanabazar kvadratisk skrift',
 			'Zinh' => 'ärvda',
 			'Zmth' => 'matematisk notation',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symboler',
 			'Zxxx' => 'oskrivet språk',
 			'Zyyy' => 'gemensamma',
 			'Zzzz' => 'okänt skriftsystem',

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
			'001' => 'världen',
 			'002' => 'Afrika',
 			'003' => 'Nordamerika',
 			'005' => 'Sydamerika',
 			'009' => 'Oceanien',
 			'011' => 'Västafrika',
 			'013' => 'Centralamerika',
 			'014' => 'Östafrika',
 			'015' => 'Nordafrika',
 			'017' => 'Centralafrika',
 			'018' => 'södra Afrika',
 			'019' => 'Nord- och Sydamerika',
 			'021' => 'Norra Amerika',
 			'029' => 'Karibien',
 			'030' => 'Östasien',
 			'034' => 'Sydasien',
 			'035' => 'Sydostasien',
 			'039' => 'Sydeuropa',
 			'053' => 'Australasien',
 			'054' => 'Melanesien',
 			'057' => 'Mikronesiska öarna',
 			'061' => 'Polynesien',
 			'142' => 'Asien',
 			'143' => 'Centralasien',
 			'145' => 'Västasien',
 			'150' => 'Europa',
 			'151' => 'Östeuropa',
 			'154' => 'Nordeuropa',
 			'155' => 'Västeuropa',
 			'202' => 'Subsahariska Afrika',
 			'419' => 'Latinamerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Förenade Arabemiraten',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua och Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanien',
 			'AM' => 'Armenien',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerikanska Samoa',
 			'AT' => 'Österrike',
 			'AU' => 'Australien',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Azerbajdzjan',
 			'BA' => 'Bosnien och Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgien',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarien',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'S:t Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibiska Nederländerna',
 			'BR' => 'Brasilien',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetön',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosöarna',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Demokratiska republiken Kongo',
 			'CF' => 'Centralafrikanska republiken',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Republiken Kongo',
 			'CH' => 'Schweiz',
 			'CI' => 'Elfenbenskusten',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cooköarna',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Colombia',
 			'CP' => 'Clippertonön',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Julön',
 			'CY' => 'Cypern',
 			'CZ' => 'Tjeckien',
 			'DE' => 'Tyskland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikanska republiken',
 			'DZ' => 'Algeriet',
 			'EA' => 'Ceuta och Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egypten',
 			'EH' => 'Västsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanien',
 			'ET' => 'Etiopien',
 			'EU' => 'Europeiska unionen',
 			'EZ' => 'euroområdet',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsöarna',
 			'FM' => 'Mikronesien',
 			'FO' => 'Färöarna',
 			'FR' => 'Frankrike',
 			'GA' => 'Gabon',
 			'GB' => 'Storbritannien',
 			'GD' => 'Grenada',
 			'GE' => 'Georgien',
 			'GF' => 'Franska Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatorialguinea',
 			'GR' => 'Grekland',
 			'GS' => 'Sydgeorgien och Sydsandwichöarna',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong SAR',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardön och McDonaldöarna',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatien',
 			'HT' => 'Haiti',
 			'HU' => 'Ungern',
 			'IC' => 'Kanarieöarna',
 			'ID' => 'Indonesien',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'Indien',
 			'IO' => 'Brittiska territoriet i Indiska oceanen',
 			'IO@alt=chagos' => 'Chagosöarna',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italien',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordanien',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorerna',
 			'KN' => 'S:t Kitts och Nevis',
 			'KP' => 'Nordkorea',
 			'KR' => 'Sydkorea',
 			'KW' => 'Kuwait',
 			'KY' => 'Caymanöarna',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'S:t Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettland',
 			'LY' => 'Libyen',
 			'MA' => 'Marocko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavien',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallöarna',
 			'MK' => 'Nordmakedonien',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongoliet',
 			'MO' => 'Macao SAR',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nordmarianerna',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanien',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldiverna',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Moçambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nya Kaledonien',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkön',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederländerna',
 			'NO' => 'Norge',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nya Zeeland',
 			'NZ@alt=variant' => 'Aotearoa Nya Zeeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Franska Polynesien',
 			'PG' => 'Papua Nya Guinea',
 			'PH' => 'Filippinerna',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'S:t Pierre och Miquelon',
 			'PN' => 'Pitcairnöarna',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinska territorierna',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'yttre öar i Oceanien',
 			'RE' => 'Réunion',
 			'RO' => 'Rumänien',
 			'RS' => 'Serbien',
 			'RU' => 'Ryssland',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudiarabien',
 			'SB' => 'Salomonöarna',
 			'SC' => 'Seychellerna',
 			'SD' => 'Sudan',
 			'SE' => 'Sverige',
 			'SG' => 'Singapore',
 			'SH' => 'S:t Helena',
 			'SI' => 'Slovenien',
 			'SJ' => 'Svalbard och Jan Mayen',
 			'SK' => 'Slovakien',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sydsudan',
 			'ST' => 'São Tomé och Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syrien',
 			'SZ' => 'Eswatini',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- och Caicosöarna',
 			'TD' => 'Tchad',
 			'TF' => 'Franska sydterritorierna',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadzjikistan',
 			'TK' => 'Tokelauöarna',
 			'TL' => 'Östtimor',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisien',
 			'TO' => 'Tonga',
 			'TR' => 'Turkiet',
 			'TT' => 'Trinidad och Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'USA:s yttre öar',
 			'UN' => 'Förenta Nationerna',
 			'UN@alt=short' => 'FN',
 			'US' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikanstaten',
 			'VC' => 'S:t Vincent och Grenadinerna',
 			'VE' => 'Venezuela',
 			'VG' => 'Brittiska Jungfruöarna',
 			'VI' => 'Amerikanska Jungfruöarna',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis- och Futunaöarna',
 			'WS' => 'Samoa',
 			'XA' => 'fejkade accenter (för test)',
 			'XB' => 'fejkad bidi (för test)',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sydafrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'okänd region',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'traditionell tysk stavning',
 			'1994' => '1994 års resisk stavning',
 			'1996' => '1996 års reformerad tysk stavning',
 			'1606NICT' => '1606 års stavning',
 			'1694ACAD' => '1694 års stavning',
 			'1959ACAD' => '1959 års stavning',
 			'ABL1943' => '1943 års stavning',
 			'AKUAPEM' => 'akapuem (twi)',
 			'ALALC97' => '1997 års ALA-LC',
 			'ALUKU' => 'Aluku-dialekt',
 			'AO1990' => 'stavning enligt 1990 års överenskommelse',
 			'ARANES' => 'aranesiska (occitanska)',
 			'AREVELA' => 'östarmeniska',
 			'AREVMDA' => 'västarmeniska',
 			'ASANTE' => 'asante (twi)',
 			'AUVERN' => 'auvergniska (occitanska)',
 			'BAKU1926' => '1926 års stavning',
 			'BALANKA' => 'balanka-dialekt',
 			'BARLA' => 'barlavento-dialekt',
 			'BASICENG' => 'Ogdens basic english',
 			'BAUDDHA' => 'bauddha-dialekt',
 			'BISCAYAN' => 'Biscaya-dialekt',
 			'BISKE' => 'Bila-dialekt',
 			'BOHORIC' => 'Bohorič-alfabetet',
 			'BOONT' => 'boontling',
 			'BORNHOLM' => 'Bornholm',
 			'CISAUP' => 'cisalpinska (occitanska)',
 			'COLB1945' => 'stavning enligt 1945 års konvention mellan Portugal och Brasilien',
 			'CORNU' => 'kornisk engelska',
 			'CREISS' => 'croissant-occitanska',
 			'DAJNKO' => 'Dajnko-alfabetet',
 			'EKAVSK' => 'ekavisk dialekt',
 			'EMODENG' => 'tidig modern engelska',
 			'FONIPA' => 'internationell fonetisk notation - IPA',
 			'FONKIRSH' => 'Kirshenbaums fonetiska alfabet',
 			'FONNAPA' => 'nordamerikanskt fonetiskt alfabet',
 			'FONUPA' => 'uralisk fonetisk notation',
 			'FONXSAMP' => 'X-SAMPA fonetisk notation',
 			'GASCON' => 'Gascogne-occitanska',
 			'GRCLASS' => 'klassisk occitanska',
 			'GRITAL' => 'italiensk-inspirerad occitanska',
 			'GRMISTR' => 'Mistral-occitanska',
 			'HEPBURN' => 'Hepburn',
 			'HOGNORSK' => 'högnorsk dialekt',
 			'HSISTEMO' => 'h-system',
 			'IJEKAVSK' => 'ijekavisk dialekt',
 			'ITIHASA' => 'itihasa-dialekt',
 			'IVANCHOV' => 'bulgariska i 1899 års stavning',
 			'JAUER' => 'jauer-dialekt',
 			'JYUTPING' => 'jyutping',
 			'KKCOR' => 'vanlig stavning',
 			'KOCIEWIE' => 'kociewiska',
 			'KSCOR' => 'standardstavning',
 			'LAUKIKA' => 'laukika-dialekt',
 			'LEMOSIN' => 'Limousin-occitanska',
 			'LENGADOC' => 'languedociska',
 			'LIPAW' => 'Lipovaz-dialekt',
 			'LUNA1918' => '1918 års stavning',
 			'METELKO' => 'Metelko-alfabetet',
 			'MONOTON' => 'monotonisk stavning',
 			'NDYUKA' => 'Ndyuka-dialekt',
 			'NEDIS' => 'natisonsk dialekt',
 			'NEWFOUND' => 'Newfoundland-engelska',
 			'NICARD' => 'Nice-occitanska',
 			'NJIVA' => 'Njiva-dialekt',
 			'NULIK' => 'nulik-stavning',
 			'OSOJS' => 'Osojane-dialekt',
 			'OXENDICT' => 'Oxford-stavning',
 			'PAHAWH2' => 'pahawh hmong andra steget reducerad stavning',
 			'PAHAWH3' => 'pahawh hmong tredje steget reducerad stavning',
 			'PAHAWH4' => 'pahawh hmong sista steget reducerad stavning',
 			'PAMAKA' => 'Pamaka-dialekt',
 			'PETR1708' => '1708 års stavning',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonisk stavning',
 			'POSIX' => 'Posix',
 			'PROVENC' => 'provensalska',
 			'PUTER' => 'puter-dialekt',
 			'REVISED' => 'reformerad stavning',
 			'RIGIK' => 'klassisk volapük',
 			'ROZAJ' => 'resisk dialekt',
 			'RUMGR' => 'grischun-dialekt',
 			'SAAHO' => 'saho-dialekt',
 			'SCOTLAND' => 'skotsk engelska',
 			'SCOUSE' => 'scouse',
 			'SIMPLE' => 'lätt',
 			'SOLBA' => 'Solbica-dialekt',
 			'SOTAV' => 'sotavento-dialekt',
 			'SPANGLIS' => 'spangelska',
 			'SURMIRAN' => 'surmiran-dialekt',
 			'SURSILV' => 'sursilvan-dialekt',
 			'SUTSILV' => 'sutsilvan-dialekt',
 			'TARASK' => 'Taraskievika-stavning',
 			'UCCOR' => 'unifierad stavning',
 			'UCRCOR' => 'reviderad unifierad stavning',
 			'ULSTER' => 'Ulster-dialekt',
 			'UNIFON' => 'unifon-skrift',
 			'VAIDIKA' => 'vedisk dialekt',
 			'VALENCIA' => 'valensisk dialekt',
 			'VALLADER' => 'vallader-dialekt',
 			'VIVARAUP' => 'vivaroalpinska (occitanska)',
 			'WADEGILE' => 'Wade-Giles',
 			'XSISTEMO' => 'x-system',

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
 			'colalternate' => 'Ignorera symboler vid sortering',
 			'colbackwards' => 'Sortera accenter omvänt',
 			'colcasefirst' => 'Ordna efter versaler/gemener',
 			'colcaselevel' => 'Skiftlägeskänslig sortering',
 			'collation' => 'sorteringsordning',
 			'colnormalization' => 'Normaliserad sortering',
 			'colnumeric' => 'Numerisk sortering',
 			'colstrength' => 'Sorteringsstyrka',
 			'currency' => 'valuta',
 			'hc' => '12- eller 24-timmarsklocka',
 			'lb' => 'radbrytningstyp',
 			'ms' => 'enhetssystem',
 			'numbers' => 'siffror',
 			'timezone' => 'Tidszon',
 			'va' => 'Språkvariant',
 			'x' => 'privat',

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
 				'buddhist' => q{buddistisk kalender},
 				'chinese' => q{kinesisk kalender},
 				'coptic' => q{koptisk kalender},
 				'dangi' => q{koreansk kalender},
 				'ethiopic' => q{etiopisk kalender},
 				'ethiopic-amete-alem' => q{etiopisk amete-alem-kalender},
 				'gregorian' => q{gregoriansk kalender},
 				'hebrew' => q{hebreisk kalender},
 				'indian' => q{indisk kalender},
 				'islamic' => q{islamisk kalender},
 				'islamic-civil' => q{islamisk civil kalender},
 				'islamic-rgsa' => q{islamisk kalender, Saudi-Arabien},
 				'islamic-tbla' => q{islamisk kalender, astronomisk},
 				'islamic-umalqura' => q{islamisk kalender, Umm al-Qura},
 				'iso8601' => q{ISO 8601-kalender},
 				'japanese' => q{japansk kalender},
 				'persian' => q{persisk kalender},
 				'roc' => q{kinesiska republikens kalender},
 			},
 			'cf' => {
 				'account' => q{redovisningsformat},
 				'standard' => q{normalt format},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{sortera symboler},
 				'shifted' => q{Sortera oavsett symboler},
 			},
 			'colbackwards' => {
 				'no' => q{sortera accenter normalt},
 				'yes' => q{sortera accenter omvänt},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sortera gemener först},
 				'no' => q{Ordna normalt efter skiftläge},
 				'upper' => q{Sortera versaler först},
 			},
 			'colcaselevel' => {
 				'no' => q{Sortera oavsett skiftläge},
 				'yes' => q{Sortera efter skiftläge},
 			},
 			'collation' => {
 				'big5han' => q{big5-sorteringsordning},
 				'compat' => q{bakåtkompatibel sorteringsordning},
 				'dictionary' => q{ordbokssorteringsordning},
 				'ducet' => q{grundläggande Unicode-sorteringsordning},
 				'emoji' => q{emojisorteringsordning},
 				'eor' => q{sorteringsordning för flerspråkliga europeiska dokument},
 				'gb2312han' => q{gb2312-sorteringsordning},
 				'phonebook' => q{telefonkatalogssorteringsordning},
 				'phonetic' => q{fonetisk sorteringsordning},
 				'pinyin' => q{pinyin-sorteringsordning},
 				'reformed' => q{reformerad sorteringsordning},
 				'search' => q{allmän sökning},
 				'searchjl' => q{söksorteringsordning för att söka på inledande Hangul-konsonant},
 				'standard' => q{normal sorteringsordning},
 				'stroke' => q{strecksorteringsordning},
 				'traditional' => q{traditionell sorteringsordning},
 				'unihan' => q{radikal-streck-sorteringsordning},
 				'zhuyin' => q{zhuyin-sorteringsordning},
 			},
 			'colnormalization' => {
 				'no' => q{sortera utan normalisering},
 				'yes' => q{sortera med Unicode-normalisering},
 			},
 			'colnumeric' => {
 				'no' => q{Sortera siffror för sig},
 				'yes' => q{Sortera siffror numeriskt},
 			},
 			'colstrength' => {
 				'identical' => q{Sortera alla},
 				'primary' => q{Sortera endast efter grundbokstäver},
 				'quaternary' => q{Sortera efter accent/skiftläge/bredd/kana},
 				'secondary' => q{Sortera accenter},
 				'tertiary' => q{Sortera accenter/skiftläge/bredd},
 			},
 			'd0' => {
 				'fwidth' => q{till helbreda},
 				'hwidth' => q{till halvbreda},
 				'npinyin' => q{Numerisk},
 			},
 			'hc' => {
 				'h11' => q{12-timmarsklocka (0–11)},
 				'h12' => q{12-timmarsklocka (1–12)},
 				'h23' => q{24-timmarsklocka (0–23)},
 				'h24' => q{24-timmarsklocka (1–24)},
 			},
 			'lb' => {
 				'loose' => q{fri radbrytning},
 				'normal' => q{normal radbrytning},
 				'strict' => q{strikt radbrytning},
 			},
 			'm0' => {
 				'bgn' => q{enligt USA:s geografiska namnkommitté},
 				'ungegn' => q{enligt FN:s geografiska namnkommitté},
 			},
 			'ms' => {
 				'metric' => q{metersystem},
 				'uksystem' => q{brittiskt måttsystem},
 				'ussystem' => q{USA:s måttsystem},
 			},
 			'numbers' => {
 				'ahom' => q{ahom-siffror},
 				'arab' => q{indo-arabiska siffror},
 				'arabext' => q{utökade indo-arabiska siffror},
 				'armn' => q{armeniska taltecken},
 				'armnlow' => q{gemena armeniska taltecken},
 				'bali' => q{balinesiska siffror},
 				'beng' => q{bengaliska siffror},
 				'brah' => q{brahmiska siffror},
 				'cakm' => q{chakma-siffror},
 				'cham' => q{chamiska siffror},
 				'cyrl' => q{kyrilliska taltecken},
 				'deva' => q{devanagariska siffror},
 				'diak' => q{dives akuru-siffror},
 				'ethi' => q{etiopiska taltecken},
 				'finance' => q{finansiella siffror},
 				'fullwide' => q{fullbreddssiffror},
 				'geor' => q{georgiska taltecken},
 				'gong' => q{gunjalagondiska siffror},
 				'gonm' => q{masaramgondiska siffror},
 				'grek' => q{grekiska taltecken},
 				'greklow' => q{små grekiska taltecken},
 				'gujr' => q{gujaratiska siffror},
 				'guru' => q{gurmukhiska siffror},
 				'hanidec' => q{kinesiska decimaltal},
 				'hans' => q{förenklat kinesiskt stavade tal},
 				'hansfin' => q{förenklat kinesiskt finansiellt stavade tal},
 				'hant' => q{traditionellt kinesiskt stavade tal},
 				'hantfin' => q{traditionellt kinesiskt finansiellt stavade tal},
 				'hebr' => q{hebreiska taltecken},
 				'hmng' => q{pahawh hmong-siffror},
 				'hmnp' => q{nyiakeng puachue hmong-siffror},
 				'java' => q{javanesiska siffror},
 				'jpan' => q{japanskt stavade tal},
 				'jpanfin' => q{japanskt finansiellt stavade tal},
 				'kali' => q{kayah li-siffror},
 				'khmr' => q{khmeriska siffror},
 				'knda' => q{kannadiska siffror},
 				'lana' => q{tai tham hora-siffror},
 				'lanatham' => q{tai tham tham-siffror},
 				'laoo' => q{laotiska siffror},
 				'latn' => q{västerländska siffror},
 				'lepc' => q{lepcha-siffror},
 				'limb' => q{limbu-siffror},
 				'mathbold' => q{matematiska siffror i fetstil},
 				'mathdbl' => q{matematiska siffror med dubbelstreck},
 				'mathmono' => q{matematiska siffror med fast teckenbredd},
 				'mathsanb' => q{matematiska siffror i sans-serif fetstil},
 				'mathsans' => q{matematiska siffror i sans-serif},
 				'mlym' => q{malayalamiska siffror},
 				'modi' => q{modi-siffror},
 				'mong' => q{mongoliska siffror},
 				'mroo' => q{mro-siffror},
 				'mtei' => q{meetei mayek-siffror},
 				'mymr' => q{burmesiska siffror},
 				'mymrshan' => q{burmesiska shan-siffror},
 				'mymrtlng' => q{burmesiska tai laing-siffror},
 				'native' => q{språkspecifika siffror},
 				'nkoo' => q{n’ko-siffror},
 				'olck' => q{ol chiki-siffror},
 				'orya' => q{oriyiska siffror},
 				'osma' => q{osmanya-siffror},
 				'rohg' => q{hanifisiffror},
 				'roman' => q{romerska taltecken},
 				'romanlow' => q{små romerska taltecken},
 				'saur' => q{saurashtra-siffror},
 				'shrd' => q{sharada-siffror},
 				'sind' => q{khudawidiska siffror},
 				'sinh' => q{sinhala lith-siffror},
 				'sora' => q{sora sompeng-siffror},
 				'sund' => q{sundanesiska siffror},
 				'takr' => q{takri-siffror},
 				'talu' => q{ny tai lü-siffror},
 				'taml' => q{traditionella tamilska taltecken},
 				'tamldec' => q{tamilska siffror},
 				'telu' => q{telugiska siffror},
 				'thai' => q{thailändska siffror},
 				'tibt' => q{tibetanska siffror},
 				'tirh' => q{tirhuta-siffror},
 				'traditional' => q{Traditionella siffror},
 				'vaii' => q{vai-siffror},
 				'wara' => q{varang kshiti-siffror},
 				'wcho' => q{wanchosiffror},
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
			'metric' => q{SI-enheter},
 			'UK' => q{engelska enheter},
 			'US' => q{USA-enheter},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'språk: {0}',
 			'script' => 'skrift: {0}',
 			'region' => 'region: {0}',

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
			auxiliary => qr{[áâãā ç èë íîïī ñ ó ú ÿü æ ø]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Å', 'Ä', 'Ö'],
			main => qr{[aà b c d eé f g h i j k l m n o p q r s t u v w x y z å ä ö]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Å', 'Ä', 'Ö'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
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
						'name' => q(kompassriktning),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kompassriktning),
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
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
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
						'one' => q({0} g-kraft),
						'other' => q({0} g-kraft),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(common),
						'one' => q({0} g-kraft),
						'other' => q({0} g-kraft),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(common),
						'name' => q(meter per kvadratsekund),
						'one' => q({0} meter per kvadratsekund),
						'other' => q({0} meter per kvadratsekund),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(common),
						'name' => q(meter per kvadratsekund),
						'one' => q({0} meter per kvadratsekund),
						'other' => q({0} meter per kvadratsekund),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(common),
						'one' => q({0} bågminut),
						'other' => q({0} bågminuter),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(common),
						'one' => q({0} bågminut),
						'other' => q({0} bågminuter),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(common),
						'one' => q({0} bågsekund),
						'other' => q({0} bågsekunder),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(common),
						'one' => q({0} bågsekund),
						'other' => q({0} bågsekunder),
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
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(common),
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(neuter),
						'one' => q({0} varv),
						'other' => q({0} varv),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(neuter),
						'one' => q({0} varv),
						'other' => q({0} varv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(neuter),
						'name' => q(engelska tunnland),
						'one' => q({0} engelskt tunnland),
						'other' => q({0} engelska tunnland),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(neuter),
						'name' => q(engelska tunnland),
						'one' => q({0} engelskt tunnland),
						'other' => q({0} engelska tunnland),
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
						'per' => q({0} per kvadratcentimeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(common),
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
						'per' => q({0} per kvadratcentimeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(common),
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(common),
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrattum),
						'one' => q({0} kvadrattum),
						'other' => q({0} kvadrattum),
						'per' => q({0} per kvadrattum),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrattum),
						'one' => q({0} kvadrattum),
						'other' => q({0} kvadrattum),
						'per' => q({0} per kvadrattum),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(common),
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} per kvadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(common),
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} per kvadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(common),
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
						'per' => q({0} per kvadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(common),
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
						'per' => q({0} per kvadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(common),
						'one' => q({0} kvadratmile),
						'other' => q({0} kvadratmile),
						'per' => q({0} per kvadratmile),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(common),
						'one' => q({0} kvadratmile),
						'other' => q({0} kvadratmile),
						'per' => q({0} per kvadratmile),
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
						'one' => q({0} objekt),
						'other' => q({0} objekt),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(neuter),
						'one' => q({0} objekt),
						'other' => q({0} objekt),
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
						'name' => q(milligram per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligram per deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligram per deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(common),
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(common),
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
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
						'one' => q({0} miljondel),
						'other' => q({0} miljondelar),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(common),
						'one' => q({0} miljondel),
						'other' => q({0} miljondelar),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(common),
						'name' => q(promyriad),
						'one' => q({0} promyriad),
						'other' => q({0} promyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(common),
						'name' => q(promyriad),
						'one' => q({0} promyriad),
						'other' => q({0} promyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(common),
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(common),
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(common),
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(common),
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(common),
						'one' => q({0} UK mil/gn),
						'other' => q({0} UK mil/gn),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(common),
						'one' => q({0} UK mil/gn),
						'other' => q({0} UK mil/gn),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} öst),
						'north' => q({0} nord),
						'south' => q({0} syd),
						'west' => q({0} väst),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} öst),
						'north' => q({0} nord),
						'south' => q({0} syd),
						'west' => q({0} väst),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(common),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(common),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(common),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(common),
						'one' => q({0} byte),
						'other' => q({0} byte),
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
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(common),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
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
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(common),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
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
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(common),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(common),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(common),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
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
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(common),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'name' => q(århundraden),
						'one' => q({0} århundrade),
						'other' => q({0} århundraden),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'name' => q(århundraden),
						'one' => q({0} århundrade),
						'other' => q({0} århundraden),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(neuter),
						'one' => q({0} dygn),
						'other' => q({0} dygn),
						'per' => q({0} per dygn),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(neuter),
						'one' => q({0} dygn),
						'other' => q({0} dygn),
						'per' => q({0} per dygn),
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
						'name' => q(årtionden),
						'one' => q({0} årtionde),
						'other' => q({0} årtionden),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'name' => q(årtionden),
						'one' => q({0} årtionde),
						'other' => q({0} årtionden),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(common),
						'name' => q(timmar),
						'one' => q({0} timme),
						'other' => q({0} timmar),
						'per' => q({0} per timme),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(common),
						'name' => q(timmar),
						'one' => q({0} timme),
						'other' => q({0} timmar),
						'per' => q({0} per timme),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(common),
						'name' => q(mikrosekunder),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekunder),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(common),
						'name' => q(mikrosekunder),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekunder),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(common),
						'name' => q(millisekunder),
						'one' => q({0} millisekund),
						'other' => q({0} millisekunder),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(common),
						'name' => q(millisekunder),
						'one' => q({0} millisekund),
						'other' => q({0} millisekunder),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(common),
						'name' => q(minuter),
						'one' => q({0} minut),
						'other' => q({0} minuter),
						'per' => q({0} per minut),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(common),
						'name' => q(minuter),
						'one' => q({0} minut),
						'other' => q({0} minuter),
						'per' => q({0} per minut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(common),
						'name' => q(månader),
						'one' => q({0} månad),
						'other' => q({0} månader),
						'per' => q({0} per månad),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(common),
						'name' => q(månader),
						'one' => q({0} månad),
						'other' => q({0} månader),
						'per' => q({0} per månad),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(common),
						'name' => q(nanosekunder),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekunder),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(common),
						'name' => q(nanosekunder),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekunder),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(common),
						'name' => q(kvartar),
						'one' => q({0} kvart),
						'other' => q({0} kvartar),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(common),
						'name' => q(kvartar),
						'one' => q({0} kvart),
						'other' => q({0} kvartar),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(common),
						'name' => q(sekunder),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} per sekund),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(common),
						'name' => q(sekunder),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} per sekund),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(common),
						'name' => q(veckor),
						'one' => q({0} vecka),
						'other' => q({0} veckor),
						'per' => q({0} per vecka),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(common),
						'name' => q(veckor),
						'one' => q({0} vecka),
						'other' => q({0} veckor),
						'per' => q({0} per vecka),
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
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(common),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(common),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(common),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal units),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal units),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(common),
						'name' => q(kalorier),
						'one' => q({0} kalori),
						'other' => q({0} kalorier),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(common),
						'name' => q(kalorier),
						'one' => q({0} kalori),
						'other' => q({0} kalorier),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(common),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(common),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(common),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(common),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(common),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(common),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
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
						'name' => q(kilowattimmar),
						'one' => q({0} kilowattimme),
						'other' => q({0} kilowattimmar),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(common),
						'name' => q(kilowattimmar),
						'one' => q({0} kilowattimme),
						'other' => q({0} kilowattimmar),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(common),
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
					'force-pound-force' => {
						'name' => q(pounds of force),
						'one' => q({0} pound of force),
						'other' => q({0} pounds of force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pounds of force),
						'one' => q({0} pound of force),
						'other' => q({0} pounds of force),
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
						'one' => q({0} punkt),
						'other' => q({0} punkter),
					},
					# Core Unit Identifier
					'dot' => {
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
						'name' => q(punkter per tum),
						'one' => q({0} punkt per tum),
						'other' => q({0} punkter per tum),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punkter per tum),
						'one' => q({0} punkt per tum),
						'other' => q({0} punkter per tum),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(common),
						'name' => q(typografisk fyrkant),
						'one' => q({0} fyrkant),
						'other' => q({0} fyrkanter),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(common),
						'name' => q(typografisk fyrkant),
						'one' => q({0} fyrkant),
						'other' => q({0} fyrkanter),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(common),
						'name' => q(megapixlar),
						'one' => q({0} megapixel),
						'other' => q({0} megapixlar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(common),
						'name' => q(megapixlar),
						'one' => q({0} megapixel),
						'other' => q({0} megapixlar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(common),
						'name' => q(pixlar),
						'one' => q({0} pixel),
						'other' => q({0} pixlar),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(common),
						'name' => q(pixlar),
						'one' => q({0} pixel),
						'other' => q({0} pixlar),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(common),
						'name' => q(pixlar per centimeter),
						'one' => q({0} pixel per centimeter),
						'other' => q({0} pixlar per centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(common),
						'name' => q(pixlar per centimeter),
						'one' => q({0} pixel per centimeter),
						'other' => q({0} pixlar per centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixel per tum),
						'one' => q({0} pixel per tum),
						'other' => q({0} pixel per tum),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixel per tum),
						'one' => q({0} pixel per tum),
						'other' => q({0} pixel per tum),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiska enheter),
						'one' => q({0} astronomisk enhet),
						'other' => q({0} astronomiska enheter),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiska enheter),
						'one' => q({0} astronomisk enhet),
						'other' => q({0} astronomiska enheter),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(common),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(common),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
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
						'name' => q(jordradie),
						'one' => q({0} jordradie),
						'other' => q({0} jordradie),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(jordradie),
						'one' => q({0} jordradie),
						'other' => q({0} jordradie),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(common),
						'per' => q({0} per fot),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(common),
						'per' => q({0} per fot),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(engelska plogfårelängder),
						'one' => q({0} engelsk plogfårelängd),
						'other' => q({0} engelska plogfårelängder),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(engelska plogfårelängder),
						'one' => q({0} engelsk plogfårelängd),
						'other' => q({0} engelska plogfårelängder),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(common),
						'per' => q({0} per tum),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(common),
						'per' => q({0} per tum),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(common),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(common),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(common),
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(common),
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
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
						'other' => q({0} mile),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(common),
						'one' => q({0} mile),
						'other' => q({0} mile),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(common),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(common),
						'one' => q({0} mil),
						'other' => q({0} mil),
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
						'name' => q(nautiska mil),
						'one' => q({0} nautisk mil),
						'other' => q({0} nautiska mil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nautiska mil),
						'one' => q({0} nautisk mil),
						'other' => q({0} nautiska mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(common),
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
					'length-solar-radius' => {
						'1' => q(common),
						'name' => q(solradier),
						'one' => q({0} solradie),
						'other' => q({0} solradier),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(common),
						'name' => q(solradier),
						'one' => q({0} solradie),
						'other' => q({0} solradier),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(common),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(common),
						'one' => q({0} yard),
						'other' => q({0} yard),
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
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(common),
						'name' => q(solluminositeter),
						'one' => q({0} solluminositet),
						'other' => q({0} solluminositeter),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(common),
						'name' => q(solluminositeter),
						'one' => q({0} solluminositet),
						'other' => q({0} solluminositeter),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(common),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(common),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(common),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(common),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(common),
						'name' => q(jordmassor),
						'one' => q({0} jordmassa),
						'other' => q({0} jordmassor),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(common),
						'name' => q(jordmassor),
						'one' => q({0} jordmassa),
						'other' => q({0} jordmassor),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(neuter),
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(neuter),
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(neuter),
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'name' => q(gram),
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
						'1' => q(neuter),
						'per' => q({0} per uns),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(neuter),
						'per' => q({0} per uns),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy uns),
						'one' => q({0} troy uns),
						'other' => q({0} troy uns),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy uns),
						'one' => q({0} troy uns),
						'other' => q({0} troy uns),
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
						'1' => q(common),
						'name' => q(solmassor),
						'one' => q({0} solmassa),
						'other' => q({0} solmassor),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(common),
						'name' => q(solmassor),
						'one' => q({0} solmassa),
						'other' => q({0} solmassor),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(engelska stenar),
						'one' => q({0} engelsk sten),
						'other' => q({0} engelska stenar),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(engelska stenar),
						'one' => q({0} engelsk sten),
						'other' => q({0} engelska stenar),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(engelska korta ton),
						'one' => q({0} engelskt kort ton),
						'other' => q({0} engelska korta ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(engelska korta ton),
						'one' => q({0} engelskt kort ton),
						'other' => q({0} engelska korta ton),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(neuter),
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(neuter),
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
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
						'one' => q({0} hästkraft),
						'other' => q({0} hästkrafter),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hästkraft),
						'other' => q({0} hästkrafter),
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
						'name' => q(atmosfärer),
						'one' => q({0} atmosfär),
						'other' => q({0} atmosfärer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(common),
						'name' => q(atmosfärer),
						'one' => q({0} atmosfär),
						'other' => q({0} atmosfärer),
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
						'name' => q(tum kvicksilver),
						'one' => q({0} tum kvicksilver),
						'other' => q({0} tum kvicksilver),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tum kvicksilver),
						'one' => q({0} tum kvicksilver),
						'other' => q({0} tum kvicksilver),
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
						'name' => q(millimeter kvicksilver),
						'one' => q({0} millimeter kvicksilver),
						'other' => q({0} millimeter kvicksilver),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimeter kvicksilver),
						'one' => q({0} millimeter kvicksilver),
						'other' => q({0} millimeter kvicksilver),
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
						'name' => q(pund per kvadrattum),
						'one' => q({0} pund per kvadrattum),
						'other' => q({0} pund per kvadrattum),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pund per kvadrattum),
						'one' => q({0} pund per kvadrattum),
						'other' => q({0} pund per kvadrattum),
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
						'1' => q(common),
						'name' => q(kilometer per timme),
						'one' => q({0} kilometer per timme),
						'other' => q({0} kilometer per timme),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(common),
						'name' => q(kilometer per timme),
						'one' => q({0} kilometer per timme),
						'other' => q({0} kilometer per timme),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(common),
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(common),
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(common),
						'name' => q(mile per timme),
						'one' => q({0} mile per timme),
						'other' => q({0} mile per timme),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(common),
						'name' => q(mile per timme),
						'one' => q({0} mile per timme),
						'other' => q({0} mile per timme),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(common),
						'name' => q(grader Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} grader Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(common),
						'name' => q(grader Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} grader Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(common),
						'name' => q(grader Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} grader Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(common),
						'name' => q(grader Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} grader Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(common),
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(common),
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
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
					'times' => {
						'1' => q({0}–{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}–{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(common),
						'name' => q(newton-meter),
						'one' => q({0} newton-meter),
						'other' => q({0} newton-meter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(common),
						'name' => q(newton-meter),
						'one' => q({0} newton-meter),
						'other' => q({0} newton-meter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-feet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-feet),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(engelska tunnland gånger fot),
						'one' => q({0} engelskt tunnland gånger fot),
						'other' => q({0} engelska tunnland gånger fot),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(engelska tunnland gånger fot),
						'one' => q({0} engelskt tunnland gånger fot),
						'other' => q({0} engelska tunnland gånger fot),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skäppor),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skäppor),
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
						'per' => q({0} per kubikcentimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(common),
						'name' => q(kubikcentimeter),
						'one' => q({0} kubikcentimeter),
						'other' => q({0} kubikcentimeter),
						'per' => q({0} per kubikcentimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(common),
						'name' => q(kubikfot),
						'one' => q({0} kubikfot),
						'other' => q({0} kubikfot),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(common),
						'name' => q(kubikfot),
						'one' => q({0} kubikfot),
						'other' => q({0} kubikfot),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubiktum),
						'one' => q({0} kubiktum),
						'other' => q({0} kubiktum),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubiktum),
						'one' => q({0} kubiktum),
						'other' => q({0} kubiktum),
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
						'per' => q({0} per kubikmeter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(common),
						'name' => q(kubikmeter),
						'one' => q({0} kubikmeter),
						'other' => q({0} kubikmeter),
						'per' => q({0} per kubikmeter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(common),
						'name' => q(kubikmile),
						'one' => q({0} kubikmile),
						'other' => q({0} kubikmile),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(common),
						'name' => q(kubikmile),
						'one' => q({0} kubikmile),
						'other' => q({0} kubikmile),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubikyard),
						'one' => q({0} kubikyard),
						'other' => q({0} kubikyard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubikyard),
						'one' => q({0} kubikyard),
						'other' => q({0} kubikyard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(common),
						'name' => q(metriska koppar),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriska koppar),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(common),
						'name' => q(metriska koppar),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriska koppar),
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
						'name' => q(dessertskedar),
						'one' => q({0} dessertsked),
						'other' => q({0} dessertskedar),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(common),
						'name' => q(dessertskedar),
						'one' => q({0} dessertsked),
						'other' => q({0} dessertskedar),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(common),
						'name' => q(brittiska dessertskedar),
						'one' => q({0} brittiska dessertskedar),
						'other' => q({0} brittiska dessertskedar),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(common),
						'name' => q(brittiska dessertskedar),
						'one' => q({0} brittiska dessertskedar),
						'other' => q({0} brittiska dessertskedar),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(common),
						'name' => q(brittisk dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(common),
						'name' => q(brittisk dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(common),
						'one' => q({0} droppe),
						'other' => q({0} droppar),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(common),
						'one' => q({0} droppe),
						'other' => q({0} droppar),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(neuter),
						'name' => q(flytande uns),
						'one' => q({0} flytande uns),
						'other' => q({0} fluid ounces),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(neuter),
						'name' => q(flytande uns),
						'one' => q({0} flytande uns),
						'other' => q({0} fluid ounces),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(neuter),
						'name' => q(Br. flytande uns),
						'one' => q({0} br. fl oz),
						'other' => q({0} br. flytande uns),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(neuter),
						'name' => q(Br. flytande uns),
						'one' => q({0} br. fl oz),
						'other' => q({0} br. flytande uns),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(common),
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(common),
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(neuter),
						'name' => q(Br. gallon),
						'one' => q({0} br. gallon),
						'other' => q({0} br. gallon),
						'per' => q({0} per br. gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(neuter),
						'name' => q(Br. gallon),
						'one' => q({0} br. gallon),
						'other' => q({0} br. gallon),
						'per' => q({0} per br. gallon),
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
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(common),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(common),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
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
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(common),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(common),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(common),
						'name' => q(metriska pint),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriska pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(common),
						'name' => q(metriska pint),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriska pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(common),
						'name' => q(br. quart),
						'one' => q({0} brittisk quart),
						'other' => q({0} brittiska quarts),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(common),
						'name' => q(br. quart),
						'one' => q({0} brittisk quart),
						'other' => q({0} brittiska quarts),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(common),
						'name' => q(matskedar),
						'one' => q({0} matsked),
						'other' => q({0} matskedar),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(common),
						'name' => q(matskedar),
						'one' => q({0} matsked),
						'other' => q({0} matskedar),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(common),
						'name' => q(teskedar),
						'one' => q({0} tesked),
						'other' => q({0} teskedar),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(common),
						'name' => q(teskedar),
						'one' => q({0} tesked),
						'other' => q({0} teskedar),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(riktning),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(riktning),
					},
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
					'angle-arc-minute' => {
						'name' => q(bågmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bågmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bågsek),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bågsek),
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
						'one' => q({0}varv),
						'other' => q({0}varv),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}varv),
						'other' => q({0}varv),
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
					'area-dunam' => {
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0}dunam),
						'other' => q({0}dunam),
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
						'one' => q({0}tum²),
						'other' => q({0}tum²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}tum²),
						'other' => q({0}tum²),
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
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}K),
						'other' => q({0}K),
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
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
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
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0}l/100 km),
						'other' => q({0}l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0}l/100 km),
						'other' => q({0}l/100 km),
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
						'one' => q({0}mpg UK),
						'other' => q({0}mpg UK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mpg UK),
						'other' => q({0}mpg UK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Ö),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Ö),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}b),
						'other' => q({0}b),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}b),
						'other' => q({0}b),
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
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
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
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
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
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
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
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
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
					'duration-century' => {
						'one' => q({0}årh),
						'other' => q({0}årh),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}årh),
						'other' => q({0}årh),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0}årt),
						'other' => q({0}årt),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0}årt),
						'other' => q({0}årt),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
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
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
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
					'duration-quarter' => {
						'one' => q({0}k),
						'other' => q({0}k),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0}k),
						'other' => q({0}k),
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
						'name' => q(v),
						'one' => q({0}v),
						'other' => q({0}v),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(v),
						'one' => q({0}v),
						'other' => q({0}v),
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
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
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
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
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
						'one' => q({0} am. therm),
						'other' => q({0} am. therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0} am. therm),
						'other' => q({0} am. therm),
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
						'name' => q(pkt),
						'one' => q({0}pkt),
						'other' => q({0}pkt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pkt),
						'one' => q({0}pkt),
						'other' => q({0}pkt),
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
					'graphics-megapixel' => {
						'one' => q({0}mpx),
						'other' => q({0}mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0}mpx),
						'other' => q({0}mpx),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}AE),
						'other' => q({0}AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}AE),
						'other' => q({0}AE),
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
						'one' => q({0}famn),
						'other' => q({0}famnar),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}famn),
						'other' => q({0}famnar),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}fot),
						'other' => q({0}fot),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}fot),
						'other' => q({0}fot),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}en.pfrld),
						'other' => q({0}en.pfrld),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}en.pfrld),
						'other' => q({0}en.pfrld),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} tum),
						'other' => q({0}"),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} tum),
						'other' => q({0}"),
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
						'one' => q({0}ljusår),
						'other' => q({0}ljusår),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}ljusår),
						'other' => q({0}ljusår),
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
						'one' => q({0}naut. mil),
						'other' => q({0}naut. mil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}naut. mil),
						'other' => q({0}naut. mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'one' => q({0}parsek),
						'other' => q({0}parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0}parsek),
						'other' => q({0}parsek),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pkt),
						'one' => q({0}pkt),
						'other' => q({0}pkt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pkt),
						'one' => q({0}pkt),
						'other' => q({0}pkt),
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
						'one' => q({0} yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
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
						'one' => q({0}lux),
						'other' => q({0}lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0}lux),
						'other' => q({0}lux),
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
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
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
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
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
						'one' => q({0}uns),
						'other' => q({0}uns),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}uns),
						'other' => q({0}uns),
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
						'one' => q({0} eng. s:n),
						'other' => q({0} eng. s:n),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} eng. s:n),
						'other' => q({0} eng. s:n),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} en.k.ton),
						'other' => q({0} en.k.ton),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} en.k.ton),
						'other' => q({0} en.k.ton),
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
						'name' => q(hk),
						'one' => q({0}hk),
						'other' => q({0}hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hk),
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
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
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
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
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
						'one' => q({0}knop),
						'other' => q({0}knop),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}knop),
						'other' => q({0}knop),
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
						'name' => q(mile/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mile/h),
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
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}en.td·fot),
						'other' => q({0}en.td·fot),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}en.td·fot),
						'other' => q({0}en.td·fot),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0}fat),
						'other' => q({0}fat),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0}fat),
						'other' => q({0}fat),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0}skäppa),
						'other' => q({0}skäppor),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0}skäppa),
						'other' => q({0}skäppor),
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
						'one' => q({0}fot³),
						'other' => q({0}fot³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0}fot³),
						'other' => q({0}fot³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0}tum³),
						'other' => q({0}tum³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}tum³),
						'other' => q({0}tum³),
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
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}kopp),
						'other' => q({0}koppar),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}kopp),
						'other' => q({0}koppar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}mcup),
						'other' => q({0}mcup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}mcup),
						'other' => q({0}mcup),
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
						'name' => q(dsk),
						'one' => q({0}dsk),
						'other' => q({0}dsk),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsk),
						'one' => q({0}dsk),
						'other' => q({0}dsk),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}br.dsk),
						'other' => q({0}br.dsk),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}br.dsk),
						'other' => q({0}br.dsk),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl. dram),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl. dram),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(drp),
						'one' => q({0}drp),
						'other' => q({0}drp),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(drp),
						'one' => q({0}drp),
						'other' => q({0}drp),
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
						'name' => q(Br. fl oz),
						'one' => q({0}br. fl oz),
						'other' => q({0}br. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Br. fl oz),
						'one' => q({0}br. fl oz),
						'other' => q({0}br. fl oz),
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
						'one' => q({0}br.gal),
						'other' => q({0}br.gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}br.gal),
						'other' => q({0}br.gal),
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
						'one' => q({0}mätglas),
						'other' => q({0}mätglas),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}mätglas),
						'other' => q({0}mätglas),
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
						'one' => q({0}nypa),
						'other' => q({0}nypor),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0}nypa),
						'other' => q({0}nypor),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
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
						'one' => q({0}br.qt),
						'other' => q({0}br.qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}br.qt),
						'other' => q({0}br.qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}msk),
						'other' => q({0}msk),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}msk),
						'other' => q({0}msk),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tsk),
						'other' => q({0}tsk),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tsk),
						'other' => q({0}tsk),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(väderstreck),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(väderstreck),
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
					'angle-arc-minute' => {
						'name' => q(bågminuter),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bågminuter),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bågsekunder),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bågsekunder),
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
						'name' => q(varv),
						'one' => q({0} varv),
						'other' => q({0} varv),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(varv),
						'one' => q({0} varv),
						'other' => q({0} varv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(eng. tunnland),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(eng. tunnland),
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
						'name' => q(kv.fot),
						'one' => q({0} kv.fot),
						'other' => q({0} kv.fot),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kv.fot),
						'one' => q({0} kv.fot),
						'other' => q({0} kv.fot),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(tum²),
						'one' => q({0} tum²),
						'other' => q({0} tum²),
						'per' => q({0}/tum²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(tum²),
						'one' => q({0} tum²),
						'other' => q({0} tum²),
						'per' => q({0}/tum²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kvadratmile),
						'one' => q({0} kv.mile),
						'other' => q({0} kv.mile),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kvadratmile),
						'one' => q({0} kv.mile),
						'other' => q({0} kv.mile),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(objekt),
						'one' => q({0} objekt),
						'other' => q({0} objekt),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(objekt),
						'one' => q({0} objekt),
						'other' => q({0} objekt),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0} K),
						'other' => q({0} K),
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
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} %),
						'other' => q({0} %),
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
					'concentr-permillion' => {
						'name' => q(miljondelar),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(miljondelar),
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
						'name' => q(UK mpg),
						'one' => q({0} mpg UK),
						'other' => q({0} mpg UK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(UK mpg),
						'one' => q({0} mpg UK),
						'other' => q({0} mpg UK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ö),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ö),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
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
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(årh),
						'one' => q({0} årh),
						'other' => q({0} årh),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(årh),
						'one' => q({0} årh),
						'other' => q({0} årh),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dygn),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dygn),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(årt),
						'one' => q({0} årt),
						'other' => q({0} årt),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(årt),
						'one' => q({0} årt),
						'other' => q({0} årt),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(tim),
						'one' => q({0} tim),
						'other' => q({0} tim),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(tim),
						'one' => q({0} tim),
						'other' => q({0} tim),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mån),
						'one' => q({0} mån),
						'other' => q({0} mån),
						'per' => q({0}/mån),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mån),
						'one' => q({0} mån),
						'other' => q({0} mån),
						'per' => q({0}/mån),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(k),
						'one' => q({0} k),
						'other' => q({0} k),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(k),
						'one' => q({0} k),
						'other' => q({0} k),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(vkr),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vkr),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
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
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
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
						'name' => q(am. therm),
						'one' => q({0} am. therm),
						'other' => q({0} am. therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(am. therm),
						'one' => q({0} am. therm),
						'other' => q({0} am. therms),
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
						'name' => q(punkt),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punkt),
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
					'graphics-em' => {
						'name' => q(fyrkant),
						'one' => q({0} fyrkant),
						'other' => q({0} fyrkant),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(fyrkant),
						'one' => q({0} fyrkant),
						'other' => q({0} fyrkant),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(mpx),
						'one' => q({0} mpx),
						'other' => q({0} mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(mpx),
						'one' => q({0} mpx),
						'other' => q({0} mpx),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(px/tum),
						'one' => q({0} px/tum),
						'other' => q({0} px/tum),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(px/tum),
						'one' => q({0} px/tum),
						'other' => q({0} px/tum),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(famnar),
						'one' => q({0} famn),
						'other' => q({0} famnar),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(famnar),
						'one' => q({0} famn),
						'other' => q({0} famnar),
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
						'name' => q(eng. plogfårelgd),
						'one' => q({0} en.pfrld),
						'other' => q({0} en.pfrld),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(eng. plogfårelgd),
						'one' => q({0} en.pfrld),
						'other' => q({0} en.pfrld),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tum),
						'one' => q({0} tum),
						'other' => q({0} tum),
						'per' => q({0}/tum),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tum),
						'one' => q({0} tum),
						'other' => q({0} tum),
						'per' => q({0}/tum),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ljusår),
						'one' => q({0} ljusår),
						'other' => q({0} ljusår),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ljusår),
						'one' => q({0} ljusår),
						'other' => q({0} ljusår),
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
						'name' => q(mile),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mile),
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
					'length-nautical-mile' => {
						'name' => q(naut. mil),
						'one' => q({0} naut. mil),
						'other' => q({0} naut. mil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(naut. mil),
						'one' => q({0} naut. mil),
						'other' => q({0} naut. mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punkter),
						'one' => q({0} pkt),
						'other' => q({0} pkt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punkter),
						'one' => q({0} pkt),
						'other' => q({0} pkt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
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
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(uns),
						'one' => q({0} uns),
						'other' => q({0} uns),
						'per' => q({0}/uns),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(uns),
						'one' => q({0} uns),
						'other' => q({0} uns),
						'per' => q({0}/uns),
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
					'mass-stone' => {
						'name' => q(eng. sten),
						'one' => q({0} eng. sten),
						'other' => q({0} eng. sten),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(eng. sten),
						'one' => q({0} eng. sten),
						'other' => q({0} eng. sten),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(eng. k. ton),
						'one' => q({0} eng. k. ton),
						'other' => q({0} eng. k. ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(eng. k. ton),
						'one' => q({0} eng. k. ton),
						'other' => q({0} eng. k. ton),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hästkrafter),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hästkrafter),
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
						'name' => q(tum Hg),
						'one' => q({0} tum Hg),
						'other' => q({0} tum Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tum Hg),
						'one' => q({0} tum Hg),
						'other' => q({0} tum Hg),
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
					'speed-mile-per-hour' => {
						'name' => q(mile/timme),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mile/timme),
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
						'name' => q(eng. t:land·fot),
						'one' => q({0} eng. t:d·fot),
						'other' => q({0} eng. t:d·fot),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(eng. t:land·fot),
						'one' => q({0} eng. t:d·fot),
						'other' => q({0} eng. t:d·fot),
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
						'name' => q(skäppa),
						'one' => q({0} skäppa),
						'other' => q({0} skäppor),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skäppa),
						'one' => q({0} skäppa),
						'other' => q({0} skäppor),
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
						'name' => q(tum³),
						'one' => q({0} tum³),
						'other' => q({0} tum³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(tum³),
						'one' => q({0} tum³),
						'other' => q({0} tum³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(koppar),
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0} mcup),
						'other' => q({0} mcup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0} mcup),
						'other' => q({0} mcup),
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
						'name' => q(des.sked),
						'one' => q({0} dsk),
						'other' => q({0} dsk),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(des.sked),
						'one' => q({0} dsk),
						'other' => q({0} dsk),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(br. dsk),
						'one' => q(br. dsk),
						'other' => q({0} br. dsk),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(br. dsk),
						'one' => q(br. dsk),
						'other' => q({0} br. dsk),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(flytande dram),
						'one' => q({0} fl. dram),
						'other' => q({0} fl. dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(flytande dram),
						'one' => q({0} fl. dram),
						'other' => q({0} fl. dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(droppe),
						'one' => q({0} droppe),
						'other' => q({0} droppe),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(droppe),
						'one' => q({0} droppe),
						'other' => q({0} droppe),
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
						'one' => q({0} br. fl oz),
						'other' => q({0} br. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} br. fl oz),
						'other' => q({0} br. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Br. gal),
						'one' => q({0} br. gal),
						'other' => q({0} br. gal),
						'per' => q({0}/br. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Br. gal),
						'one' => q({0} br. gal),
						'other' => q({0} br. gal),
						'per' => q({0}/br. gal),
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
						'name' => q(mätglas),
						'one' => q({0} mätglas),
						'other' => q({0} mätglas),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(mätglas),
						'one' => q({0} mätglas),
						'other' => q({0} mätglas),
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
						'name' => q(nypa),
						'one' => q({0} nypa),
						'other' => q({0} nypa),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(nypa),
						'one' => q({0} nypa),
						'other' => q({0} nypa),
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
					'volume-quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(br. qt),
						'one' => q({0} br. qt),
						'other' => q({0} br. qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(br. qt),
						'one' => q({0} br. qt),
						'other' => q({0} br. qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(msk),
						'one' => q({0} msk),
						'other' => q({0} msk),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(msk),
						'one' => q({0} msk),
						'other' => q({0} msk),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
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
				end => q({0} och {1}),
				2 => q({0} och {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'exponential' => q(×۱۰^),
			'group' => q( ),
			'minusSign' => q(؜−),
			'perMille' => q(؉‏),
		},
		'arabext' => {
			'decimal' => q(,),
			'group' => q( ),
			'minusSign' => q(‎−‎),
			'timeSeparator' => q(:),
		},
		'fullwide' => {
			'timeSeparator' => q(：),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(×10^),
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
					'one' => '0 miljon',
					'other' => '0 miljoner',
				},
				'10000000' => {
					'one' => '00 miljon',
					'other' => '00 miljoner',
				},
				'100000000' => {
					'one' => '000 miljoner',
					'other' => '000 miljoner',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljarder',
				},
				'10000000000' => {
					'one' => '00 miljarder',
					'other' => '00 miljarder',
				},
				'100000000000' => {
					'one' => '000 miljarder',
					'other' => '000 miljarder',
				},
				'1000000000000' => {
					'one' => '0 biljon',
					'other' => '0 biljoner',
				},
				'10000000000000' => {
					'one' => '00 biljoner',
					'other' => '00 biljoner',
				},
				'100000000000000' => {
					'one' => '000 biljoner',
					'other' => '000 biljoner',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tn',
					'other' => '0 tn',
				},
				'10000' => {
					'one' => '00 tn',
					'other' => '00 tn',
				},
				'100000' => {
					'one' => '000 tn',
					'other' => '000 tn',
				},
				'1000000' => {
					'one' => '0 mn',
					'other' => '0 mn',
				},
				'10000000' => {
					'one' => '00 mn',
					'other' => '00 mn',
				},
				'100000000' => {
					'one' => '000 mn',
					'other' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 md',
					'other' => '0 md',
				},
				'10000000000' => {
					'one' => '00 md',
					'other' => '00 md',
				},
				'100000000000' => {
					'one' => '000 md',
					'other' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
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
				'currency' => q(andorransk peseta),
				'one' => q(andorransk peseta),
				'other' => q(andorranska pesetas),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(emiratisk dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghansk afghani),
				'one' => q(afghansk afghani),
				'other' => q(afghanska afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albansk lek \(1946–1965\)),
				'one' => q(albansk lek \(1946–1965\)),
				'other' => q(albanska lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albansk lek),
				'one' => q(albansk lek),
				'other' => q(albanska leke),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armenisk dram),
				'one' => q(armenisk dram),
				'other' => q(armeniska dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(antillergulden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolansk kwanza),
				'one' => q(angolansk kwanza),
				'other' => q(angolanska kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolansk kwanza \(1977–1990\)),
				'one' => q(angolansk kwanza \(1977–1990\)),
				'other' => q(angolanska kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolansk ny kwanza \(1990–2000\)),
				'one' => q(angolansk kwanza \(1990–2000\)),
				'other' => q(angolanska nya kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolansk kwanza reajustado \(1995–1999\)),
				'one' => q(angolansk kwanza reajustado \(1995–1999\)),
				'other' => q(angolanska kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinsk austral),
				'one' => q(argentinsk austral),
				'other' => q(argentinska australer),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentisk peso \(1970–1983\)),
				'one' => q(argentisk peso \(1970–1983\)),
				'other' => q(argentiska pesos \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentisk peso \(1881–1969\)),
				'one' => q(argentisk peso \(1881–1969\)),
				'other' => q(argentiska pesos \(1881–1969\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinsk peso \(1983–1985\)),
				'one' => q(argentinsk peso \(1983–1985\)),
				'other' => q(argentinska pesos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinsk peso),
				'one' => q(argentinsk peso),
				'other' => q(argentinska pesos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(österrikisk schilling),
				'one' => q(österrikisk schilling),
				'other' => q(österrikiska schilling),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(australisk dollar),
				'one' => q(australisk dollar),
				'other' => q(australiska dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubansk florin),
				'one' => q(arubansk florin),
				'other' => q(arubanska floriner),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdzjansk manat \(1993–2006\)),
				'one' => q(azerbajdzjansk manat \(1993–2006\)),
				'other' => q(azerbajdzjanska manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdzjansk manat),
				'one' => q(azerbajdzjansk manat),
				'other' => q(azerbajdzjanska manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinsk dinar \(1992–1994\)),
				'one' => q(bosnisk-hercegovinsk dinar \(1992–1994\)),
				'other' => q(bosnisk-hercegovinska dinarer \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinsk mark \(konvertibel\)),
				'one' => q(bosnisk-hercegovinsk mark \(konvertibel\)),
				'other' => q(bosnisk-hercegovinska mark \(konvertibla\)),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinsk dinar \(1994–1998\)),
				'one' => q(bosnisk-hercegovinsk dinar \(1994–1998\)),
				'other' => q(bosnisk-hercegovinska dinarer \(1994–1998\)),
			},
		},
		'BBD' => {
			symbol => 'Bds$',
			display_name => {
				'currency' => q(barbadisk dollar),
				'one' => q(barbadisk dollar),
				'other' => q(barbadiska dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshisk taka),
				'one' => q(bangladeshisk taka),
				'other' => q(bangladeshiska taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgisk franc \(konvertibel\)),
				'one' => q(belgisk franc \(konvertibel\)),
				'other' => q(belgiska franc \(konvertibla\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgisk franc),
				'one' => q(belgisk franc),
				'other' => q(belgiska franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgisk franc \(finansiell\)),
				'one' => q(belgisk franc \(finansiell\)),
				'other' => q(belgiska franc \(finansiella\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarisk hård lev \(1962–1999\)),
				'one' => q(bulgarisk hård lev \(1962–1999\)),
				'other' => q(bulgariska hårda lev \(1962–1999\)),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bulgarisk lev \(1952–1962\)),
				'one' => q(bulgarisk lev \(1952–1962\)),
				'other' => q(bulgariska lev \(1952–1962\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgarisk lev),
				'one' => q(bulgarisk lev),
				'other' => q(bulgariska leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulgarisk lev \(1881–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainsk dinar),
				'one' => q(bahrainsk dinar),
				'other' => q(bahrainska dinarer),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundisk franc),
				'one' => q(burundisk franc),
				'other' => q(burundiska franc),
			},
		},
		'BMD' => {
			symbol => 'BM$',
			display_name => {
				'currency' => q(bermudisk dollar),
				'one' => q(bermudisk dollar),
				'other' => q(bermudiska dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneisk dollar),
				'one' => q(bruneisk dollar),
				'other' => q(bruneiska dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviansk boliviano),
				'one' => q(boliviansk boliviano),
				'other' => q(bolivianska bolivianos),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviansk boliviano \(1864–1963\)),
				'one' => q(boliviansk boliviano \(1864–1963\)),
				'other' => q(bolivianska bolivianos \(1864–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliviansk peso),
				'one' => q(boliviansk peso),
				'other' => q(bolivianska pesos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliviansk mvdol),
				'one' => q(boliviansk mvdol),
				'other' => q(bolivianska mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro novo \(1967–1986\)),
				'one' => q(brasiliansk cruzeiro \(1967–1986\)),
				'other' => q(brasilianska cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brasiliansk cruzado),
				'one' => q(brasiliansk cruzado),
				'other' => q(brasilianska cruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro \(1990–1993\)),
				'one' => q(brasiliansk cruzeiro \(1990–1993\)),
				'other' => q(brasilianska cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BR$',
			display_name => {
				'currency' => q(brasiliansk real),
				'one' => q(brasiliansk real),
				'other' => q(brasilianska real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brasiliansk cruzado novo),
				'one' => q(brasiliansk cruzado novo),
				'other' => q(brasilianska cruzado novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro),
				'one' => q(brasiliansk cruzeiro),
				'other' => q(brasilianska cruzeiros),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro \(1942–1967\)),
				'one' => q(brasiliansk cruzeiro \(1942–1967\)),
				'other' => q(brasilianska cruzeiros \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BS$',
			display_name => {
				'currency' => q(bahamansk dollar),
				'one' => q(bahamansk dollar),
				'other' => q(bahamanska dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanesisk ngultrum),
				'one' => q(bhutanesisk ngultrum),
				'other' => q(bhutanesiska ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmesisk kyat),
				'one' => q(burmesisk kyat),
				'other' => q(burmesiska kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswansk pula),
				'one' => q(botswansk pula),
				'other' => q(botswanska pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(belarusisk ny rubel \(1994–1999\)),
				'one' => q(belarusisk ny rubel \(1994–1999\)),
				'other' => q(belarusiska nya rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(belarusisk rubel),
				'one' => q(belarusisk rubel),
				'other' => q(belarusiska rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(belarusisk rubel \(2000–2016\)),
				'one' => q(belarusisk rubel \(2000–2016\)),
				'other' => q(belarusiska rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZ$',
			display_name => {
				'currency' => q(belizisk dollar),
				'one' => q(belizisk dollar),
				'other' => q(beliziska dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kanadensisk dollar),
				'one' => q(kanadensisk dollar),
				'other' => q(kanadensiska dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongolesisk franc),
				'one' => q(kongolesisk franc),
				'other' => q(kongolesiska franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(euro \(konvertibelt konto, WIR Bank, Schweiz\)),
				'one' => q(euro \(WIR Bank\)),
				'other' => q(euro \(konvertibelt konto, WIR Bank, Schweiz\)),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(schweizisk franc),
				'one' => q(schweizisk franc),
				'other' => q(schweiziska franc),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(franc \(konvertibelt konto, WIR Bank, Schweiz\)),
				'one' => q(franc \(WIR Bank\)),
				'other' => q(franc \(konvertibelt konto, WIR Bank, Schweiz\)),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(chilensk escudo \(1960–1975\)),
				'one' => q(chilensk escudo \(1960–1975\)),
				'other' => q(chilenska escudos \(1960–1975\)),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(chilensk unidad de fomento),
				'one' => q(chilensk unidad de fomento),
				'other' => q(chilenska unidad de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilensk peso),
				'one' => q(chilensk peso),
				'other' => q(chilenska pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kinesisk yuan \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(kinesisk dollar),
				'one' => q(kinesisk dollar),
				'other' => q(kinesiska dollar),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(kinesisk yuan),
				'one' => q(kinesisk yuan),
				'other' => q(kinesiska yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(colombiansk peso),
				'one' => q(colombiansk peso),
				'other' => q(colombianska pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(colombiansk unidad de valor real),
				'one' => q(colombiansk unidad de valor real),
				'other' => q(colombianska unidad de valor real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(costarikansk colón),
				'one' => q(costarikansk colón),
				'other' => q(costarikanska colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(serbisk dinar \(2002–2006\)),
				'one' => q(serbisk dinar \(2002–2006\)),
				'other' => q(serbiska dinarer \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(tjeckoslovakisk krona \(–1993\)),
				'one' => q(tjeckoslovakisk hård koruna),
				'other' => q(tjeckiska hårda koruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubansk peso \(konvertibel\)),
				'one' => q(kubansk peso \(konvertibel\)),
				'other' => q(kubanska pesos \(konvertibla\)),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubansk peso),
				'one' => q(kubansk peso),
				'other' => q(kubanska pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdisk escudo),
				'one' => q(kapverdisk escudo),
				'other' => q(kapverdiska escudos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(cypriotiskt pund),
				'one' => q(cypriotiskt pund),
				'other' => q(cypriotiska pund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tjeckisk koruna),
				'one' => q(tjeckisk koruna),
				'other' => q(tjeckiska koruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(östtysk mark),
				'one' => q(östtysk mark),
				'other' => q(östtyska mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(tysk mark),
				'one' => q(tysk mark),
				'other' => q(tyska mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(djiboutisk franc),
				'one' => q(djiboutisk franc),
				'other' => q(djiboutiska franc),
			},
		},
		'DKK' => {
			symbol => 'Dkr',
			display_name => {
				'currency' => q(dansk krona),
				'one' => q(dansk krona),
				'other' => q(danska kronor),
			},
		},
		'DOP' => {
			symbol => 'RD$',
			display_name => {
				'currency' => q(dominikansk peso),
				'one' => q(dominikansk peso),
				'other' => q(dominikanska pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algerisk dinar),
				'one' => q(algerisk dinar),
				'other' => q(algeriska dinarer),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ecuadoriansk sucre),
				'one' => q(ecuadoriansk sucre),
				'other' => q(ecuadorianska sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ecuadoriansk unidad de valor constante),
				'one' => q(ecuadoriansk unidad de valor constante),
				'other' => q(ecuadorianska unidad de valor constante),
			},
		},
		'EEK' => {
			symbol => 'Ekr',
			display_name => {
				'currency' => q(estnisk krona),
				'one' => q(estnisk krona),
				'other' => q(estniska kronor),
			},
		},
		'EGP' => {
			symbol => 'EG£',
			display_name => {
				'currency' => q(egyptiskt pund),
				'one' => q(egyptiskt pund),
				'other' => q(egyptiska pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreansk nakfa),
				'one' => q(eritreansk nakfa),
				'other' => q(eritreanska nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spansk peseta \(konto\)),
				'one' => q(spansk peseta \(konto\)),
				'other' => q(spanska pesetas \(konto\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spansk peseta \(konvertibelt konto\)),
				'one' => q(spansk peseta \(konvertibelt konto\)),
				'other' => q(spanska pesetas \(konvertibelt konto\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(spansk peseta),
				'one' => q(spansk peseta),
				'other' => q(spanska pesetas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopisk birr),
				'one' => q(etiopisk birr),
				'other' => q(etiopiska birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finsk mark),
				'one' => q(finsk mark),
				'other' => q(finska mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fijidollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falklandspund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(fransk franc),
				'one' => q(fransk franc),
				'other' => q(franska franc),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(brittiskt pund),
				'one' => q(brittiskt pund),
				'other' => q(brittiska pund),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(georgisk kupon larit),
				'one' => q(georgisk kupon larit),
				'other' => q(georgiska kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgisk lari),
				'one' => q(georgisk lari),
				'other' => q(georgiska lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanansk cedi \(1979–2007\)),
				'one' => q(ghanansk cedi \(1979–2007\)),
				'other' => q(ghananska cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanansk cedi),
				'one' => q(ghanansk cedi),
				'other' => q(ghananska cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltiskt pund),
				'one' => q(gibraltiskt pund),
				'other' => q(gibraltiska pund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambisk dalasi),
				'one' => q(gambisk dalasi),
				'other' => q(gambiska dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineansk franc),
				'one' => q(guineansk franc),
				'other' => q(guineanska franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(guineansk syli),
				'one' => q(guineansk syli),
				'other' => q(guineanska syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekvatorialguineansk ekwele),
				'one' => q(ekvatorialguineansk ekwele),
				'other' => q(ekvatorialguineanska ekweler),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(grekisk drachma),
				'one' => q(grekisk drachma),
				'other' => q(grekiska drachmer),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalansk quetzal),
				'one' => q(guatemalansk quetzal),
				'other' => q(guatemalanska quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugisiska Guinea-escudo),
				'one' => q(Portugisiska Guinea-escudo),
				'other' => q(Portugisiska Guinea-escudos),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau-peso),
				'one' => q(Guinea-Bissau-peso),
				'other' => q(Guinea-Bissau-pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyanadollar),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Hongkongdollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduransk lempira),
				'one' => q(honduransk lempira),
				'other' => q(honduranska lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatisk dinar),
				'one' => q(kroatisk dinar),
				'other' => q(kroatiska dinarer),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kroatisk kuna),
				'one' => q(kroatisk kuna),
				'other' => q(kroatiska kunor),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitisk gourde),
				'one' => q(haitisk gourde),
				'other' => q(haitiska gourder),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ungersk forint),
				'one' => q(ungersk forint),
				'other' => q(ungerska forinter),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonesisk rupie),
				'one' => q(indonesisk rupie),
				'other' => q(indonesiska rupier),
			},
		},
		'IEP' => {
			symbol => 'IE£',
			display_name => {
				'currency' => q(irländskt pund),
				'one' => q(irländskt pund),
				'other' => q(irländska pund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(israeliskt pund),
				'one' => q(israeliskt pund),
				'other' => q(israeliska pund),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(israelisk shekel \(1980–1985\)),
				'one' => q(israelisk shekel \(1980–1985\)),
				'other' => q(israeliska shekel \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(israelisk ny shekel),
				'one' => q(israelisk ny shekel),
				'other' => q(israeliska nya shekel),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indisk rupie),
				'one' => q(indisk rupie),
				'other' => q(indiska rupier),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakisk dinar),
				'one' => q(irakisk dinar),
				'other' => q(irakiska dinarer),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iransk rial),
				'one' => q(iransk rial),
				'other' => q(iranska rial),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(isländsk gammal krona),
				'one' => q(isländsk gammal krona),
				'other' => q(isländska kronor \(1874–1981\)),
			},
		},
		'ISK' => {
			symbol => 'Ikr',
			display_name => {
				'currency' => q(isländsk krona),
				'one' => q(isländsk krona),
				'other' => q(isländska kronor),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italiensk lire),
				'one' => q(italiensk lire),
				'other' => q(italienska lire),
			},
		},
		'JMD' => {
			symbol => 'JM$',
			display_name => {
				'currency' => q(jamaicansk dollar),
				'one' => q(Jamaica-dollar),
				'other' => q(jamaicanska dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordansk dinar),
				'one' => q(jordansk dinar),
				'other' => q(jordanska dinarer),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(japansk yen),
				'one' => q(japansk yen),
				'other' => q(japanska yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyansk shilling),
				'one' => q(kenyansk shilling),
				'other' => q(kenyanska shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgizisk som),
				'one' => q(kirgizisk som),
				'other' => q(kirgiziska somer),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodjansk riel),
				'one' => q(kambodjansk riel),
				'other' => q(kambodjanska riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorisk franc),
				'one' => q(komorisk franc),
				'other' => q(komoriska franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(nordkoreansk won),
				'one' => q(nordkoreansk won),
				'other' => q(nordkoreanska won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(sydkoreansk hwan \(1953–1962\)),
				'one' => q(sydkoreansk hwan \(1953–1962\)),
				'other' => q(sydkoreanska hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(sydkoreansk won \(1945–1953\)),
				'one' => q(sydkoreansk won \(1945–1953\)),
				'other' => q(sydkoreanska won \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(sydkoreansk won),
				'one' => q(sydkoreansk won),
				'other' => q(sydkoreanska won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitisk dinar),
				'one' => q(kuwaitisk dinar),
				'other' => q(kuwaitiska dinarer),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(caymansk dollar),
				'one' => q(caymansk dollar),
				'other' => q(caymanska dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazakisk tenge),
				'one' => q(kazakisk tenge),
				'other' => q(kazakiska tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laotisk kip),
				'one' => q(laotisk kip),
				'other' => q(laotiska kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanesiskt pund),
				'one' => q(libanesiskt pund),
				'other' => q(libanesiska pund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srilankesisk rupie),
				'one' => q(srilankesisk rupie),
				'other' => q(srilankesiska rupier),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiansk dollar),
				'one' => q(liberiansk dollar),
				'other' => q(liberianska dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothisk loti),
				'one' => q(lesothisk loti),
				'other' => q(lesothiska lotier),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litauisk litas),
				'one' => q(litauisk litas),
				'other' => q(litauiska litai),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litauisk talonas),
				'one' => q(litauisk talonas),
				'other' => q(litauiska talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburgsk franc \(konvertibel\)),
				'one' => q(luxemburgsk franc \(konvertibel\)),
				'other' => q(luxemburgska franc \(konvertibla\)),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(luxemburgsk franc),
				'one' => q(luxemburgsk franc),
				'other' => q(luxemburgska franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luxemburgsk franc \(finansiell\)),
				'one' => q(luxemburgsk franc \(finansiell\)),
				'other' => q(luxemburgska franc \(finansiella\)),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lettisk lats),
				'one' => q(lettisk lats),
				'other' => q(lettiska lati),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(lettisk rubel),
				'one' => q(lettisk rubel),
				'other' => q(lettiska rubel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libysk dinar),
				'one' => q(libysk dinar),
				'other' => q(libyska dinarer),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marockansk dirham),
				'one' => q(marockansk dirham),
				'other' => q(marockanska dirhamer),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(marockansk franc),
				'one' => q(marockansk franc),
				'other' => q(marockanska franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monegaskisk franc \(–2001\)),
				'one' => q(monegaskisk franc \(–2001\)),
				'other' => q(monegaskiska franc \(–2001\)),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldavisk cupon \(1992–1993\)),
				'one' => q(moldavisk cupon \(1992–1993\)),
				'other' => q(moldaviska cupon \(1992–1993\)),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldavisk leu),
				'one' => q(moldavisk leu),
				'other' => q(moldaviska lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskisk ariary),
				'one' => q(madagaskisk ariary),
				'other' => q(madagaskiska ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(madagaskisk franc),
				'one' => q(madagaskisk franc),
				'other' => q(madagaskiska franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonisk denar),
				'one' => q(makedonisk denar),
				'other' => q(makedoniska denarer),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedonisk denar \(1992–1993\)),
				'one' => q(makedonisk denar \(1992–1993\)),
				'other' => q(makedoniska denarer \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(malisk franc),
				'one' => q(malisk franc),
				'other' => q(maliska franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarisk kyat),
				'one' => q(myanmarisk kyat),
				'other' => q(myanmariska kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolisk tögrög),
				'one' => q(mongolisk tögrög),
				'other' => q(mongoliska tögrög),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makanesisk pataca),
				'one' => q(makanesisk pataca),
				'other' => q(makanesiska pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauretansk ouguiya \(1973–2017\)),
				'one' => q(mauretansk ouguiya \(1973–2017\)),
				'other' => q(mauretanska ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauretansk ouguiya),
				'one' => q(mauretansk ouguiya),
				'other' => q(mauretanska ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltesisk lire),
				'one' => q(maltesisk lire),
				'other' => q(maltesiska lire),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltesiskt pund),
				'one' => q(maltesiskt pund),
				'other' => q(maltesiska pund),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritisk rupie),
				'one' => q(mauritisk rupie),
				'other' => q(mauritiska rupier),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(maldivisk rupie),
				'one' => q(maldivisk rupie),
				'other' => q(maldiviska rupier),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivisk rufiyaa),
				'one' => q(maldivisk rufiyaa),
				'other' => q(maldiviska rufiyer),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawisk kwacha),
				'one' => q(malawisk kwacha),
				'other' => q(malawiska kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexikansk peso),
				'one' => q(mexikansk peso),
				'other' => q(mexikanska pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(mexikansk silverpeso \(1861–1992\)),
				'one' => q(mexikansk silverpeso \(1861–1992\)),
				'other' => q(mexikanska silverpesos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(mexikansk unidad de inversion),
				'one' => q(mexikansk unidad de inversion),
				'other' => q(mexikanska unidad de inversion),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysisk ringgit),
				'one' => q(malaysisk ringgit),
				'other' => q(malaysiska ringgiter),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(moçambikisk escudo),
				'one' => q(moçambikisk escudo \(1914–1980\)),
				'other' => q(moçambikiska escudos),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(gammal moçambikisk metical),
				'one' => q(moçambikisk metical \(1980–2006\)),
				'other' => q(gammla moçambikiska metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(moçambikisk metical),
				'one' => q(moçambikisk metical),
				'other' => q(moçambikiska metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibisk dollar),
				'one' => q(namibisk dollar),
				'other' => q(namibiska dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigeriansk naira),
				'one' => q(nigeriansk naira),
				'other' => q(nigerianska naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nicaraguansk córdoba \(1998–1991\)),
				'one' => q(nicaraguansk córdoba \(1998–1991\)),
				'other' => q(nicaraguanska córdobas \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguansk córdoba),
				'one' => q(nicaraguansk córdoba),
				'other' => q(nicaraguanska córdobas),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nederländsk gulden),
				'one' => q(nederländsk gulden),
				'other' => q(nederländska gulden),
			},
		},
		'NOK' => {
			symbol => 'Nkr',
			display_name => {
				'currency' => q(norsk krona),
				'one' => q(norsk krona),
				'other' => q(norska kronor),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalesisk rupie),
				'one' => q(nepalesisk rupie),
				'other' => q(nepalesiska rupier),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(nyzeeländsk dollar),
				'one' => q(nyzeeländsk dollar),
				'other' => q(nyzeeländska dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omansk rial),
				'one' => q(omansk rial),
				'other' => q(omanska rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamansk balboa),
				'one' => q(panamansk balboa),
				'other' => q(panamanska balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruansk inti),
				'one' => q(peruansk inti),
				'other' => q(peruanska intier),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruansk sol),
				'one' => q(peruansk sol),
				'other' => q(peruanska sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruansk sol \(1863–1965\)),
				'one' => q(peruansk sol \(1863–1965\)),
				'other' => q(peruanska sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuansk kina),
				'one' => q(papuansk kina),
				'other' => q(papuanska kinor),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filippinsk peso),
				'one' => q(filippinsk peso),
				'other' => q(filippinska pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistansk rupie),
				'one' => q(pakistansk rupie),
				'other' => q(pakistanska rupier),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polsk zloty),
				'one' => q(polsk zloty),
				'other' => q(polska zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polsk zloty \(1950–1995\)),
				'one' => q(polsk zloty \(1950–1995\)),
				'other' => q(polska zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugisisk escudo),
				'one' => q(portugisisk escudo),
				'other' => q(portugisiska escudos),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayansk guarani),
				'one' => q(paraguayansk guarani),
				'other' => q(paraguayska guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(qatarisk rial),
				'one' => q(qatarisk rial),
				'other' => q(qatariska rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesisk dollar),
				'one' => q(rhodesisk dollar),
				'other' => q(rhodesiska dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(rumänsk leu \(1952–2005\)),
				'one' => q(rumänsk leu \(1952–2005\)),
				'other' => q(rumänska leu \(1952–2005\)),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(rumänsk leu),
				'one' => q(rumänsk leu),
				'other' => q(rumänska lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbisk dinar),
				'one' => q(serbisk dinar),
				'other' => q(serbiska dinarer),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rysk rubel),
				'one' => q(rysk rubel),
				'other' => q(ryska rubel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rysk rubel \(1991–1998\)),
				'one' => q(rysk rubel \(1991–1998\)),
				'other' => q(ryska rubel \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandisk franc),
				'one' => q(rwandisk franc),
				'other' => q(rwandiska franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudisk riyal),
				'one' => q(saudisk riyal),
				'other' => q(saudiska riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomondollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychellisk rupie),
				'one' => q(seychellisk rupie),
				'other' => q(seychelliska rupier),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(sudansk dinar \(1992–2007\)),
				'one' => q(sudansk dinar \(1992–2007\)),
				'other' => q(sudanska dinarer \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanesiskt pund),
				'one' => q(sudanesiskt pund),
				'other' => q(sudanesiska pund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(sudanskt pund \(1916–1992\)),
				'one' => q(sudanskt pund \(1916–1992\)),
				'other' => q(sudanska pund \(1916–1992\)),
			},
		},
		'SEK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(svensk krona),
				'one' => q(svensk krona),
				'other' => q(svenska kronor),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singaporiansk dollar),
				'one' => q(singaporiansk dollar),
				'other' => q(singaporianska dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sankthelenskt pund),
				'one' => q(sankthelenskt pund),
				'other' => q(sankthelenska pund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovensk tolar),
				'one' => q(slovensk tolar),
				'other' => q(slovenska tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovakisk koruna),
				'one' => q(slovakisk krona),
				'other' => q(slovakiska korunor),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierraleonsk leone),
				'one' => q(sierraleonsk leone),
				'other' => q(sierraleonska leoner),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonsk leone \(1964—2022\)),
				'one' => q(sierraleonsk leone \(1964—2022\)),
				'other' => q(sierraleonska leoner \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somalisk shilling),
				'one' => q(somalisk shilling),
				'other' => q(somaliska shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamesisk dollar),
				'one' => q(surinamesisk dollar),
				'other' => q(surinamesiska dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamesisk gulden),
				'one' => q(surinamesisk gulden),
				'other' => q(surinamesiska gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sydsudanesiskt pund),
				'one' => q(sydsudanesiskt pund),
				'other' => q(sydsudanesiska pund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(saotomeansk dobra \(1977–2017\)),
				'one' => q(saotomeansk dobra \(1977–2017\)),
				'other' => q(saotomeanska dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(saotomeansk dobra),
				'one' => q(saotomeansk dobra),
				'other' => q(saotomeanska dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovjetisk rubel),
				'one' => q(sovjetisk rubel),
				'other' => q(sovjetiska rubler),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadoransk colón),
				'one' => q(salvadoransk colón),
				'other' => q(salvadoranska colón),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriskt pund),
				'one' => q(syriskt pund),
				'other' => q(syriska pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swaziländsk lilangeni),
				'one' => q(swaziländsk lilangeni),
				'other' => q(swaziländska lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thailändsk baht),
				'one' => q(thailändsk baht),
				'other' => q(thailändska baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadzjikisk rubel),
				'one' => q(tadzjikisk rubel),
				'other' => q(tadzjikiska rubler),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadzjikisk somoni),
				'one' => q(tadzjikisk somoni),
				'other' => q(tadzjikiska somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenistansk manat \(1993–2009\)),
				'one' => q(turkmenistansk manat \(1993–2009\)),
				'other' => q(turkmenistanska manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenistansk manat),
				'one' => q(turkmenistansk manat),
				'other' => q(turkmenistanska manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisisk dinar),
				'one' => q(tunisisk dinar),
				'other' => q(tunisiska dinarer),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongansk paʻanga),
				'one' => q(tongansk paʻanga),
				'other' => q(tonganska paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(östtimoresisk escudo),
				'one' => q(östtimoresisk escudo),
				'other' => q(östtimoresiska escudos),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(turkisk lire \(1922–2005\)),
				'one' => q(turkisk lire \(1922–2005\)),
				'other' => q(turkiska lire \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turkisk lira),
				'one' => q(turkisk lira),
				'other' => q(turkiska lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidaddollar),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(taiwanesisk dollar),
				'one' => q(taiwanesisk dollar),
				'other' => q(taiwanesiska dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanisk shilling),
				'one' => q(tanzanisk shilling),
				'other' => q(tanzaniska shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainsk hryvnia),
				'one' => q(ukrainsk hryvnia),
				'other' => q(ukrainska hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrainsk karbovanetz),
				'one' => q(ukrainsk karbovanetz \(1992–1996\)),
				'other' => q(ukrainska karbovanetz \(1992–1996\)),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandisk shilling \(1966–1987\)),
				'one' => q(ugandisk shilling \(1966–1987\)),
				'other' => q(ugandiska shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandisk shilling),
				'one' => q(ugandisk shilling),
				'other' => q(ugandiska shilling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(amerikansk dollar),
				'one' => q(amerikansk dollar),
				'other' => q(amerikanska dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(US-dollar \(nästa dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US-dollar \(samma dag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayansk peso en unidades indexadas),
				'one' => q(uruguayansk peso en unidades indexadas),
				'other' => q(uruguayanska pesos en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayansk peso \(1975–1993\)),
				'one' => q(uruguayansk peso \(1975–1993\)),
				'other' => q(uruguayanska pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayansk peso),
				'one' => q(uruguayansk peso),
				'other' => q(uruguayanska pesos),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(uruguayansk indexenhet för nominell lön),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbekisk sum),
				'one' => q(uzbekisk sum),
				'other' => q(uzbekiska sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelansk bolivar \(1871–2008\)),
				'one' => q(venezuelansk bolivar \(1871–2008\)),
				'other' => q(venezuelanska bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelansk bolívar \(2008–2018\)),
				'one' => q(venezuelansk bolívar \(2008–2018\)),
				'other' => q(venezuelanska bolívar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelansk bolívar),
				'one' => q(venezuelansk bolívar),
				'other' => q(venezuelanska bolívar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnamesisk dong),
				'one' => q(vietnamesisk dong),
				'other' => q(vietnamesiska dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamesisk dong \(1978–1985\)),
				'one' => q(vietnamesisk dong \(1978–1985\)),
				'other' => q(vietnamesiska dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatisk vatu),
				'one' => q(vanuatisk vatu),
				'other' => q(vanuatiska vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(västsamoansk tala),
				'one' => q(västsamoansk tala),
				'other' => q(västsamoanska tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(centralafrikansk franc),
				'one' => q(centralafrikansk franc),
				'other' => q(centralafrikanska franc),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(silver),
				'one' => q(uns silver),
				'other' => q(silveruns),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(guld),
				'one' => q(uns guld),
				'other' => q(gulduns),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(europeisk kompositenhet),
				'one' => q(europeisk kompositenhet),
				'other' => q(europeiska kompositenheter),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europeisk monetär enhet),
				'one' => q(europeisk monetär enhet),
				'other' => q(europeiska monetära enheter),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europeisk kontoenhet \(XBC\)),
				'one' => q(europeisk kontoenhet \(XBC\)),
				'other' => q(europeiska kontoenheter \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europeisk kontoenhet \(XBD\)),
				'one' => q(europeisk kontoenhet \(XBD\)),
				'other' => q(europeiska kontoenheter \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(östkaribisk dollar),
				'one' => q(östkaribisk dollar),
				'other' => q(östkaribiska dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(IMF särskild dragningsrätt),
				'one' => q(IMF särskild dragningsrätt),
				'other' => q(IMF särskilda dragningsrätter),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(europeisk valutaenhet),
				'one' => q(europeisk valutaenhet),
				'other' => q(europeiska valutaenheter),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(fransk guldfranc),
				'one' => q(fransk guldfranc),
				'other' => q(franska guldfranc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(internationella järnvägsunionens franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(västafrikansk franc),
				'one' => q(västafrikansk franc),
				'other' => q(västafrikanska franc),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'one' => q(uns palladium),
				'other' => q(palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'one' => q(uns platina),
				'other' => q(platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-fond),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(latinamerikansk sucre),
				'one' => q(latinamerikansk sucre),
				'other' => q(latinamerikanska sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(testvalutaenhet),
				'one' => q(testvalutaenhet),
				'other' => q(testvalutaenheter),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(afrikansk kontoenhet),
				'one' => q(afrikansk kontoenhet),
				'other' => q(afrikanska kontoenheter),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(okänd valuta),
				'one' => q(\(okänd valutaenhet\)),
				'other' => q(\(okända valutaenheter\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenitisk dinar),
				'one' => q(jemenitisk dinar),
				'other' => q(jemenitiska dinarer),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenitisk rial),
				'one' => q(jemenitisk rial),
				'other' => q(jemenitiska rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(jugoslavisk dinar \(1966–1990\)),
				'one' => q(jugoslavisk dinar \(1966–1990\)),
				'other' => q(jugoslaviska dinarer \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(jugoslavisk dinar \(1994–2002\)),
				'one' => q(jugoslavisk dinar \(1994–2002\)),
				'other' => q(jugoslaviska dinarer \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslavisk dinar \(1990–1992\)),
				'one' => q(jugoslavisk dinar \(1990–1992\)),
				'other' => q(jugoslaviska dinarer \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(jugoslavisk dinar \(1992–1993\)),
				'one' => q(jugoslavisk dinar \(1992–1993\)),
				'other' => q(jugoslaviska dinarer \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(sydafrikansk rand \(finansiell\)),
				'one' => q(sydafrikansk rand \(finansiell\)),
				'other' => q(sydafrikanska rand \(finansiella\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sydafrikansk rand),
				'one' => q(sydafrikansk rand),
				'other' => q(sydafrikanska rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambisk kwacha \(1968–2012\)),
				'one' => q(zambisk kwacha \(1968–2012\)),
				'other' => q(zambiska kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambisk kwacha),
				'one' => q(zambisk kwacha),
				'other' => q(zambiska kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairisk ny zaire),
				'one' => q(zaïrisk ny zaïre),
				'other' => q(zaïriska nya zaïre),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairisk zaire),
				'one' => q(zaïrisk zaïre),
				'other' => q(zaïriska zaïre),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwe-dollar),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwe-dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwe-dollar \(2008\)),
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
							'1:a mån',
							'2:a mån',
							'3:e mån',
							'4:e mån',
							'5:e mån',
							'6:e mån',
							'7:e mån',
							'8:e mån',
							'9:e mån',
							'10:e mån',
							'11:e mån',
							'12:e mån'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'första månaden',
							'andra månaden',
							'tredje månaden',
							'fjärde månaden',
							'femte månaden',
							'sjätte månaden',
							'sjunde månaden',
							'åttonde månaden',
							'nionde månaden',
							'tionde månaden',
							'elfte månaden',
							'tolfte månaden'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'tout',
							'bâbâ',
							'hâtour',
							'kiahk',
							'toubah',
							'amshîr',
							'barmahât',
							'barmoudah',
							'bashans',
							'ba’ounah',
							'abîb',
							'misra',
							'al-nasi'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Bâbâ',
							'Hâtour',
							'Kiahk',
							'Toubah',
							'Amshîr',
							'Barmahât',
							'Barmoudah',
							'Bashans',
							'Ba’ounah',
							'Abîb',
							'Misra',
							'Al-nasi'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Tout',
							'Bâbâ',
							'Hâtour',
							'Kiahk',
							'Toubah',
							'Amshîr',
							'Barmahât',
							'Barmoudah',
							'Bashans',
							'Ba’ounah',
							'Abîb',
							'Misra',
							'Al-nasi'
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
							'mäskäräm',
							'teqemt',
							'hedar',
							'tahesas',
							'ter',
							'yäkatit',
							'mägabit',
							'miyazya',
							'guenbot',
							'säné',
							'hamlé',
							'nähasé',
							'pagumén'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahesas',
							'Ter',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Guenbot',
							'Säné',
							'Hamlé',
							'Nähasé',
							'Pagumén'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahesas',
							'Ter',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Guenbot',
							'Säné',
							'Hamlé',
							'Nähasé',
							'Pagumén'
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
							'maj',
							'juni',
							'juli',
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
							'januari',
							'februari',
							'mars',
							'april',
							'maj',
							'juni',
							'juli',
							'augusti',
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
							'tishrí',
							'heshván',
							'kislév',
							'tevét',
							'shevát',
							'adár I',
							'adár',
							'nisán',
							'ijjár',
							'siván',
							'tammúz',
							'ab',
							'elúl'
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
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tishrí',
							'Heshván',
							'Kislév',
							'Tevét',
							'Shevát',
							'Adár I',
							'Adár',
							'Nisán',
							'Ijjár',
							'Siván',
							'Tammúz',
							'Ab',
							'Elúl'
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
					wide => {
						nonleap => [
							'Tishrí',
							'Heshván',
							'Kislév',
							'Tevét',
							'Shevát',
							'Adár I',
							'Adár',
							'Nisán',
							'Ijjár',
							'Siván',
							'Tammúz',
							'Ab',
							'Elúl'
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
							'vaishākh',
							'jyaishtha',
							'āshādha',
							'shrāvana',
							'bhādrapad',
							'āshwin',
							'kārtik',
							'mārgashīrsha',
							'paush',
							'māgh',
							'phālgun'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaishākh',
							'Jyaishtha',
							'Āshādha',
							'Shrāvana',
							'Bhādrapad',
							'Āshwin',
							'Kārtik',
							'Mārgashīrsha',
							'Paush',
							'Māgh',
							'Phālgun'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaishākh',
							'Jyaishtha',
							'Āshādha',
							'Shrāvana',
							'Bhādrapad',
							'Āshwin',
							'Kārtik',
							'Mārgashīrsha',
							'Paush',
							'Māgh',
							'Phālgun'
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
							'rabi’ al-awwal',
							'rabi’ al-akhir',
							'jumada-l-ula',
							'jumada-l-akhira',
							'rajab',
							'sha’ban',
							'ramadan',
							'shawwal',
							'dhu-l-ga’da',
							'dhu-l-hijja'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabi’ al-awwal',
							'Rabi’ al-akhir',
							'Jumada-l-ula',
							'Jumada-l-akhira',
							'Rajab',
							'Sha’ban',
							'Ramadan',
							'Shawwal',
							'Dhu-l-ga’da',
							'Dhu-l-hijja'
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
							'khordād',
							'tir',
							'mordād',
							'shahrivar',
							'mehr',
							'ābān',
							'āzar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordād',
							'Tir',
							'Mordād',
							'Shahrivar',
							'Mehr',
							'Ābān',
							'Āzar',
							'Dey',
							'Bahman',
							'Esfand'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordād',
							'Tir',
							'Mordād',
							'Shahrivar',
							'Mehr',
							'Ābān',
							'Āzar',
							'Dey',
							'Bahman',
							'Esfand'
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
						mon => 'mån',
						tue => 'tis',
						wed => 'ons',
						thu => 'tors',
						fri => 'fre',
						sat => 'lör',
						sun => 'sön'
					},
					short => {
						mon => 'må',
						tue => 'ti',
						wed => 'on',
						thu => 'to',
						fri => 'fr',
						sat => 'lö',
						sun => 'sö'
					},
					wide => {
						mon => 'måndag',
						tue => 'tisdag',
						wed => 'onsdag',
						thu => 'torsdag',
						fri => 'fredag',
						sat => 'lördag',
						sun => 'söndag'
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
					wide => {0 => '1:a kvartalet',
						1 => '2:a kvartalet',
						2 => '3:e kvartalet',
						3 => '4:e kvartalet'
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
			if ($_ eq 'chinese') {
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
					'afternoon1' => q{på efterm.},
					'am' => q{fm},
					'evening1' => q{på kvällen},
					'midnight' => q{midnatt},
					'morning1' => q{på morg.},
					'morning2' => q{på förm.},
					'night1' => q{på natten},
					'pm' => q{em},
				},
				'narrow' => {
					'afternoon1' => q{på efterm.},
					'evening1' => q{på kvällen},
					'midnight' => q{midn.},
					'morning1' => q{på morg.},
					'morning2' => q{på förm.},
					'night1' => q{på natten},
				},
				'wide' => {
					'afternoon1' => q{på eftermiddagen},
					'evening1' => q{på kvällen},
					'midnight' => q{midnatt},
					'morning1' => q{på morgonen},
					'morning2' => q{på förmiddagen},
					'night1' => q{på natten},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{efterm.},
					'evening1' => q{kväll},
					'morning1' => q{morgon},
					'morning2' => q{förm.},
					'night1' => q{natt},
				},
				'narrow' => {
					'afternoon1' => q{efterm.},
					'evening1' => q{kväll},
					'midnight' => q{midn.},
					'morning1' => q{morg.},
					'morning2' => q{förm.},
					'night1' => q{natt},
				},
				'wide' => {
					'afternoon1' => q{eftermiddag},
					'am' => q{förmiddag},
					'evening1' => q{kväll},
					'morning1' => q{morgon},
					'morning2' => q{förmiddag},
					'night1' => q{natt},
					'pm' => q{eftermiddag},
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
				'0' => 'Buddhistisk era'
			},
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			wide => {
				'0' => 'före Kristus',
				'1' => 'efter Kristus'
			},
		},
		'hebrew' => {
			wide => {
				'0' => 'Anno Mundi'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'SAKA'
			},
			wide => {
				'0' => 'Saka-eran'
			},
		},
		'islamic' => {
			wide => {
				'0' => 'efter Hirja'
			},
		},
		'japanese' => {
			abbreviated => {
				'10' => 'Tempyō (729–749)',
				'11' => 'Tempyō-kampō (749–749)',
				'12' => 'Tempyō-shōhō (749–757)',
				'13' => 'Tempyō-hōji (757–765)',
				'14' => 'Temphō-jingo (765–767)',
				'25' => 'Saiko (854–857)',
				'26' => 'Tennan (857–859)',
				'28' => 'Genkei (877–885)',
				'30' => 'Kampyō (889–898)',
				'34' => 'Shōhei (931–938)',
				'42' => 'Ten-en (973–976)',
				'47' => 'Ei-en (987–989)',
				'68' => 'Eiho (1081–1084)',
				'71' => 'Kaho (1094–1096)',
				'73' => 'Shōtoku (1097–1099)',
				'80' => 'Gen-ei (1118–1120)',
				'81' => 'Hoan (1120–1124)',
				'86' => 'Hoen (1135–1141)',
				'89' => 'Tenyō (1144–1145)',
				'93' => 'Hogen (1156–1159)',
				'99' => 'Nin-an (1166–1169)',
				'106' => 'Genryuku (1184–1185)',
				'112' => 'Ken-ei (1206–1207)',
				'113' => 'Shōgen (1207–1211)',
				'116' => 'Shōkyū (1219–1222)',
				'123' => 'Tempuku (1233–1234)',
				'127' => 'En-ō (1239–1240)',
				'135' => 'Bun-ō (1260–1261)',
				'137' => 'Bun-ei (1264–1275)',
				'146' => 'Enkei (1308–1311)',
				'151' => 'Genkyō (1321–1324)',
				'153' => 'Kareki (1326–1329)',
				'156' => 'Kemmu (1334–1336)',
				'174' => 'Bun-an (1444–1449)',
				'190' => 'Tenmon (1532–1555)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624–1644)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'206' => 'Tenwa (1681–1684)',
				'215' => 'Kan-en (1748–1751)',
				'216' => 'Hōryaku (1751–1764)',
				'218' => 'An-ei (1772–1781)',
				'228' => 'Man-en (1860–1861)'
			},
		},
		'persian' => {
			wide => {
				'0' => 'Anno Persarum'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'före R.K.',
				'1' => 'R.K.'
			},
			narrow => {
				'0' => 'f.R.K.'
			},
			wide => {
				'0' => 'före Republiken Kina',
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{y-MM-dd G},
		},
		'chinese' => {
			'full' => q{EEEE d MMMM r(U)},
			'long' => q{d MMMM r(U)},
			'medium' => q{d MMM r},
			'short' => q{r-MM-dd},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{G y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{y-MM-dd},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
		'buddhist' => {
			MMdd => q{d/M},
			yyyyMM => q{y-MM G},
		},
		'chinese' => {
			Ed => q{E d},
			Gy => q{r(U)},
			GyMMM => q{MMM r(U)},
			GyMMMEd => q{E d MMM r(U)},
			GyMMMd => q{d MMM r},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			UM => q{M/U},
			UMMM => q{MMM U},
			UMMMd => q{d MMM U},
			UMd => q{d/M U},
			yyyyMEd => q{E r-MM-dd},
			yyyyMMM => q{MMM r(U)},
			yyyyMMMEd => q{E d MMM r(U)},
			yyyyMMMM => q{MMMM r(U)},
			yyyyMMMd => q{d MMM r},
			yyyyQQQ => q{QQQ r(U)},
			yyyyQQQQ => q{QQQQ r(U)},
		},
		'generic' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{y-MM-dd GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/M},
			MMdd => q{dd/MM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{y-MM G},
			yyyyMEd => q{E y-MM-dd G},
			yyyyMM => q{G y-MM},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{y-MM-dd G},
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
			GyMd => q{y-MM-dd GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMW => q{'vecka' W 'i' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/M},
			MMdd => q{dd/MM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yMEd => q{E, y-MM-dd},
			yMM => q{y-MM},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'vecka' w, Y},
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
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			GyM => {
				G => q{y-MM GGGGG – y-MM GGGGG},
				M => q{y-MM – y-MM GGGGG},
				y => q{y-MM – y-MM GGGGG},
			},
			GyMEd => {
				y => q{E y-MM-dd – E y-MM-dd GGGGG},
			},
			GyMd => {
				M => q{y-MM-dd – y-MM-dd GGGGG},
				d => q{y-MM-dd – y-MM-dd GGGGG},
			},
			yM => {
				M => q{y-MM – MM GGGGG},
			},
			yMMMEd => {
				d => q{E d MMM–E d MMM y G},
			},
			yMd => {
				M => q{y-MM-dd – MM-dd GGGGG},
				d => q{y-MM-d – d GGGGG},
				y => q{y-MM-dd – y-MM-dd GGGGG},
			},
		},
		'chinese' => {
			MEd => {
				M => q{E MM-dd – E MM-dd},
				d => q{E MM-dd – E MM-dd},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMM => {
				M => q{MMM – MMM U},
				y => q{MMM U – MMM U},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM U},
				d => q{E d MMM – E d MMM U},
				y => q{E d MMM U – E d MMM U},
			},
			yMMMM => {
				M => q{MMMM–MMMM U},
			},
			yMMMd => {
				M => q{d MMM – d MMM U},
				d => q{d–d MMM U},
				y => q{d MMM U – d MMM U},
			},
		},
		'coptic' => {
			Bh => {
				B => q{h B – h B},
			},
		},
		'generic' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G–y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG–M/y GGGGG},
				M => q{M/y–M/y GGGGG},
				y => q{M/y–M/y GGGGG},
			},
			GyMEd => {
				G => q{E y-MM-dd GGGG – E y-MM-dd GGGG},
				M => q{E d/M y – E d/M y GGGGG},
				d => q{E y-MM-dd – E y-MM-dd GGGGG},
				y => q{E d/M y – E d/M y GGGGG},
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
				d => q{d–d MMM y G},
				y => q{d MMM y G – d MMM d y},
			},
			GyMd => {
				G => q{y-MM-dd GGGGG – y-MM-dd GGGGG},
				M => q{d/M/y–d/M/y GGGGG},
				d => q{d/M/y–d/M/y GGGGG},
				y => q{y-MM-dd – y-MM-dd GGGGG},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M–d/M},
				d => q{d–d/M},
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
				M => q{y-MM – y-MM GGGGG},
				y => q{y-MM – y-MM GGGGG},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd GGGGG},
				d => q{E y-MM-dd – E y-MM-dd GGGGG},
				y => q{E y-MM-dd – E y-MM-dd GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM–E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y–E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM–d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y–d MMM y G},
			},
			yMd => {
				M => q{d/M y – d/M y GGGGG},
				d => q{d/M y – d/M y GGGGG},
				y => q{d/M y – d/M y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B–h B},
			},
			Bhm => {
				B => q{h:mm B–h:mm B},
				h => q{hh:mm – hh:mm B},
				m => q{hh:mm – hh:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG–M/y GGGGG},
				M => q{M/y–M/y GGGGG},
				y => q{M/y–M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG–E, d/M/y GGGGG},
				M => q{E, d/M/y–E, d/M/y GGGGG},
				d => q{E, d/M/y–E, d/M/y GGGGG},
				y => q{E, d/M/y–E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{d MMM y G, E – d MMM y G, E},
				M => q{E d MMM y G – E d MMM},
				d => q{E d MMM y G – E d MMM},
				y => q{E d MMM y G – E d MMM y},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y G – d MMM y},
			},
			GyMd => {
				G => q{d/M/y GGGGG–d/M/y GGGGG},
				M => q{d/M/y–d/M/y GGGGG},
				d => q{d/M/y–d/M/y GGGGG},
				y => q{d/M/y–d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M–d/M},
				d => q{d–d/M},
			},
			h => {
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
			yM => {
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E dd MMM–E dd MMM y},
				d => q{E dd MMM–E dd MMM y},
				y => q{E dd MMM y–E dd MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM–d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y–d MMM y},
			},
			yMd => {
				M => q{y-MM-dd – MM-dd},
				d => q{y-MM-dd – dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'hebrew' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'islamic' => {
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'persian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;−HH:mm),
		regionFormat => q({0}tid),
		regionFormat => q({0} (sommartid)),
		regionFormat => q({0} (normaltid)),
		'Acre' => {
			long => {
				'daylight' => q#västbrasiliansk sommartid#,
				'generic' => q#västbrasiliansk tid#,
				'standard' => q#västbrasiliansk normaltid#,
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
			exemplarCity => q#Dar es-Salaam#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Aaiún#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#centralafrikansk tid#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#östafrikansk tid#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#sydafrikansk tid#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#västafrikansk sommartid#,
				'generic' => q#västafrikansk tid#,
				'standard' => q#västafrikansk normaltid#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska, sommartid#,
				'generic' => q#Alaskatid#,
				'standard' => q#Alaska, normaltid#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatysommartid#,
				'generic' => q#Almatytid#,
				'standard' => q#Almatynormaltid#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonas, sommartid#,
				'generic' => q#Amazonastid#,
				'standard' => q#Amazonas, normaltid#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caymanöarna#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Jujuy' => {
			exemplarCity => q#San Salvador de Jujuy#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko City#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fernando de Noronha#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
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
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#centralnordamerikansk sommartid#,
				'generic' => q#centralnordamerikansk tid#,
				'standard' => q#centralnordamerikansk normaltid#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#östnordamerikansk sommartid#,
				'generic' => q#östnordamerikansk tid#,
				'standard' => q#östnordamerikansk normaltid#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Klippiga bergen, sommartid#,
				'generic' => q#Klippiga bergentid#,
				'standard' => q#Klippiga bergen, normaltid#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#västnordamerikansk sommartid#,
				'generic' => q#västnordamerikansk tid#,
				'standard' => q#västnordamerikansk normaltid#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyrsommartid#,
				'generic' => q#Anadyrtid#,
				'standard' => q#Anadyrnormaltid#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia, sommartid#,
				'generic' => q#Apiatid#,
				'standard' => q#Apia, normaltid#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtausommartid#,
				'generic' => q#Aqtautid#,
				'standard' => q#Aqtaunormaltid#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtöbesommartid#,
				'generic' => q#Aqtöbetid#,
				'standard' => q#Aqtöbenormaltid#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#saudiarabisk sommartid#,
				'generic' => q#saudiarabisk tid#,
				'standard' => q#saudiarabisk normaltid#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#östargentinsk sommartid#,
				'generic' => q#östargentinsk tid#,
				'standard' => q#östargentinsk normaltid#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#västargentinsk sommartid#,
				'generic' => q#västargentinsk tid#,
				'standard' => q#västargentinsk normaltid#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armenisk sommartid#,
				'generic' => q#armenisk tid#,
				'standard' => q#armenisk normaltid#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjchabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tjita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tjojbalsan#,
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
		'Asia/Hovd' => {
			exemplarCity => q#Chovd#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtjatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh-staden#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
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
				'daylight' => q#nordamerikansk atlantsommartid#,
				'generic' => q#nordamerikansk atlanttid#,
				'standard' => q#nordamerikansk atlantnormaltid#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorerna#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarieöarna#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Torshamn#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sydgeorgien#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sankt Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#centralaustralisk sommartid#,
				'generic' => q#centralaustralisk tid#,
				'standard' => q#centralaustralisk normaltid#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#västcentralaustralisk sommartid#,
				'generic' => q#västcentralaustralisk tid#,
				'standard' => q#västcentralaustralisk normaltid#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#östaustralisk sommartid#,
				'generic' => q#östaustralisk tid#,
				'standard' => q#östaustralisk normaltid#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#västaustralisk sommartid#,
				'generic' => q#västaustralisk tid#,
				'standard' => q#västaustralisk normaltid#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#azerbajdzjansk sommartid#,
				'generic' => q#azerbajdzjansk tid#,
				'standard' => q#azerbajdzjansk normaltid#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#azorisk sommartid#,
				'generic' => q#azorisk tid#,
				'standard' => q#azorisk normaltid#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladeshisk sommartid#,
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
				'daylight' => q#Brasilia, sommartid#,
				'generic' => q#Brasiliatid#,
				'standard' => q#Brasilia, normaltid#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruneitid#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kap Verde, sommartid#,
				'generic' => q#Kap Verdetid#,
				'standard' => q#Kap Verde, normaltid#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Caseytid#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorrotid#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham, sommartid#,
				'generic' => q#Chathamtid#,
				'standard' => q#Chatham, normaltid#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilensk sommartid#,
				'generic' => q#chilensk tid#,
				'standard' => q#chilensk normaltid#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#kinesisk sommartid#,
				'generic' => q#kinesisk tid#,
				'standard' => q#kinesisk normaltid#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Tjojbalsan, sommartid#,
				'generic' => q#Tjojbalsantid#,
				'standard' => q#Tjojbalsan, normaltid#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Julöns tid#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Keelingöarnas tid#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#colombiansk sommartid#,
				'generic' => q#colombiansk tid#,
				'standard' => q#colombiansk normaltid#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cooköarnas sommartid#,
				'generic' => q#Cooköarnas tid#,
				'standard' => q#Cooköarnas normaltid#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubansk sommartid#,
				'generic' => q#kubansk tid#,
				'standard' => q#kubansk normaltid#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davistid#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont d’Urville-tid#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#östtimorisk tid#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Påskön, sommartid#,
				'generic' => q#Påskötid#,
				'standard' => q#Påskön, normaltid#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ecuadoriansk tid#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinerad universell tid#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#okänd stad#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bryssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen am Hochrhein#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chișinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Köpenhamn#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#irländsk sommartid#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsingfors#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#brittisk sommartid#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
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
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzjhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanen#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warszawa#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizjzja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#centraleuropeisk sommartid#,
				'generic' => q#centraleuropeisk tid#,
				'standard' => q#centraleuropeisk normaltid#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#östeuropeisk sommartid#,
				'generic' => q#östeuropeisk tid#,
				'standard' => q#östeuropeisk normaltid#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningradtid#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#västeuropeisk sommartid#,
				'generic' => q#västeuropeisk tid#,
				'standard' => q#västeuropeisk normaltid#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandsöarna, sommartid#,
				'generic' => q#Falklandsöarnas tid#,
				'standard' => q#Falklandsöarna, normaltid#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji, sommartid#,
				'generic' => q#Fijitid#,
				'standard' => q#Fiji, normaltid#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Franska Guyanatid#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Franska Sydterritoriernas tid#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichtid#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galápagostid#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiertid#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#georgisk sommartid#,
				'generic' => q#georgisk tid#,
				'standard' => q#georgisk normaltid#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Kiribatitid#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#östgrönländsk sommartid#,
				'generic' => q#östgrönländsk tid#,
				'standard' => q#östgrönländsk normaltid#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#västgrönländsk sommartid#,
				'generic' => q#västgrönländsk tid#,
				'standard' => q#västgrönländsk normaltid#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guamtid#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Persiska vikentid#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyanatid#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Honolulu, sommartid#,
				'generic' => q#Honolulutid#,
				'standard' => q#Honolulu, normaltid#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkong, sommartid#,
				'generic' => q#Hongkongtid#,
				'standard' => q#Hongkong, normaltid#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Chovd, sommartid#,
				'generic' => q#Chovdtid#,
				'standard' => q#Chovd, normaltid#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indisk tid#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Julön#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosöarna#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komorerna#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelenöarna#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiverna#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Brittiska Indiska oceanöarnas tid#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indokinesisk tid#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#centralindonesisk tid#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#östindonesisk tid#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#västindonesisk tid#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iransk sommartid#,
				'generic' => q#iransk tid#,
				'standard' => q#iransk normaltid#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk, sommartid#,
				'generic' => q#Irkutsktid#,
				'standard' => q#Irkutsk, normaltid#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israelisk sommartid#,
				'generic' => q#israelisk tid#,
				'standard' => q#israelisk normaltid#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japansk sommartid#,
				'generic' => q#japansk tid#,
				'standard' => q#japansk normaltid#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Kamtjatkasommartid#,
				'generic' => q#Kamtjatkatid#,
				'standard' => q#Kamtjatkanormaltid#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#östkazakstansk tid#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#västkazakstansk tid#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#koreansk sommartid#,
				'generic' => q#koreansk tid#,
				'standard' => q#koreansk normaltid#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraetid#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk, sommartid#,
				'generic' => q#Krasnojarsktid#,
				'standard' => q#Krasnojarsk, normaltid#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgizisk tid#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Sri Lankatid#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Lineöarnas tid#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe, sommartid#,
				'generic' => q#Lord Howetid#,
				'standard' => q#Lord Howe, normaltid#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macaosommartid#,
				'generic' => q#Macaotid#,
				'standard' => q#Macaonormaltid#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarietid#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan, sommartid#,
				'generic' => q#Magadantid#,
				'standard' => q#Magadan, normaltid#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malaysisk tid#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivernatid#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesastid#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshallöarnas tid#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius, sommartid#,
				'generic' => q#Mauritiustid#,
				'standard' => q#Mauritius, normaltid#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsontid#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#nordvästmexikansk sommartid#,
				'generic' => q#nordvästmexikansk tid#,
				'standard' => q#nordvästmexikansk normaltid#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#mexikansk stillahavstid, sommartid#,
				'generic' => q#mexikansk stillahavstid#,
				'standard' => q#mexikansk stillahavstid, normaltid#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar, sommartid#,
				'generic' => q#Ulaanbaatartid#,
				'standard' => q#Ulaanbaatar, normaltid#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva, sommartid#,
				'generic' => q#Moskvatid#,
				'standard' => q#Moskva, normaltid#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#burmesisk tid#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Naurutid#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepalesisk tid#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nya Kaledonien, sommartid#,
				'generic' => q#Nya Kaledonientid#,
				'standard' => q#Nya Kaledonien, normaltid#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#nyzeeländsk sommartid#,
				'generic' => q#nyzeeländsk tid#,
				'standard' => q#nyzeeländsk normaltid#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland, sommartid#,
				'generic' => q#Newfoundlandtid#,
				'standard' => q#Newfoundland, normaltid#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuetid#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolköns sommartid#,
				'generic' => q#Norfolköns tid#,
				'standard' => q#Norfolköns normaltid#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha, sommartid#,
				'generic' => q#Fernando de Noronhatid#,
				'standard' => q#Fernando de Noronha, normaltid#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Nordmarianernas tid#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk, sommartid#,
				'generic' => q#Novosibirsktid#,
				'standard' => q#Novosibirsk, normaltid#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk, sommartid#,
				'generic' => q#Omsktid#,
				'standard' => q#Omsk, normaltid#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Påskön#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambieröarna#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#Honolulusommartid#,
				'generic' => q#Honolulutid#,
				'standard' => q#Honolulunormaltid#,
			},
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnstonatollen#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesasöarna#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midwayöarna#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairnöarna#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallisön#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakistansk sommartid#,
				'generic' => q#pakistansk tid#,
				'standard' => q#pakistansk normaltid#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palautid#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Nya Guineas tid#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguayansk sommartid#,
				'generic' => q#paraguayansk tid#,
				'standard' => q#paraguayansk normaltid#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruansk sommartid#,
				'generic' => q#peruansk tid#,
				'standard' => q#peruansk normaltid#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filippinsk sommartid#,
				'generic' => q#filippinsk tid#,
				'standard' => q#filippinsk normaltid#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Enderburytid#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre-et-Miquelon, sommartid#,
				'generic' => q#Saint-Pierre-et-Miquelon-tid#,
				'standard' => q#Saint-Pierre-et-Miquelon, normaltid#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairntid#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapetid#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyangtid#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylordasommartid#,
				'generic' => q#Qyzylordatid#,
				'standard' => q#Qyzylordanormaltid#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réuniontid#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotheratid#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalin, sommartid#,
				'generic' => q#Sachalintid#,
				'standard' => q#Sachalin, normaltid#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samarasommartid#,
				'generic' => q#Samaratid#,
				'standard' => q#Samaranormaltid#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoansk sommartid#,
				'generic' => q#samoansk tid#,
				'standard' => q#samoansk normaltid#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychellernatid#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singaporetid#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonöarnas tid#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#sydgeorgisk tid#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamtid#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowatid#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahititid#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei, sommartid#,
				'generic' => q#Taipeitid#,
				'standard' => q#Taipei, normaltid#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadzjikistantid#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelautid#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga, sommartid#,
				'generic' => q#Tongatid#,
				'standard' => q#Tonga, normaltid#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuktid#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmensk sommartid#,
				'generic' => q#turkmensk tid#,
				'standard' => q#turkmensk normaltid#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalutid#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayansk sommartid#,
				'generic' => q#uruguayansk tid#,
				'standard' => q#uruguayansk normaltid#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzbekisk sommartid#,
				'generic' => q#uzbekisk tid#,
				'standard' => q#uzbekisk normaltid#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu, sommartid#,
				'generic' => q#Vanuatutid#,
				'standard' => q#Vanuatu, normaltid#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelansk tid#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok, sommartid#,
				'generic' => q#Vladivostoktid#,
				'standard' => q#Vladivostok, normaltid#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd, sommartid#,
				'generic' => q#Volgogradtid#,
				'standard' => q#Volgograd, normaltid#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostoktid#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wakeöarnas tid#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis- och Futunaöarnas tid#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk, sommartid#,
				'generic' => q#Jakutsktid#,
				'standard' => q#Jakutsk, normaltid#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg, sommartid#,
				'generic' => q#Jekaterinburgtid#,
				'standard' => q#Jekaterinburg, normaltid#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukontid#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
