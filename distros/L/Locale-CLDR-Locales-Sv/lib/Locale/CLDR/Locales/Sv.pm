=encoding utf8

=head1

Locale::CLDR::Locales::Sv - Package for language Swedish

=cut

package Locale::CLDR::Locales::Sv;
# This file auto generated from Data\common\main\sv.xml
#	on Sun  7 Oct 11:00:08 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-neuter','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-reale','spellout-ordinal-neuter','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-reale','digits-ordinal-neuter','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal-reale','digits-ordinal' ]},
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
 				'anp' => 'angika',
 				'ar' => 'arabiska',
 				'ar_001' => 'modern standardarabiska',
 				'arc' => 'arameiska',
 				'arn' => 'mapudungun',
 				'aro' => 'araoniska',
 				'arp' => 'arapaho',
 				'arq' => 'algerisk arabiska',
 				'ars' => 'najdiarabiska',
 				'arw' => 'arawakiska',
 				'ary' => 'marockansk arabiska',
 				'arz' => 'egyptisk arabiska',
 				'as' => 'assamesiska',
 				'asa' => 'asu',
 				'ase' => 'amerikanskt teckenspråk',
 				'ast' => 'asturiska',
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
 				'be' => 'vitryska',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bew' => 'betawiska',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'bagada',
 				'bg' => 'bulgariska',
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
 				'ckb' => 'soranisk kurdiska',
 				'co' => 'korsikanska',
 				'cop' => 'koptiska',
 				'cps' => 'kapisnon',
 				'cr' => 'cree',
 				'crh' => 'krimtatariska',
 				'crs' => 'seychellisk kreol',
 				'cs' => 'tjeckiska',
 				'csb' => 'kasjubiska',
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
 				'he' => 'hebreiska',
 				'hi' => 'hindi',
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
 				'khq' => 'Timbuktu-songhoy',
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
 				'ky' => 'kirgisiska',
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
 				'liv' => 'livoniska',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardiska',
 				'ln' => 'lingala',
 				'lo' => 'laotiska',
 				'lol' => 'mongo',
 				'lou' => 'louisiana-kreol',
 				'loz' => 'lozi',
 				'lrc' => 'nordluri',
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
 				'na' => 'nauriska',
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
 				'pcm' => 'Nigeria-pidgin',
 				'pdc' => 'Pennsylvaniatyska',
 				'pdt' => 'mennonitisk lågtyska',
 				'peo' => 'fornpersiska',
 				'pfl' => 'Pfalz-tyska',
 				'phn' => 'feniciska',
 				'pi' => 'pali',
 				'pl' => 'polska',
 				'pms' => 'piemontesiska',
 				'pnt' => 'pontiska',
 				'pon' => 'pohnpeiska',
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
 				'rif' => 'riffianska',
 				'rm' => 'rätoromanska',
 				'rn' => 'rundi',
 				'ro' => 'rumänska',
 				'ro_MD' => 'moldaviska',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'rot',
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
 				'ses' => 'Gao-songhay',
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
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadzjikiska',
 				'th' => 'thailändska',
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
 				'tpi' => 'tok pisin',
 				'tr' => 'turkiska',
 				'tru' => 'turoyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakodiska',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatariska',
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
 			'Cirt' => 'cirt',
 			'Copt' => 'koptiska',
 			'Cprt' => 'cypriotiska',
 			'Cyrl' => 'kyrilliska',
 			'Cyrs' => 'fornkyrkoslavisk kyrilliska',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'Duployéstenografiska',
 			'Egyd' => 'demotiska',
 			'Egyh' => 'hieratiska',
 			'Egyp' => 'egyptiska hieroglyfer',
 			'Elba' => 'elbasiska',
 			'Ethi' => 'etiopiska',
 			'Geok' => 'kutsuri',
 			'Geor' => 'georgiska',
 			'Glag' => 'glagolitiska',
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
 			'Hans' => 'förenklade',
 			'Hans@alt=stand-alone' => 'förenklade han-tecken',
 			'Hant' => 'traditionella',
 			'Hant@alt=stand-alone' => 'traditionella han-tecken',
 			'Hatr' => 'hatran',
 			'Hebr' => 'hebreiska',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hittitiska hieroglyfer',
 			'Hmng' => 'pahaw mong',
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
 			'Mand' => 'mandaéiska',
 			'Mani' => 'manikeanska',
 			'Marc' => 'marchenska',
 			'Maya' => 'mayahieroglyfer',
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
 			'Rjng' => 'rejang',
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
 			'Wole' => 'woleai',
 			'Xpeo' => 'fornpersiska',
 			'Xsux' => 'sumero-akkadisk kilskrift',
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
 			'021' => 'norra Amerika',
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
 			'202' => '202',
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
 			'BY' => 'Vitryssland',
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
 			'CI@alt=variant' => 'CI',
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
 			'CZ@alt=variant' => 'CZ',
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
 			'EZ' => 'eurozonen',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsöarna',
 			'FK@alt=variant' => 'FK',
 			'FM' => 'Mikronesien',
 			'FO' => 'Färöarna',
 			'FR' => 'Frankrike',
 			'GA' => 'Gabon',
 			'GB' => 'Storbritannien',
 			'GB@alt=short' => 'Storbritannien',
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
 			'HK' => 'Hongkong',
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
 			'MK' => 'Makedonien',
 			'MK@alt=variant' => 'f.d. jugoslaviska republiken Makedonien',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongoliet',
 			'MO' => 'Macao',
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
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- och Caicosöarna',
 			'TD' => 'Tchad',
 			'TF' => 'Franska sydterritorierna',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadzjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Östtimor',
 			'TL@alt=variant' => 'TL',
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
 			'US@alt=short' => 'USA',
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
 			'ALALC97' => '1997 års ALA-LC',
 			'ALUKU' => 'Aluku-dialekt',
 			'AO1990' => 'stavning enligt 1990 års överenskommelse',
 			'AREVELA' => 'östarmeniska',
 			'AREVMDA' => 'västarmeniska',
 			'BAKU1926' => '1926 års stavning',
 			'BALANKA' => 'balanka-dialekt',
 			'BARLA' => 'barlavento-dialekt',
 			'BASICENG' => 'Ogdens basic english',
 			'BAUDDHA' => 'bauddha-dialekt',
 			'BISCAYAN' => 'Biscaya-dialekt',
 			'BISKE' => 'Bila-dialekt',
 			'BOHORIC' => 'Bohorič-alfabetet',
 			'BOONT' => 'boontling',
 			'COLB1945' => 'stavning enligt 1945 års konvention mellan Portugal och Brasilien',
 			'CORNU' => 'kornisk engelska',
 			'DAJNKO' => 'Dajnko-alfabetet',
 			'EKAVSK' => 'ekavisk dialekt',
 			'EMODENG' => 'tidig modern engelska',
 			'FONIPA' => 'internationell fonetisk notation - IPA',
 			'FONUPA' => 'uralisk fonetisk notation',
 			'FONXSAMP' => 'X-SAMPA fonetisk notation',
 			'HEPBURN' => 'Hepburn',
 			'HOGNORSK' => 'högnorsk dialekt',
 			'HSISTEMO' => 'h-system',
 			'IJEKAVSK' => 'ijekavisk dialekt',
 			'ITIHASA' => 'itihasa-dialekt',
 			'JAUER' => 'jauer-dialekt',
 			'JYUTPING' => 'jyutping',
 			'KKCOR' => 'vanlig stavning',
 			'KOCIEWIE' => 'kociewiska',
 			'KSCOR' => 'standardstavning',
 			'LAUKIKA' => 'laukika-dialekt',
 			'LIPAW' => 'Lipovaz-dialekt',
 			'LUNA1918' => '1918 års stavning',
 			'METELKO' => 'Metelko-alfabetet',
 			'MONOTON' => 'monotonisk stavning',
 			'NDYUKA' => 'Ndyuka-dialekt',
 			'NEDIS' => 'natisonsk dialekt',
 			'NEWFOUND' => 'Newfoundland-engelska',
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
 				'metric' => q{SI-enheter},
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
 				'ethi' => q{etiopiska taltecken},
 				'finance' => q{finansiella siffror},
 				'fullwide' => q{fullbreddssiffror},
 				'geor' => q{georgiska taltecken},
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
 				'native' => q{Språkspecifika siffror},
 				'nkoo' => q{n’ko-siffror},
 				'olck' => q{ol chiki-siffror},
 				'orya' => q{oriyiska siffror},
 				'osma' => q{osmanya-siffror},
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
			auxiliary => qr{[á â ã ā ç è ë í î ï ī ñ ó ú ÿ ü æ ø]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Å', 'Ä', 'Ö'],
			main => qr{[a à b c d e é f g h i j k l m n o p q r s t u v w x y z å ä ö]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Å', 'Ä', 'Ö'], };
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
	default		=> qq{”},
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
	default		=> qq{’},
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
					'acre' => {
						'name' => q(engelska tunnland),
						'one' => q({0} engelskt tunnland),
						'other' => q({0} engelska tunnland),
					},
					'acre-foot' => {
						'name' => q(engelska tunnland gånger fot),
						'one' => q({0} engelskt tunnland gånger fot),
						'other' => q({0} engelska tunnland gånger fot),
					},
					'ampere' => {
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					'arc-minute' => {
						'name' => q(bågminuter),
						'one' => q({0} bågminut),
						'other' => q({0} bågminuter),
					},
					'arc-second' => {
						'name' => q(bågsekunder),
						'one' => q({0} bågsekund),
						'other' => q({0} bågsekunder),
					},
					'astronomical-unit' => {
						'name' => q(astronomiska enheter),
						'one' => q({0} astronomisk enhet),
						'other' => q({0} astronomiska enheter),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(skäppor),
						'one' => q({0} skäppa),
						'other' => q({0} skäppor),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(kalorier),
						'one' => q({0} kalori),
						'other' => q({0} kalorier),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(grader Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} grader Celsius),
					},
					'centiliter' => {
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					'centimeter' => {
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					'century' => {
						'name' => q(århundraden),
						'one' => q({0} århundrade),
						'other' => q({0} århundraden),
					},
					'coordinate' => {
						'east' => q({0} öst),
						'north' => q({0} nord),
						'south' => q({0} syd),
						'west' => q({0} väst),
					},
					'cubic-centimeter' => {
						'name' => q(kubikcentimeter),
						'one' => q({0} kubikcentimeter),
						'other' => q({0} kubikcentimeter),
						'per' => q({0} per kubikcentimeter),
					},
					'cubic-foot' => {
						'name' => q(kubikfot),
						'one' => q({0} kubikfot),
						'other' => q({0} kubikfot),
					},
					'cubic-inch' => {
						'name' => q(kubiktum),
						'one' => q({0} kubiktum),
						'other' => q({0} kubiktum),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					'cubic-meter' => {
						'name' => q(kubikmeter),
						'one' => q({0} kubikmeter),
						'other' => q({0} kubikmeter),
						'per' => q({0} per kubikmeter),
					},
					'cubic-mile' => {
						'name' => q(engelska kubikmil),
						'one' => q({0} engelsk kubikmil),
						'other' => q({0} engelska kubikmil),
					},
					'cubic-yard' => {
						'name' => q(engelska kubikyard),
						'one' => q({0} engelsk kubikyard),
						'other' => q({0} engelska kubikyard),
					},
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					'cup-metric' => {
						'name' => q(koppar à 2,5 dl),
						'one' => q({0} kopp à 2,5 dl),
						'other' => q({0} koppar à 2,5 dl),
					},
					'day' => {
						'name' => q(dygn),
						'one' => q({0} dygn),
						'other' => q({0} dygn),
						'per' => q({0} per dygn),
					},
					'deciliter' => {
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					'decimeter' => {
						'name' => q(decimeter),
						'one' => q({0} decimeter),
						'other' => q({0} decimeter),
					},
					'degree' => {
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					'fahrenheit' => {
						'name' => q(grader Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} grader Fahrenheit),
					},
					'fathom' => {
						'name' => q(famnar),
						'one' => q({0} famn),
						'other' => q({0} famnar),
					},
					'fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
					},
					'foodcalorie' => {
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0} per fot),
					},
					'furlong' => {
						'name' => q(engelska plogfårelängder),
						'one' => q({0} engelsk plogfårelängd),
						'other' => q({0} engelska plogfårelängder),
					},
					'g-force' => {
						'name' => q(gånger jordens gravitation),
						'one' => q({0} gånger jordens gravitation),
						'other' => q({0} gånger jordens gravitation),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					'gallon-imperial' => {
						'name' => q(ämbar à 4,6 l),
						'one' => q({0} ämbar à 4,6 l),
						'other' => q({0} ämbar à 4,6 l),
						'per' => q({0} per ämbar à 4,6 l),
					},
					'generic' => {
						'name' => q(grader),
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
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					'hectoliter' => {
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					'hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(hästkrafter),
						'one' => q({0} hästkraft),
						'other' => q({0} hästkrafter),
					},
					'hour' => {
						'name' => q(timmar),
						'one' => q({0} timme),
						'other' => q({0} timmar),
						'per' => q({0} per timme),
					},
					'inch' => {
						'name' => q(tum),
						'one' => q({0} tum),
						'other' => q({0} tum),
						'per' => q({0} per tum),
					},
					'inch-hg' => {
						'name' => q(tum kvicksilver),
						'one' => q({0} tum kvicksilver),
						'other' => q({0} tum kvicksilver),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
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
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
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
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per timme),
						'one' => q({0} kilometer per timme),
						'other' => q({0} kilometer per timme),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowattimmar),
						'one' => q({0} kilowattimme),
						'other' => q({0} kilowattimmar),
					},
					'knot' => {
						'name' => q(knop),
						'one' => q({0} knop),
						'other' => q({0} knop),
					},
					'light-year' => {
						'name' => q(ljusår),
						'one' => q({0} ljusår),
						'other' => q({0} ljusår),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
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
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					'meter-per-second' => {
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					'meter-per-second-squared' => {
						'name' => q(meter per kvadratsekund),
						'one' => q({0} meter per kvadratsekund),
						'other' => q({0} meter per kvadratsekund),
					},
					'metric-ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					'microsecond' => {
						'name' => q(mikrosekunder),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekunder),
					},
					'mile' => {
						'name' => q(engelska mil),
						'one' => q({0} engelsk mil),
						'other' => q({0} engelska mil),
					},
					'mile-per-gallon' => {
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(UK mpg),
						'one' => q({0} UK mil/gn),
						'other' => q({0} UK mil/gn),
					},
					'mile-per-hour' => {
						'name' => q(engelska mil per timme),
						'one' => q({0} engelsk mil per timme),
						'other' => q({0} engelska mil per timme),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
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
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligram per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligram per deciliter),
					},
					'milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeter kvicksilver),
						'one' => q({0} millimeter kvicksilver),
						'other' => q({0} millimeter kvicksilver),
					},
					'millimole-per-liter' => {
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					'millisecond' => {
						'name' => q(millisekunder),
						'one' => q({0} millisekund),
						'other' => q({0} millisekunder),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(minuter),
						'one' => q({0} minut),
						'other' => q({0} minuter),
						'per' => q({0} per minut),
					},
					'month' => {
						'name' => q(månader),
						'one' => q({0} månad),
						'other' => q({0} månader),
						'per' => q({0} per månad),
					},
					'nanometer' => {
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					'nanosecond' => {
						'name' => q(nanosekunder),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekunder),
					},
					'nautical-mile' => {
						'name' => q(nautiska mil),
						'one' => q({0} nautisk mil),
						'other' => q({0} nautiska mil),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(uns),
						'one' => q({0} uns),
						'other' => q({0} uns),
						'per' => q({0} per uns),
					},
					'ounce-troy' => {
						'name' => q(troy uns),
						'one' => q({0} troy uns),
						'other' => q({0} troy uns),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					'part-per-million' => {
						'name' => q(miljondelar),
						'one' => q({0} miljondel),
						'other' => q({0} miljondelar),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(pint à 500 ml),
						'one' => q({0} pint à 500 ml),
						'other' => q({0} pint à 500 ml),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} per pund),
					},
					'pound-per-square-inch' => {
						'name' => q(pund per kvadrattum),
						'one' => q({0} pund per kvadrattum),
						'other' => q({0} pund per kvadrattum),
					},
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					'radian' => {
						'name' => q(radianer),
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					'revolution' => {
						'name' => q(varv),
						'one' => q({0} varv),
						'other' => q({0} varv),
					},
					'second' => {
						'name' => q(sekunder),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} per sekund),
					},
					'square-centimeter' => {
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
						'per' => q({0} per kvadratcentimeter),
					},
					'square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					'square-inch' => {
						'name' => q(kvadrattum),
						'one' => q({0} kvadrattum),
						'other' => q({0} kvadrattum),
						'per' => q({0} per kvadrattum),
					},
					'square-kilometer' => {
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} per kvadratkilometer),
					},
					'square-meter' => {
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
						'per' => q({0} per kvadratmeter),
					},
					'square-mile' => {
						'name' => q(engelska kvadratmil),
						'one' => q({0} engelsk kvadratmil),
						'other' => q({0} engelska kvadratmil),
						'per' => q({0} per engelsk kvadratmil),
					},
					'square-yard' => {
						'name' => q(yard²),
						'one' => q({0} engelsk kvadratyard),
						'other' => q({0} yard²),
					},
					'stone' => {
						'name' => q(engelska stenar),
						'one' => q({0} engelsk sten),
						'other' => q({0} engelska stenar),
					},
					'tablespoon' => {
						'name' => q(matskedar),
						'one' => q({0} matsked),
						'other' => q({0} matskedar),
					},
					'teaspoon' => {
						'name' => q(teskedar),
						'one' => q({0} tesked),
						'other' => q({0} teskedar),
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
						'name' => q(engelska korta ton),
						'one' => q({0} engelskt kort ton),
						'other' => q({0} engelska korta ton),
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
						'name' => q(veckor),
						'one' => q({0} vecka),
						'other' => q({0} veckor),
						'per' => q({0} per vecka),
					},
					'yard' => {
						'name' => q(engelska yard),
						'one' => q({0} engelsk yard),
						'other' => q({0} engelska yard),
					},
					'year' => {
						'name' => q(år),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0} per år),
					},
				},
				'narrow' => {
					'acre' => {
						'name' => q(eng. tunnland),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(eng. t:land·fot),
						'one' => q({0}en.td·fot),
						'other' => q({0}en.td·fot),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					'arc-minute' => {
						'name' => q(bågmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(bågsek),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0}AE),
						'other' => q({0}AE),
					},
					'bit' => {
						'name' => q(b),
						'one' => q({0}b),
						'other' => q({0}b),
					},
					'bushel' => {
						'name' => q(skäppa),
						'one' => q({0} skäppa),
						'other' => q({0} skäppor),
					},
					'byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(årh),
						'one' => q({0}årh),
						'other' => q({0}årh),
					},
					'coordinate' => {
						'east' => q({0}Ö),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(fot³),
						'one' => q({0} fot³),
						'other' => q({0} fot³),
					},
					'cubic-inch' => {
						'name' => q(tum³),
						'one' => q({0} tum³),
						'other' => q({0} tum³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0}m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(eng. mil³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(eng. yard³),
						'one' => q({0} en. yrd³),
						'other' => q({0} en. yrd³),
					},
					'cup' => {
						'name' => q(kp·2,5dL),
						'one' => q({0}kp·2½dL),
						'other' => q({0}kp·2½dL),
					},
					'cup-metric' => {
						'name' => q(kp à 2,5 dl),
						'one' => q({0}kp·2½dl),
						'other' => q({0}kp·2½dl),
					},
					'day' => {
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					'degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(famnar),
						'one' => q({0} famn),
						'other' => q({0} famnar),
					},
					'fluid-ounce' => {
						'name' => q(vätskeuns),
						'one' => q({0} v:euns),
						'other' => q({0} v:euns),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0}/fot),
					},
					'furlong' => {
						'name' => q(eng. plogfårelgd),
						'one' => q({0}en.pfrld),
						'other' => q({0}en.pfrld),
					},
					'g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gallon' => {
						'name' => q(USA vätskegallon),
						'one' => q({0} v:egal:n),
						'other' => q({0} v:egal:n),
						'per' => q({0}/äb·3,8L),
					},
					'gallon-imperial' => {
						'name' => q(ämbar à 4,6L),
						'one' => q({0} äb·4,6L),
						'other' => q({0} äb·4,6L),
						'per' => q({0}/äb·4,6L),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					'horsepower' => {
						'name' => q(hk),
						'one' => q({0}hk),
						'other' => q({0}hk),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(tum),
						'one' => q({0} tum),
						'other' => q({0} tum),
						'per' => q({0}/tum),
					},
					'inch-hg' => {
						'name' => q(tum Hg),
						'one' => q({0} tum Hg),
						'other' => q({0} tum Hg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} krt),
						'other' => q({0} krt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					'knot' => {
						'name' => q(knop),
						'one' => q({0}knop),
						'other' => q({0}knop),
					},
					'light-year' => {
						'name' => q(ljusår),
						'one' => q({0} ljusår),
						'other' => q({0} ljusår),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					'microgram' => {
						'name' => q(μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					'mile' => {
						'name' => q(eng. mil),
						'one' => q({0} mi),
						'other' => q({0}mi),
					},
					'mile-per-gallon' => {
						'name' => q(eng.mil/gallon),
						'one' => q({0}e.mil/gn),
						'other' => q({0}e.mil/gn),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(UK mpg),
						'one' => q({0}UK mpg),
						'other' => q({0}UK mpg),
					},
					'mile-per-hour' => {
						'name' => q(eng. mil/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0}mil),
						'other' => q({0}mil),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0}mm Hg),
						'other' => q({0}mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					'minute' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/mån),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					'nautical-mile' => {
						'name' => q(naut. mil),
						'one' => q({0}M),
						'other' => q({0}M),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					'ounce' => {
						'name' => q(uns),
						'one' => q({0} uns),
						'other' => q({0} uns),
						'per' => q({0}/uns·28g),
					},
					'ounce-troy' => {
						'name' => q(Troy-uns à 31g),
						'one' => q({0} tr.uns),
						'other' => q({0} tr.uns),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(miljondelar),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pint' => {
						'name' => q(USA vätskepint),
						'one' => q({0} v:epint),
						'other' => q({0} v:epint),
					},
					'pint-metric' => {
						'name' => q(pt à 500 ml),
						'one' => q({0}pt·50cL),
						'other' => q({0}pt·50cL),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(s:pund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
						'per' => q({0}/libra·454g),
					},
					'pound-per-square-inch' => {
						'name' => q(s:d/tum²),
						'one' => q({0}s:d/tum²),
						'other' => q({0}s:d/tum²),
					},
					'quart' => {
						'name' => q(USA vätskequart),
						'one' => q({0} v:equart),
						'other' => q({0} v:equart),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					'revolution' => {
						'name' => q(varv),
						'one' => q({0}varv),
						'other' => q({0}varv),
					},
					'second' => {
						'name' => q(sek),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(fot²),
						'one' => q({0} fot²),
						'other' => q({0} fot²),
					},
					'square-inch' => {
						'name' => q(tum²),
						'one' => q({0} tum²),
						'other' => q({0} tum²),
						'per' => q({0}/tum²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(eng. mil²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/en.mil²),
					},
					'square-yard' => {
						'name' => q(eng. yard²),
						'one' => q({0} en. yrd²),
						'other' => q({0} en. yrd²),
					},
					'stone' => {
						'name' => q(eng. sten),
						'one' => q({0} eng. s:n),
						'other' => q({0} eng. s:n),
					},
					'tablespoon' => {
						'name' => q(msk),
						'one' => q({0}msk),
						'other' => q({0}msk),
					},
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0}tsk),
						'other' => q({0}tsk),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					'ton' => {
						'name' => q(eng. k. ton),
						'one' => q({0} en.k.ton),
						'other' => q({0} en.k.ton),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(v),
						'one' => q({0}v),
						'other' => q({0}v),
						'per' => q({0}/v),
					},
					'yard' => {
						'name' => q(engelska yard),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					'year' => {
						'name' => q(år),
						'one' => q({0}å),
						'other' => q({0}å),
						'per' => q({0}/år),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(eng. tunnland),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(eng. t:land·fot),
						'one' => q({0} eng. t:d·fot),
						'other' => q({0} eng. t:d·fot),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(bågminuter),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(bågsekunder),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'bushel' => {
						'name' => q(skäppa),
						'one' => q({0} skäppa),
						'other' => q({0} skäppor),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
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
						'name' => q(årh),
						'one' => q({0} årh),
						'other' => q({0} årh),
					},
					'coordinate' => {
						'east' => q({0} Ö),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(fot³),
						'one' => q({0} fot³),
						'other' => q({0} fot³),
					},
					'cubic-inch' => {
						'name' => q(tum³),
						'one' => q({0} tum³),
						'other' => q({0} tum³),
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
						'name' => q(engelska kubikmil),
						'one' => q({0} eng. mil³),
						'other' => q({0} eng. mil³),
					},
					'cubic-yard' => {
						'name' => q(eng. yard³),
						'one' => q({0} eng. yard³),
						'other' => q({0} eng. yard³),
					},
					'cup' => {
						'name' => q(koppar),
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					'cup-metric' => {
						'name' => q(kp à 2,5 dl),
						'one' => q({0} kp 2,5dl),
						'other' => q({0} kp 2,5dl),
					},
					'day' => {
						'name' => q(dygn),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
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
						'name' => q(grader),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'name' => q(famnar),
						'one' => q({0} famn),
						'other' => q({0} famnar),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0}/fot),
					},
					'furlong' => {
						'name' => q(eng. plogfårelgd),
						'one' => q({0} eng. plogfårelgd),
						'other' => q({0} eng. plogfårelgd),
					},
					'g-force' => {
						'name' => q(G),
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
						'name' => q(ämbar à 4,6 l),
						'one' => q({0} ämb à 4,6l),
						'other' => q({0} ämb à 4,6l),
						'per' => q({0} ämb à 4,6l),
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
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektar),
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
						'name' => q(hästkrafter),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					'hour' => {
						'name' => q(tim),
						'one' => q({0} tim),
						'other' => q({0} tim),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(tum),
						'one' => q({0} tum),
						'other' => q({0} tum),
						'per' => q({0}/tum),
					},
					'inch-hg' => {
						'name' => q(tum Hg),
						'one' => q({0} tum Hg),
						'other' => q({0} tum Hg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} kar),
						'other' => q({0} kar),
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
						'name' => q(knop),
						'one' => q({0} knop),
						'other' => q({0} knop),
					},
					'light-year' => {
						'name' => q(ljusår),
						'one' => q({0} ljusår),
						'other' => q({0} ljusår),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
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
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(eng. mil),
						'one' => q({0} eng. mil),
						'other' => q({0} eng. mil),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(UK mpg),
						'one' => q({0}mpgUK),
						'other' => q({0}mpgUK),
					},
					'mile-per-hour' => {
						'name' => q(eng. mil/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
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
						'name' => q(mån),
						'one' => q({0} mån),
						'other' => q({0} mån),
						'per' => q({0}/mån),
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
						'name' => q(naut. mil),
						'one' => q({0} naut. mil),
						'other' => q({0} naut. mil),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(uns),
						'one' => q({0} uns),
						'other' => q({0} uns),
						'per' => q({0}/uns),
					},
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					'part-per-million' => {
						'name' => q(miljondelar),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(pt à 500 ml),
						'one' => q({0} pt à 500 ml),
						'other' => q({0} pt à 500 ml),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					'radian' => {
						'name' => q(radianer),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(varv),
						'one' => q({0} varv),
						'other' => q({0} varv),
					},
					'second' => {
						'name' => q(sek),
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
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					'square-inch' => {
						'name' => q(tum²),
						'one' => q({0} tum²),
						'other' => q({0} tum²),
						'per' => q({0}/tum²),
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
						'name' => q(engelska kvadratmil),
						'one' => q({0} eng.mil²),
						'other' => q({0} eng.mil²),
						'per' => q({0}/eng. mil²),
					},
					'square-yard' => {
						'name' => q(yard²),
						'one' => q({0} yard²),
						'other' => q({0} yard²),
					},
					'stone' => {
						'name' => q(eng. sten),
						'one' => q({0} eng. sten),
						'other' => q({0} eng. sten),
					},
					'tablespoon' => {
						'name' => q(msk),
						'one' => q({0} msk),
						'other' => q({0} msk),
					},
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
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
						'name' => q(eng. k. ton),
						'one' => q({0} eng. k. ton),
						'other' => q({0} eng. k. ton),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(vkr),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
					},
					'yard' => {
						'name' => q(engelska yard),
						'one' => q({0} eng. yard),
						'other' => q({0} eng. yard),
					},
					'year' => {
						'name' => q(år),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0}/år),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
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
		'arab' => {
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(؜−),
			'nan' => q(¤¤¤),
			'perMille' => q(؉‏),
			'percentSign' => q(٪؜),
			'plusSign' => q(؜+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'decimal' => q(,),
			'exponential' => q(×۱۰^),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‎−‎),
			'nan' => q(¤¤¤),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+‎),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'fullwide' => {
			'timeSeparator' => q(：),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(×10^),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
			'nan' => q(¤¤¤),
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
				'currency' => q(andorransk peseta),
				'one' => q(andorransk peseta),
				'other' => q(andorranska pesetas),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Förenade Arabemiratens dirham),
				'one' => q(Förenade Arabemiratens dirham),
				'other' => q(Förenade Arabemiratens dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
				'one' => q(afghani \(1927–2002\)),
				'other' => q(afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
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
			symbol => 'ALL',
			display_name => {
				'currency' => q(albansk lek),
				'one' => q(albansk lek),
				'other' => q(albanska leke),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(armenisk dram),
				'one' => q(armenisk dram),
				'other' => q(armeniska dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Nederländska Antillernas gulden),
				'one' => q(Nederländska Antillernas gulden),
				'other' => q(Nederländska Antillernas gulden),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'AWG',
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
			symbol => 'AZN',
			display_name => {
				'currency' => q(azerbajdzjansk manat),
				'one' => q(azerbajdzjansk manat),
				'other' => q(azerbajdzjanska manat),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(bosnisk-hercegovinsk dinar \(1992–1994\)),
				'one' => q(bosnisk-hercegovinsk dinar \(1992–1994\)),
				'other' => q(bosnisk-hercegovinska dinarer \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
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
				'currency' => q(Barbados-dollar),
				'one' => q(Barbados-dollar),
				'other' => q(Barbados-dollar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
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
				'other' => q(bulgariska hård lev \(1962–1999\)),
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
			symbol => 'BGN',
			display_name => {
				'currency' => q(bulgarisk lev),
				'one' => q(bulgarisk lev),
				'other' => q(bulgariska leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulgarisk lev \(1881–1952\)),
				'one' => q(bulgarisk lev \(1881–1952\)),
				'other' => q(bulgarisk lev \(1881–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahrainsk dinar),
				'one' => q(bahrainsk dinar),
				'other' => q(bahrainska dinarer),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundisk franc),
				'one' => q(burundisk franc),
				'other' => q(burundiska franc),
			},
		},
		'BMD' => {
			symbol => 'BM$',
			display_name => {
				'currency' => q(Bermuda-dollar),
				'one' => q(Bermuda-dollar),
				'other' => q(Bermuda-dollar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(bruneisk dollar),
				'one' => q(bruneisk dollar),
				'other' => q(bruneiska dollar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
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
			symbol => 'BTN',
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
			symbol => 'BWP',
			display_name => {
				'currency' => q(botswansk pula),
				'one' => q(botswansk pula),
				'other' => q(botswanska pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(vitrysk ny rubel \(1994–1999\)),
				'one' => q(vitrysk rubel \(1994–1999\)),
				'other' => q(vitryska nya rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(vitrysk rubel),
				'one' => q(vitrysk rubel),
				'other' => q(vitryska rubel),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(vitrysk rubel \(2000–2016\)),
				'one' => q(vitrysk rubel \(2000–2016\)),
				'other' => q(vitryska rubel \(2000–2016\)),
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
			symbol => 'CA$',
			display_name => {
				'currency' => q(kanadensisk dollar),
				'one' => q(kanadensisk dollar),
				'other' => q(kanadensiska dollar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
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
			symbol => 'CHF',
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
			symbol => 'CLP',
			display_name => {
				'currency' => q(chilensk peso),
				'one' => q(chilensk peso),
				'other' => q(chilenska pesos),
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
		'CNX' => {
			symbol => 'CNX',
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
			symbol => 'COP',
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
			symbol => 'CRC',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubansk peso \(konvertibel\)),
				'one' => q(kubansk peso \(konvertibel\)),
				'other' => q(kubanska pesos \(konvertibla\)),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubansk peso),
				'one' => q(kubansk peso),
				'other' => q(kubanska pesos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(kapverdisk escudo),
				'one' => q(kapverdisk escudo),
				'other' => q(kapverdiska escudos),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(cypriotiskt pund),
				'one' => q(cypriotiskt pund),
				'other' => q(cypriotiska pund),
			},
		},
		'CZK' => {
			symbol => 'CZK',
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
			symbol => 'DJF',
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
			symbol => 'DZD',
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
			symbol => 'ERN',
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
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiopisk birr),
				'one' => q(etiopisk birr),
				'other' => q(etiopiska birr),
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
				'currency' => q(finsk mark),
				'one' => q(finsk mark),
				'other' => q(finska mark),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fijidollar),
				'one' => q(Fijidollar),
				'other' => q(Fijidollar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Falklandspund),
				'one' => q(Falklandspund),
				'other' => q(Falklandspund),
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
			symbol => 'GEL',
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
			symbol => 'GHS',
			display_name => {
				'currency' => q(ghanansk cedi),
				'one' => q(ghanansk cedi),
				'other' => q(ghananska cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltiskt pund),
				'one' => q(gibraltiskt pund),
				'other' => q(gibraltiska pund),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambisk dalasi),
				'one' => q(gambisk dalasi),
				'other' => q(gambiska dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
			display_name => {
				'currency' => q(Guyanadollar),
				'one' => q(Guyanadollar),
				'other' => q(Guyanadollar),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Hongkongdollar),
				'one' => q(Hongkongdollar),
				'other' => q(Hongkongdollar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
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
			symbol => 'HRK',
			display_name => {
				'currency' => q(kroatisk kuna),
				'one' => q(kroatisk kuna),
				'other' => q(kroatiska kunor),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haitisk gourde),
				'one' => q(haitisk gourde),
				'other' => q(haitiska gourder),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(ungersk forint),
				'one' => q(ungersk forint),
				'other' => q(ungerska forinter),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => '₪',
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
			symbol => 'IQD',
			display_name => {
				'currency' => q(irakisk dinar),
				'one' => q(irakisk dinar),
				'other' => q(irakiska dinarer),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iransk rial),
				'one' => q(iransk rial),
				'other' => q(iranska rial),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
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
			symbol => 'ITL',
			display_name => {
				'currency' => q(italiensk lire),
				'one' => q(italiensk lire),
				'other' => q(italienska lire),
			},
		},
		'JMD' => {
			symbol => 'JM$',
			display_name => {
				'currency' => q(Jamaica-dollar),
				'one' => q(Jamaica-dollar),
				'other' => q(Jamaica-dollar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(kenyansk shilling),
				'one' => q(kenyansk shilling),
				'other' => q(kenyanska shilling),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgizisk som),
				'one' => q(kirgizisk som),
				'other' => q(kirgiziska somer),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambodjansk riel),
				'one' => q(kambodjansk riel),
				'other' => q(kambodjanska riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(komorisk franc),
				'one' => q(komorisk franc),
				'other' => q(komoriska franc),
			},
		},
		'KPW' => {
			symbol => 'KPW',
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
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuwaitisk dinar),
				'one' => q(kuwaitisk dinar),
				'other' => q(kuwaitiska dinarer),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Cayman-dollar),
				'one' => q(Cayman-dollar),
				'other' => q(Cayman-dollar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kazakisk tenge),
				'one' => q(kazakisk tenge),
				'other' => q(kazakiska tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laotisk kip),
				'one' => q(laotisk kip),
				'other' => q(laotiska kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanesiskt pund),
				'one' => q(libanesiskt pund),
				'other' => q(libanesiska pund),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(srilankesisk rupie),
				'one' => q(srilankesisk rupie),
				'other' => q(srilankesiska rupier),
			},
		},
		'LRD' => {
			symbol => 'LRD',
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
			symbol => 'LTL',
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
			symbol => 'LVL',
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
			symbol => 'LYD',
			display_name => {
				'currency' => q(libysk dinar),
				'one' => q(libysk dinar),
				'other' => q(libyska dinarer),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldavisk leu),
				'one' => q(moldavisk leu),
				'other' => q(moldaviska lei),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
			symbol => 'MKD',
			display_name => {
				'currency' => q(makedonisk denar),
				'one' => q(makedonisk denar),
				'other' => q(makedoniska denarer),
			},
		},
		'MKN' => {
			symbol => 'MKN',
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
			symbol => 'MMK',
			display_name => {
				'currency' => q(myanmarisk kyat),
				'one' => q(myanmarisk kyat),
				'other' => q(myanmariska kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongolisk tögrög),
				'one' => q(mongolisk tögrög),
				'other' => q(mongoliska tögrög),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(makanesisk pataca),
				'one' => q(makanesisk pataca),
				'other' => q(makanesiska pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
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
			symbol => 'MTL',
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(mauritisk rupie),
				'one' => q(mauritisk rupie),
				'other' => q(mauritiska rupier),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(maldivisk rupie),
				'one' => q(maldivisk rupie),
				'other' => q(maldiviska rupier),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maldivisk rufiyaa),
				'one' => q(maldivisk rufiyaa),
				'other' => q(maldiviska rufiyer),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(malawisk kwacha),
				'one' => q(malawisk kwacha),
				'other' => q(malawiska kwacha),
			},
		},
		'MXN' => {
			symbol => 'MX$',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(moçambikisk metical),
				'one' => q(moçambikisk metical),
				'other' => q(moçambikiska metical),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namibisk dollar),
				'one' => q(namibisk dollar),
				'other' => q(namibiska dollar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(nigeriansk naira),
				'one' => q(nigeriansk naira),
				'other' => q(nigerianska naira),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(nicaraguansk córdoba \(1998–1991\)),
				'one' => q(nicaraguansk córdoba \(1998–1991\)),
				'other' => q(nicaraguanska córdobas \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
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
			symbol => 'NPR',
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
			symbol => 'OMR',
			display_name => {
				'currency' => q(omansk rial),
				'one' => q(omansk rial),
				'other' => q(omanska rial),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
			symbol => 'PEN',
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
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakistansk rupie),
				'one' => q(pakistansk rupie),
				'other' => q(pakistanska rupier),
			},
		},
		'PLN' => {
			symbol => 'PLN',
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(paraguayansk guarani),
				'one' => q(paraguayansk guarani),
				'other' => q(paraguayska guarani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'RON',
			display_name => {
				'currency' => q(rumänsk leu),
				'one' => q(rumänsk leu),
				'other' => q(rumänska lei),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(serbisk dinar),
				'one' => q(serbisk dinar),
				'other' => q(serbiska dinarer),
			},
		},
		'RUB' => {
			symbol => 'RUB',
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
			symbol => 'RWF',
			display_name => {
				'currency' => q(rwandisk franc),
				'one' => q(rwandisk franc),
				'other' => q(rwandiska franc),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(saudisk riyal),
				'one' => q(saudisk riyal),
				'other' => q(saudiska riyal),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Salomondollar),
				'one' => q(Salomondollar),
				'other' => q(Salomondollar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
			symbol => 'SDG',
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
			symbol => 'SGD',
			display_name => {
				'currency' => q(singaporiansk dollar),
				'one' => q(singaporiansk dollar),
				'other' => q(singaporianska dollar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(S:t Helena-pund),
				'one' => q(S:t Helena-pund),
				'other' => q(S:t Helena-pund),
			},
		},
		'SIT' => {
			symbol => 'SIT',
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(sierraleonsk leone),
				'one' => q(sierraleonsk leone),
				'other' => q(sierraleonska leoner),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(somalisk shilling),
				'one' => q(somalisk shilling),
				'other' => q(somaliska shilling),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(sydsudanesiskt pund),
				'one' => q(sydsudanesiskt pund),
				'other' => q(sydsudanesiska pund),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(saotomeansk dobra \(1977–2017\)),
				'one' => q(saotomeansk dobra \(1977–2017\)),
				'other' => q(saotomeanska dobra \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
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
			symbol => 'SYP',
			display_name => {
				'currency' => q(syriskt pund),
				'one' => q(syriskt pund),
				'other' => q(syriska pund),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(swaziländsk lilangeni),
				'one' => q(swaziländsk lilangeni),
				'other' => q(swaziländska lilangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(thailändsk baht),
				'one' => q(thailändsk baht),
				'other' => q(thailändska baht),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(tadzjikisk rubel),
				'one' => q(tadzjikisk rubel),
				'other' => q(tadzjikiska rubler),
			},
		},
		'TJS' => {
			symbol => 'TJS',
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
			symbol => 'TMT',
			display_name => {
				'currency' => q(turkmenistansk manat),
				'one' => q(turkmenistansk manat),
				'other' => q(turkmenistanska manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tunisisk dinar),
				'one' => q(tunisisk dinar),
				'other' => q(tunisiska dinarer),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(tongansk paʻanga),
				'one' => q(tongansk paʻanga),
				'other' => q(tonganska paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timoriansk escudo),
				'one' => q(östtimoresisk escudo),
				'other' => q(timorianska escudos),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(turkisk lire \(1922–2005\)),
				'one' => q(turkisk lire \(1922–2005\)),
				'other' => q(turkiska lire \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(turkisk lira),
				'one' => q(turkisk lira),
				'other' => q(turkiska lira),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad och Tobago-dollar),
				'one' => q(Trinidad och Tobago-dollar),
				'other' => q(Trinidad och Tobago-dollar),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(Taiwandollar),
				'one' => q(Taiwandollar),
				'other' => q(Taiwandollar),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzanisk shilling),
				'one' => q(tanzanisk shilling),
				'other' => q(tanzaniska shilling),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
			symbol => 'UGX',
			display_name => {
				'currency' => q(ugandisk shilling),
				'one' => q(ugandisk shilling),
				'other' => q(ugandiska shilling),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(US-dollar),
				'one' => q(US-dollar),
				'other' => q(US-dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(US-dollar \(nästa dag\)),
				'one' => q(US-dollar \(nästa dag\)),
				'other' => q(US-dollar \(nästa dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US-dollar \(samma dag\)),
				'one' => q(US-dollar \(samma dag\)),
				'other' => q(US-dollar \(samma dag\)),
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(uruguayansk peso),
				'one' => q(uruguayansk peso),
				'other' => q(uruguayanska pesos),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
			symbol => 'VEF',
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
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatisk vatu),
				'one' => q(vanuatisk vatu),
				'other' => q(vanuatiska vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(västsamoansk tala),
				'one' => q(västsamoansk tala),
				'other' => q(västsamoanska tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
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
				'one' => q(europeisk gammal kompositenhet),
				'other' => q(europeiska kompositenheter),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europeisk monetär enhet),
				'one' => q(europeisk gammal monetär enhet),
				'other' => q(europeiska monetära enheter),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europeisk kontoenhet \(XBC\)),
				'one' => q(europeisk gammal kontoenhet),
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
			symbol => 'EC$',
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
				'one' => q(internationella järnvägsunionens franc),
				'other' => q(internationella järnvägsunionens franc),
			},
		},
		'XOF' => {
			symbol => 'CFA',
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
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP-franc),
				'one' => q(CFP-franc),
				'other' => q(CFP-franc),
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
				'one' => q(RINET-fond),
				'other' => q(RINET-fond),
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
			symbol => 'XTS',
			display_name => {
				'currency' => q(test-valutakod),
				'one' => q(\(valutakod för teständamål\)),
				'other' => q(test-valutakod),
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
			symbol => 'YER',
			display_name => {
				'currency' => q(jemenitisk rial),
				'one' => q(jemenitisk rial),
				'other' => q(jemenitiska rial),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(jugoslavisk dinar \(1966–1990\)),
				'one' => q(jugoslavisk dinar \(1966–1990\)),
				'other' => q(jugoslaviska dinarer \(1966–1990\)),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(jugoslavisk dinar \(1994–2002\)),
				'one' => q(jugoslavisk dinar \(1994–2002\)),
				'other' => q(jugoslaviska dinarer \(1994–2002\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
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
			symbol => 'ZAR',
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
			symbol => 'ZMW',
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
				'one' => q(Zimbabwe-dollar),
				'other' => q(Zimbabwe-dollar),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwe-dollar \(2009\)),
				'one' => q(Zimbabwe-dollar \(2009\)),
				'other' => q(Zimbabwe-dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwe-dollar \(2008\)),
				'one' => q(Zimbabwe-dollar \(2008\)),
				'other' => q(Zimbabwe-dollar \(2008\)),
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
					abbreviated => {
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
					abbreviated => {
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adár II'
						],
					},
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adár II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'Adár II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'Adár II'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
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
					abbreviated => {
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
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'O',
						thu => 'T',
						fri => 'F',
						sat => 'L',
						sun => 'S'
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
					abbreviated => {
						mon => 'mån',
						tue => 'tis',
						wed => 'ons',
						thu => 'tors',
						fri => 'fre',
						sat => 'lör',
						sun => 'sön'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'O',
						thu => 'T',
						fri => 'F',
						sat => 'L',
						sun => 'S'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1:a kvartalet',
						1 => '2:a kvartalet',
						2 => '3:e kvartalet',
						3 => '4:e kvartalet'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
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
				'wide' => {
					'afternoon1' => q{på eftermiddagen},
					'morning2' => q{på förmiddagen},
					'midnight' => q{midnatt},
					'pm' => q{em},
					'am' => q{fm},
					'evening1' => q{på kvällen},
					'night1' => q{på natten},
					'morning1' => q{på morgonen},
				},
				'narrow' => {
					'am' => q{fm},
					'evening1' => q{på kvällen},
					'morning1' => q{på morg.},
					'night1' => q{på natten},
					'morning2' => q{på förm.},
					'afternoon1' => q{på efterm.},
					'midnight' => q{midn.},
					'pm' => q{em},
				},
				'abbreviated' => {
					'afternoon1' => q{på efterm.},
					'morning2' => q{på förm.},
					'midnight' => q{midnatt},
					'pm' => q{em},
					'am' => q{fm},
					'evening1' => q{på kvällen},
					'night1' => q{på natten},
					'morning1' => q{på morg.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'evening1' => q{kväll},
					'am' => q{f.m.},
					'night1' => q{natt},
					'morning1' => q{morgon},
					'midnight' => q{midnatt},
					'afternoon1' => q{efterm.},
					'morning2' => q{förm.},
					'pm' => q{e.m.},
				},
				'wide' => {
					'night1' => q{natt},
					'morning1' => q{morgon},
					'evening1' => q{kväll},
					'am' => q{förmiddag},
					'pm' => q{eftermiddag},
					'midnight' => q{midnatt},
					'afternoon1' => q{eftermiddag},
					'morning2' => q{förmiddag},
				},
				'narrow' => {
					'morning2' => q{förm.},
					'afternoon1' => q{efterm.},
					'midnight' => q{midn.},
					'pm' => q{em},
					'evening1' => q{kväll},
					'am' => q{fm},
					'night1' => q{natt},
					'morning1' => q{morg.},
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
				'0' => 'BE'
			},
			narrow => {
				'0' => 'BE'
			},
			wide => {
				'0' => 'Buddhistisk era'
			},
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
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
			narrow => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			wide => {
				'0' => 'före Kristus',
				'1' => 'efter Kristus'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'Anno Mundi'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'SAKA'
			},
			narrow => {
				'0' => 'SAKA'
			},
			wide => {
				'0' => 'Saka-eran'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'efter Hirja'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tempyō (729–749)',
				'11' => 'Tempyō-kampō (749–749)',
				'12' => 'Tempyō-shōhō (749–757)',
				'13' => 'Tempyō-hōji (757–765)',
				'14' => 'Temphō-jingo (765–767)',
				'15' => 'Jingo-keiun (767–770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781–782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saiko (854–857)',
				'26' => 'Tennan (857–859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Genkei (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kampyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Shōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten-en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Ei-en (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eiho (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kaho (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Shōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110–1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen-ei (1118–1120)',
				'81' => 'Hoan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hoen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Tenyō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hogen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin-an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryuku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken-ei (1206–1207)',
				'113' => 'Shōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Shōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tempuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En-ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun-ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun-ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkei (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkyō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Kareki (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kemmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun-an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenmon (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenwa (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan-en (1748–1751)',
				'216' => 'Hōryaku (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An-ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man-en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			narrow => {
				'0' => 'AP'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'före R.K.',
				'1' => 'R.K.'
			},
			narrow => {
				'0' => 'f.R.K.',
				'1' => 'R.K.'
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
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
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
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{'kl'. HH:mm:ss zzzz},
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
		},
		'coptic' => {
		},
		'dangi' => {
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
			MMMMEd => q{E d MMMM},
			MMMMW => q{'vecka' W 'i' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/M},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{E, y-MM-dd},
			yMM => q{y-MM},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'vecka' w, Y},
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
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/M},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M–d/M},
				d => q{d–d/M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				M => q{y-MM – MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E dd MMM–E dd MMM y},
				d => q{E dd MMM–E dd MMM y},
				y => q{E dd MMM y–E dd MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM–d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y–d MMM y},
			},
			yMd => {
				M => q{y-MM-dd – MM-dd},
				d => q{y-MM-dd – dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'buddhist' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
		},
		'indian' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				m => q{HH:mm–HH:mm v},
			},
		},
		'islamic' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
		},
		'roc' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
		},
		'hebrew' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
		},
		'generic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M–d/M},
				d => q{d–d/M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				M => q{G y-MM – MM},
				y => q{G y-MM – y-MM},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd G},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E dd MMM–E dd MMM y G},
				d => q{E dd MMM–E dd MMM y G},
				y => q{E dd MMM y–E dd MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM–d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y–d MMM y G},
			},
			yMd => {
				M => q{G y-MM-dd – MM-dd},
				d => q{G y-MM-dd – dd},
				y => q{G y-MM-dd – y-MM-dd},
			},
		},
		'persian' => {
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'dangi' => {
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
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
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}tid),
		regionFormat => q({0} (sommartid)),
		regionFormat => q({0} (normaltid)),
		fallbackFormat => q({1} ({0})),
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
			exemplarCity => q#Alger#,
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
			exemplarCity => q#Kairo#,
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
			exemplarCity => q#Dar es-Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Aaiún#,
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
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
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
			exemplarCity => q#Mogadishu#,
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
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
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
			exemplarCity => q#Belém#,
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
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caymanöarna#,
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
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
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
			exemplarCity => q#Eirunepé#,
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
			exemplarCity => q#Guadeloupe#,
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
			exemplarCity => q#Havanna#,
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
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#San Salvador de Jujuy#,
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
			exemplarCity => q#Maceió#,
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
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
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
			exemplarCity => q#Mexiko City#,
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
			exemplarCity => q#Fernando de Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
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
			exemplarCity => q#Puerto Rico#,
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
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#S:t Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#S:t Johns#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#S:t Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#S:t Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#S:t Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#S:t Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
			exemplarCity => q#Anadyr#,
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
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
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
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tjita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tjojbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusjanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Chovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtjatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
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
			exemplarCity => q#Manilla#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
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
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh-staden#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Söul#,
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
			exemplarCity => q#Tasjkent#,
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
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
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
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
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
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sydgeorgien#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#S:t Helena#,
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
				'standard' => q#Koordinerad universell tid#,
			},
			short => {
				'standard' => q#UTC#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#okänd stad#,
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
			exemplarCity => q#Aten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bryssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
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
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#irländsk sommartid#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsingfors#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isle of Man#,
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
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#brittisk sommartid#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
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
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
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
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
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
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanen#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warszawa#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagosöarna#,
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
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
				'daylight' => q#Macausommartid#,
				'generic' => q#Macautid#,
				'standard' => q#Macaunormaltid#,
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
				'standard' => q#Norfolköns tid#,
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
			exemplarCity => q#Påskön#,
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
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambieröarna#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
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
			exemplarCity => q#Marquesasöarna#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midwayöarna#,
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
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairnöarna#,
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
				'daylight' => q#S:t Pierre och Miquelon, sommartid#,
				'generic' => q#S:t Pierre och Miquelontid#,
				'standard' => q#S:t Pierre och Miquelon, normaltid#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
