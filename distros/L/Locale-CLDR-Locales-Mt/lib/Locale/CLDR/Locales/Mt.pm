=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mt - Package for language Maltese

=cut

package Locale::CLDR::Locales::Mt;
# This file auto generated from Data\common\main\mt.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'and-type-a-feminine' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%spellout-cardinal-feminine=),
				},
			},
		},
		'and-type-a-masculine' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%spellout-cardinal-masculine=),
				},
			},
		},
		'and-type-b-feminine' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%%spellout-cardinal-type-b-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%%spellout-cardinal-type-b-feminine=),
				},
			},
		},
		'and-type-b-masculine' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%%spellout-cardinal-type-b-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' u =%%spellout-cardinal-type-b-masculine=),
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
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(żero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(waħda),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(żewġ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tliet),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(erbaʼ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ħames),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sitt),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sebaʼ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tmien),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(disaʼ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(għaxar),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ħdax-il),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tnax-il),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tlettax-il),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(erbatax-il),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ħmistax-il),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sittax-il),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sbatax-il),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(tmintax-il),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dsatax-il),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]għoxrin),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]tletin),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]erbgħin),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]ħamsin),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]sittin),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]sebgħin),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]tmenin),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%spellout-cardinal-feminine→ u ]disgħin),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(mitt),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(mija u →%spellout-cardinal-feminine→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(mitejn[ u →%spellout-cardinal-feminine→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine← mija[→%%and-type-a-feminine→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(elf[→%%and-type-a-feminine→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(elfejn[→%%and-type-a-feminine→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%%thousands← elef[→%%and-type-a-feminine→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← elf[→%%and-type-a-feminine→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljun[→%%and-type-a-feminine→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miljuni[→%%and-type-a-feminine→]),
				},
				'11000000' => {
					base_value => q(11000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← miljun[→%%and-type-a-feminine→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(biljun[→%%and-type-a-feminine→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← biljuni[→%%and-type-a-feminine→]),
				},
				'11000000000' => {
					base_value => q(11000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← biljun[→%%and-type-a-feminine→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(triljun[→%%and-type-a-feminine→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← triljuni[→%%and-type-a-feminine→]),
				},
				'11000000000000' => {
					base_value => q(11000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← triljun[→%%and-type-a-feminine→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(kvadriljun[→%%and-type-a-feminine→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← kvadriljuni[→%%and-type-a-feminine→]),
				},
				'11000000000000000' => {
					base_value => q(11000000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← kvadriljun[→%%and-type-a-feminine→]),
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
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(żero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(wieħed),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(żewġ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tliet),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(erbaʼ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ħames),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sitt),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sebaʼ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tmien),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(disaʼ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(għaxar),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ħdax-il),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tnax-il),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tlettax-il),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(erbatax-il),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ħmistax-il),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sittax-il),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sbatax-il),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(tmintax-il),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dsatax-il),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]għoxrin),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]tletin),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]erbgħin),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]ħamsin),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]sittin),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]sebgħin),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]tmenin),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→ u ]disgħin),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(mitt),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(mija u →%spellout-cardinal-masculine→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(mitejn[ u →%spellout-cardinal-masculine→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine← mija[→%%and-type-a-masculine→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(elf[→%%and-type-a-masculine→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(elfejn[→%%and-type-a-masculine→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%%thousands← elef[→%%and-type-a-masculine→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← elf[→%%and-type-a-masculine→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljun[→%%and-type-a-masculine→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miljuni[→%%and-type-a-masculine→]),
				},
				'11000000' => {
					base_value => q(11000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← miljun[→%%and-type-a-masculine→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(biljun[→%%and-type-a-masculine→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← biljuni[→%%and-type-a-masculine→]),
				},
				'11000000000' => {
					base_value => q(11000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← biljun[→%%and-type-a-masculine→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(triljun[→%%and-type-a-masculine→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← triljuni[→%%and-type-a-masculine→]),
				},
				'11000000000000' => {
					base_value => q(11000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← triljun[→%%and-type-a-masculine→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(kvadriljun[→%%and-type-a-masculine→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← kvadriljuni[→%%and-type-a-masculine→]),
				},
				'11000000000000000' => {
					base_value => q(11000000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← kvadriljun[→%%and-type-a-masculine→]),
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
		'spellout-cardinal-type-b-feminine' => {
			'private' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(żero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(waħda),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tnejn),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tlieta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(erbgħa),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ħamsa),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sitta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sebgħa),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tmienja),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(disgħa),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(għaxra),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ħdax),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tnax),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tlettax),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(erbatax),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ħmistax),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sittax),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sbatax),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(tmintax),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dsatax),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→→ u ]għoxrin),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→→ u ]tletin),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→→ u ]erbgħin),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→→ u ]ħamsin),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→→ u ]sittin),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→→ u ]sebgħin),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→→ u ]tmenin),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→→ u ]disgħin),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(mija[ u →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(mitejn[ u →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine← mija[ u →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(elf[→%%and-type-b-feminine→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(elfejn[→%%and-type-b-feminine→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%%thousands← elef[→%%and-type-b-feminine→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← elf[→%%and-type-b-feminine→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljun[→%%and-type-b-feminine→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miljuni[→%%and-type-b-feminine→]),
				},
				'11000000' => {
					base_value => q(11000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← miljun[→%%and-type-b-feminine→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(biljun[→%%and-type-b-feminine→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← biljuni[→%%and-type-b-feminine→]),
				},
				'11000000000' => {
					base_value => q(11000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← biljun[→%%and-type-b-feminine→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(triljun[→%%and-type-b-feminine→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← triljuni[→%%and-type-b-feminine→]),
				},
				'11000000000000' => {
					base_value => q(11000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← triljun[→%%and-type-b-feminine→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(kvadriljun[→%%and-type-b-feminine→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← kvadriljuni[→%%and-type-b-feminine→]),
				},
				'11000000000000000' => {
					base_value => q(11000000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← kvadriljun[→%%and-type-b-feminine→]),
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
		'spellout-cardinal-type-b-masculine' => {
			'private' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(żero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(wieħed),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tnejn),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tlieta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(erbgħa),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ħamsa),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sitta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sebgħa),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tmienja),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(disgħa),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(għaxra),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ħdax),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tnax),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tlettax),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(erbatax),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ħmistax),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sittax),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sbatax),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(tmintax),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dsatax),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→→ u ]għoxrin),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→→ u ]tletin),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→→ u ]erbgħin),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→→ u ]ħamsin),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→→ u ]sittin),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→→ u ]sebgħin),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→→ u ]tmenin),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→→ u ]disgħin),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(mija[ u →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(mitejn[ u →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine← mija[ u →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(elf[→%%and-type-b-masculine→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(elfejn[→%%and-type-b-masculine→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%%thousands← elef[→%%and-type-b-masculine→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← elf[→%%and-type-b-masculine→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljun[→%%and-type-b-masculine→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miljuni[→%%and-type-b-masculine→]),
				},
				'11000000' => {
					base_value => q(11000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← miljun[→%%and-type-b-masculine→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(biljun[→%%and-type-b-masculine→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← biljuni[→%%and-type-b-masculine→]),
				},
				'11000000000' => {
					base_value => q(11000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← biljun[→%%and-type-b-masculine→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(triljun[→%%and-type-b-masculine→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← triljuni[→%%and-type-b-masculine→]),
				},
				'11000000000000' => {
					base_value => q(11000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← triljun[→%%and-type-b-masculine→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(kvadriljun[→%%and-type-b-masculine→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← kvadriljuni[→%%and-type-b-masculine→]),
				},
				'11000000000000000' => {
					base_value => q(11000000000000000),
					divisor => q(1,000),
					rule => q(←%spellout-cardinal-masculine← kvadriljun[→%%and-type-b-masculine→]),
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
					rule => q(=%%spellout-cardinal-type-b-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-type-b-masculine=),
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
		'thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ERROR-=0=),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tlitt),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(erbat),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ħamest),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sitt),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sebat),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tmint),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(disat),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(għaxart),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(għaxart),
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
				'aa' => 'Afar',
 				'ab' => 'Abkażjan',
 				'ace' => 'Aċiniż',
 				'ach' => 'Akoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'ae' => 'Avestan',
 				'af' => 'Afrikans',
 				'afh' => 'Afriħili',
 				'agq' => 'Aghem',
 				'ain' => 'Ajnu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadjen',
 				'ale' => 'Aleut',
 				'alt' => 'Altai tan-Nofsinhar',
 				'am' => 'Amhariku',
 				'an' => 'Aragoniż',
 				'ang' => 'Ingliż Antik',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Għarbi',
 				'ar_001' => 'Għarbi Standard Modern',
 				'arc' => 'Aramajk',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'arw' => 'Arawak',
 				'as' => 'Assamiż',
 				'asa' => 'Asu',
 				'ast' => 'Asturian',
 				'av' => 'Avarik',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Ażerbajġani',
 				'az@alt=short' => 'Ażeri',
 				'ba' => 'Bashkir',
 				'bal' => 'Baluċi',
 				'ban' => 'Baliniż',
 				'bas' => 'Basa',
 				'be' => 'Belarussu',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgaru',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bengali',
 				'bo' => 'Tibetjan',
 				'br' => 'Breton',
 				'bra' => 'Braj',
 				'brx' => 'Bodo',
 				'bs' => 'Bożnijaku',
 				'bua' => 'Burjat',
 				'bug' => 'Buginese',
 				'byn' => 'Blin',
 				'ca' => 'Katalan',
 				'cad' => 'Kaddo',
 				'car' => 'Karib',
 				'cch' => 'Atsam',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Chagatai',
 				'chk' => 'Ċukiż',
 				'chm' => 'Mari',
 				'chn' => 'Chinook Jargon',
 				'cho' => 'Choctaw',
 				'chp' => 'Ċipewjan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Kurd Ċentrali',
 				'co' => 'Korsiku',
 				'cop' => 'Koptiku',
 				'cr' => 'Cree',
 				'crh' => 'Tork tal-Krimea',
 				'crs' => 'Franċiż tas-Seselwa Creole',
 				'cs' => 'Ċek',
 				'csb' => 'Kashubian',
 				'cu' => 'Slaviku tal-Knisja',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Daniż',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Ġermaniż',
 				'de_AT' => 'Ġermaniż Awstrijak',
 				'de_CH' => 'Ġermaniż Żvizzeru',
 				'del' => 'Delawerjan',
 				'den' => 'Slav',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Sorbjan Komuni',
 				'dua' => 'Dwala',
 				'dum' => 'Olandiż Medjevali',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Eġizzjan (Antik)',
 				'eka' => 'Ekajuk',
 				'el' => 'Grieg',
 				'elx' => 'Elamit',
 				'en' => 'Ingliż',
 				'en_AU' => 'Ingliż Awstraljan',
 				'en_CA' => 'Ingliż Kanadiż',
 				'en_GB' => 'Ingliż Brittaniku',
 				'en_GB@alt=short' => 'Ingliż (UK)',
 				'en_US' => 'Ingliż Amerikan',
 				'en_US@alt=short' => 'Ingliż (US)',
 				'enm' => 'Ingliż Medjevali',
 				'eo' => 'Esperanto',
 				'es' => 'Spanjol',
 				'es_419' => 'Spanjol Latin Amerikan',
 				'es_ES' => 'Spanjol Ewropew',
 				'es_MX' => 'Spanjol tal-Messiku',
 				'et' => 'Estonjan',
 				'eu' => 'Bask',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persjan',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fulah',
 				'fi' => 'Finlandiż',
 				'fil' => 'Filippin',
 				'fj' => 'Fiġjan',
 				'fo' => 'Faroese',
 				'fon' => 'Fon',
 				'fr' => 'Franċiż',
 				'fr_CA' => 'Franċiż Kanadiż',
 				'fr_CH' => 'Franċiż Żvizzeru',
 				'frm' => 'Franċiż Medjevali',
 				'fro' => 'Franċiż Antik',
 				'fur' => 'Frijuljan',
 				'fy' => 'Frisian tal-Punent',
 				'ga' => 'Irlandiż',
 				'gaa' => 'Ga',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gd' => 'Galliku Skoċċiż',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertjan',
 				'gl' => 'Galiċjan',
 				'gmh' => 'Ġermaniż Medjevali Pulit',
 				'gn' => 'Guarani',
 				'goh' => 'Ġermaniż Antik, Pulit',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gotiku',
 				'grb' => 'Grebo',
 				'grc' => 'Grieg, Antik',
 				'gsw' => 'Ġermaniż tal-Iżvizzera',
 				'gu' => 'Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwiċin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Ħawajjan',
 				'he' => 'Ebrajk',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hittite',
 				'hmn' => 'Hmong',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Kroat',
 				'hsb' => 'Sorbjan ta’ Fuq',
 				'ht' => 'Creole ta’ Haiti',
 				'hu' => 'Ungeriż',
 				'hup' => 'Hupa',
 				'hy' => 'Armen',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indoneżjan',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ik' => 'Inupjak',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Iżlandiż',
 				'it' => 'Taljan',
 				'iu' => 'Inuktitut',
 				'ja' => 'Ġappuniż',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Lhudi-Persjan',
 				'jrb' => 'Lhudi-Għarbi',
 				'jv' => 'Ġavaniż',
 				'ka' => 'Ġorġjan',
 				'kaa' => 'Kara-Kalpak',
 				'kab' => 'Kabuljan',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardian',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Cape Verdjan',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kha' => 'Khasi',
 				'kho' => 'Kotaniż',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuju',
 				'kj' => 'Kuanyama',
 				'kk' => 'Każak',
 				'kkj' => 'Kako',
 				'kl' => 'Kalallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Korean',
 				'kok' => 'Konkani',
 				'kos' => 'Kosrejan',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Kareljan',
 				'kru' => 'Kurux',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kolonjan',
 				'ku' => 'Kurd',
 				'kum' => 'Kumyk',
 				'kut' => 'Kutenaj',
 				'kv' => 'Komi',
 				'kw' => 'Korniku',
 				'ky' => 'Kirgiż',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Lussemburgiż',
 				'lez' => 'Leżgjan',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingaljan',
 				'lo' => 'Laosjan',
 				'lol' => 'Mongo',
 				'loz' => 'Lożi',
 				'lrc' => 'Luri tat-Tramuntana',
 				'lt' => 'Litwan',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Luluwa',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Latvjan',
 				'mad' => 'Maduriż',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'man' => 'Mandingo',
 				'mas' => 'Masai',
 				'mdf' => 'Moksha',
 				'mdr' => 'Mandar',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasy',
 				'mga' => 'Irlandiż Medjevali',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Metà',
 				'mh' => 'Marshalljaniż',
 				'mi' => 'Maori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Maċedonjan',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoljan',
 				'mnc' => 'Manchu',
 				'mni' => 'Manipuri',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Malay',
 				'mt' => 'Malti',
 				'mua' => 'Mundang',
 				'mul' => 'Lingwi Diversi',
 				'mus' => 'Kriek',
 				'mwl' => 'Mirandiż',
 				'mwr' => 'Marwari',
 				'my' => 'Burmiż',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Naurujan',
 				'nap' => 'Naplitan',
 				'naq' => 'Nama',
 				'nb' => 'Bokmal Norveġiż',
 				'nd' => 'Ndebeli tat-Tramuntana',
 				'nds' => 'Ġermaniż Komuni',
 				'nds_NL' => 'Sassonu Komuni',
 				'ne' => 'Nepaliż',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nijas',
 				'niu' => 'Niuean',
 				'nl' => 'Olandiż',
 				'nl_BE' => 'Fjamming',
 				'nmg' => 'Kwasio',
 				'nn' => 'Ninorsk Norveġiż',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norveġiż',
 				'nog' => 'Nogai',
 				'non' => 'Nors Antik',
 				'nqo' => 'N’Ko',
 				'nr' => 'Ndebele tan-Nofsinhar',
 				'nso' => 'Soto tat-Tramuntana',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Newari Klassiku',
 				'ny' => 'Nyanja',
 				'nym' => 'Njamweżi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Oċċitan',
 				'oj' => 'Oġibwa',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossettiku',
 				'osa' => 'Osaġjan',
 				'ota' => 'Tork Ottoman',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinjan',
 				'pal' => 'Pahlavi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palawjan',
 				'pcm' => 'Pidgin Niġerjan',
 				'peo' => 'Persjan Antik',
 				'phn' => 'Feniċju',
 				'pi' => 'Pali',
 				'pl' => 'Pollakk',
 				'pon' => 'Ponpejan',
 				'prg' => 'Prussu',
 				'pro' => 'Provenzal Antik',
 				'ps' => 'Pashto',
 				'pt' => 'Portugiż',
 				'pt_BR' => 'Portugiż tal-Brażil',
 				'pt_PT' => 'Portugiż Ewropew',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'raj' => 'Raġastani',
 				'rap' => 'Rapanwi',
 				'rar' => 'Rarotongani',
 				'rm' => 'Romanz',
 				'rn' => 'Rundi',
 				'ro' => 'Rumen',
 				'ro_MD' => 'Moldovan',
 				'rof' => 'Rombo',
 				'rom' => 'Romanesk',
 				'ru' => 'Russu',
 				'rup' => 'Aromanjan',
 				'rw' => 'Kinjarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'sam' => 'Samaritan Aramajk',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinjan',
 				'scn' => 'Sqalli',
 				'sco' => 'Skoċċiż',
 				'sd' => 'Sindhi',
 				'se' => 'Sami tat-Tramuntana',
 				'seh' => 'Sena',
 				'sel' => 'Selkup',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Irlandiż Antik',
 				'sh' => 'Serbo-Kroat',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Sinhala',
 				'sid' => 'Sidamo',
 				'sk' => 'Slovakk',
 				'sl' => 'Sloven',
 				'sm' => 'Samoan',
 				'sma' => 'Sami tan-Nofsinhar',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somali',
 				'sog' => 'Sogdien',
 				'sq' => 'Albaniż',
 				'sr' => 'Serb',
 				'srn' => 'Sranan Tongo',
 				'srr' => 'Serer',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Soto tan-Nofsinhar',
 				'su' => 'Sundaniż',
 				'suk' => 'Sukuma',
 				'sus' => 'Susu',
 				'sux' => 'Sumerjan',
 				'sv' => 'Żvediż',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Swahili tar-Repubblika Demokratika tal-Kongo',
 				'swb' => 'Komorjan',
 				'syr' => 'Sirjan',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetum',
 				'tg' => 'Taġik',
 				'th' => 'Tajlandiż',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmeni',
 				'tkl' => 'Tokelau',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tmh' => 'Tamashek',
 				'tn' => 'Tswana',
 				'to' => 'Tongan',
 				'tog' => 'Nyasa Tonga',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Tork',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tatar',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Taħitjan',
 				'tyv' => 'Tuvinjan',
 				'tzm' => 'Tamazight tal-Atlas Ċentrali',
 				'udm' => 'Udmurt',
 				'ug' => 'Uyghur',
 				'uga' => 'Ugaritiku',
 				'uk' => 'Ukren',
 				'umb' => 'Umbundu',
 				'und' => 'Lingwa Mhix Magħrufa',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Vjetnamiż',
 				'vo' => 'Volapuk',
 				'vot' => 'Votik',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Walamo',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wo' => 'Wolof',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapese',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yue' => 'Kantoniż',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotec',
 				'zen' => 'Zenaga',
 				'zgh' => 'Tamazight Standard tal-Marokk',
 				'zh' => 'Ċiniż',
 				'zh_Hans' => 'Ċiniż Simplifikat',
 				'zh_Hant' => 'Ċiniż Tradizzjonali',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Bla kontenut lingwistiku',
 				'zza' => 'Zaza',

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
			'Arab' => 'Għarbi',
 			'Brai' => 'Braille',
 			'Cyrl' => 'Ċirilliku',
 			'Grek' => 'Grieg',
 			'Hans' => 'Simplifikat',
 			'Hans@alt=stand-alone' => 'Han Simplifikat',
 			'Hant' => 'Tradizzjonali',
 			'Hant@alt=stand-alone' => 'Han Tradizzjonali',
 			'Jpan' => 'Ġappuniż',
 			'Kore' => 'Korean',
 			'Latn' => 'Latin',
 			'Xpeo' => 'Persjan Antik',
 			'Zxxx' => 'Mhux Miktub',
 			'Zyyy' => 'Komuni',
 			'Zzzz' => 'Kitba Mhux Magħrufa',

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
			'001' => 'Dinja',
 			'002' => 'Affrika',
 			'003' => 'Amerika ta’ Fuq',
 			'005' => 'Amerika t’Isfel',
 			'009' => 'Oċejanja',
 			'011' => 'Affrika tal-Punent',
 			'013' => 'Amerika Ċentrali',
 			'014' => 'Affrika tal-Lvant',
 			'015' => 'Affrika ta’ Fuq',
 			'017' => 'Affrika Nofsani',
 			'018' => 'Affrika t’Isfel',
 			'019' => 'Amerika',
 			'021' => 'Amerika Nòrdiku',
 			'029' => 'Karibew',
 			'030' => 'Asja tal-Lvant',
 			'034' => 'Asja t’Isfel Ċentrali',
 			'035' => 'Asja tax-Xlokk',
 			'039' => 'Ewropa t’Isfel',
 			'053' => 'Awstralja u New Zealand',
 			'054' => 'Melanesja',
 			'057' => 'Reġjun ta’ Mikroneżja',
 			'061' => 'Polinesja',
 			'142' => 'Asja',
 			'143' => 'Asja Ċentrali',
 			'145' => 'Asja tal-Punent',
 			'150' => 'Ewropa',
 			'151' => 'Ewropa tal-Lvant',
 			'154' => 'Ewropa ta’ Fuq',
 			'155' => 'Ewropa tal-Punent',
 			'419' => 'Amerika Latina',
 			'AC' => 'Ascension Island',
 			'AD' => 'Andorra',
 			'AE' => 'l-Emirati Għarab Magħquda',
 			'AF' => 'l-Afganistan',
 			'AG' => 'Antigua u Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'l-Albanija',
 			'AM' => 'l-Armenja',
 			'AO' => 'l-Angola',
 			'AQ' => 'l-Antartika',
 			'AR' => 'l-Arġentina',
 			'AS' => 'is-Samoa Amerikana',
 			'AT' => 'l-Awstrija',
 			'AU' => 'l-Awstralja',
 			'AW' => 'Aruba',
 			'AX' => 'il-Gżejjer Aland',
 			'AZ' => 'l-Ażerbajġan',
 			'BA' => 'il-Bożnija-Ħerzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'il-Bangladesh',
 			'BE' => 'il-Belġju',
 			'BF' => 'il-Burkina Faso',
 			'BG' => 'il-Bulgarija',
 			'BH' => 'il-Bahrain',
 			'BI' => 'il-Burundi',
 			'BJ' => 'il-Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'il-Brunei',
 			'BO' => 'il-Bolivja',
 			'BQ' => 'in-Netherlands tal-Karibew',
 			'BR' => 'Il-Brażil',
 			'BS' => 'il-Bahamas',
 			'BT' => 'il-Bhutan',
 			'BV' => 'Gżira Bouvet',
 			'BW' => 'il-Botswana',
 			'BY' => 'il-Belarussja',
 			'BZ' => 'il-Belize',
 			'CA' => 'il-Kanada',
 			'CC' => 'Gżejjer Cocos (Keeling)',
 			'CD' => 'ir-Repubblika Demokratika tal-Kongo',
 			'CD@alt=variant' => 'Kongo (RDK)',
 			'CF' => 'ir-Repubblika Ċentru-Afrikana',
 			'CG' => 'il-Kongo - Brazzaville',
 			'CG@alt=variant' => 'ir-Repubblika tal-Kongo',
 			'CH' => 'l-Iżvizzera',
 			'CI' => 'il-Kosta tal-Avorju',
 			'CK' => 'Gżejjer Cook',
 			'CL' => 'iċ-Ċili',
 			'CM' => 'il-Kamerun',
 			'CN' => 'iċ-Ċina',
 			'CO' => 'il-Kolombja',
 			'CP' => 'il-Gżira Clipperton',
 			'CR' => 'il-Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'il-Gżira Christmas',
 			'CY' => 'Ċipru',
 			'CZ' => 'ir-Repubblika Ċeka',
 			'CZ@alt=variant' => 'Ir-Repubblika Ċeka',
 			'DE' => 'il-Ġermanja',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'il-Djibouti',
 			'DK' => 'id-Danimarka',
 			'DM' => 'Dominica',
 			'DO' => 'ir-Repubblika Dominicana',
 			'DZ' => 'l-Alġerija',
 			'EA' => 'Ceuta u Melilla',
 			'EC' => 'l-Ekwador',
 			'EE' => 'l-Estonja',
 			'EG' => 'l-Eġittu',
 			'EH' => 'is-Saħara tal-Punent',
 			'ER' => 'l-Eritrea',
 			'ES' => 'Spanja',
 			'ET' => 'l-Etjopja',
 			'EU' => 'Unjoni Ewropea',
 			'FI' => 'il-Finlandja',
 			'FJ' => 'Fiġi',
 			'FK' => 'il-Gżejjer Falkland',
 			'FK@alt=variant' => 'Il-Gżejjer Falkland (il-Gżejjer Malvinas)',
 			'FM' => 'il-Mikroneżja',
 			'FO' => 'il-Gżejjer Faeroe',
 			'FR' => 'Franza',
 			'GA' => 'il-Gabon',
 			'GB' => 'ir-Renju Unit',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'il-Georgia',
 			'GF' => 'il-Guyana Franċiża',
 			'GG' => 'Guernsey',
 			'GH' => 'il-Ghana',
 			'GI' => 'Ġibiltà',
 			'GL' => 'Greenland',
 			'GM' => 'il-Gambja',
 			'GN' => 'il-Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'il-Guinea Ekwatorjali',
 			'GR' => 'il-Greċja',
 			'GS' => 'il-Georgia tan-Nofsinhar u l-Gżejjer Sandwich tan-Nofsinhar',
 			'GT' => 'il-Gwatemala',
 			'GU' => 'Guam',
 			'GW' => 'il-Guinea-Bissau',
 			'GY' => 'il-Guyana',
 			'HK' => 'ir-Reġjun Amministrattiv Speċjali ta’ Hong Kong tar-Repubblika tal-Poplu taċ-Ċina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'il-Gżejjer Heard u l-Gżejjer McDonald',
 			'HN' => 'il-Honduras',
 			'HR' => 'il-Kroazja',
 			'HT' => 'il-Haiti',
 			'HU' => 'l-Ungerija',
 			'IC' => 'il-Gżejjer Canary',
 			'ID' => 'l-Indoneżja',
 			'IE' => 'l-Irlanda',
 			'IL' => 'Iżrael',
 			'IM' => 'Isle of Man',
 			'IN' => 'l-Indja',
 			'IO' => 'Territorju Brittaniku tal-Oċean Indjan',
 			'IQ' => 'l-Iraq',
 			'IR' => 'l-Iran',
 			'IS' => 'l-Iżlanda',
 			'IT' => 'l-Italja',
 			'JE' => 'Jersey',
 			'JM' => 'il-Ġamajka',
 			'JO' => 'il-Ġordan',
 			'JP' => 'il-Ġappun',
 			'KE' => 'il-Kenja',
 			'KG' => 'il-Kirgiżistan',
 			'KH' => 'il-Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Saint Kitts u Nevis',
 			'KP' => 'il-Korea ta’ Fuq',
 			'KR' => 'il-Korea t’Isfel',
 			'KW' => 'il-Kuwajt',
 			'KY' => 'il-Gżejjer Cayman',
 			'KZ' => 'il-Każakistan',
 			'LA' => 'il-Laos',
 			'LB' => 'il-Libanu',
 			'LC' => 'Saint Lucia',
 			'LI' => 'il-Liechtenstein',
 			'LK' => 'is-Sri Lanka',
 			'LR' => 'il-Liberja',
 			'LS' => 'il-Lesoto',
 			'LT' => 'il-Litwanja',
 			'LU' => 'il-Lussemburgu',
 			'LV' => 'il-Latvja',
 			'LY' => 'il-Libja',
 			'MA' => 'il-Marokk',
 			'MC' => 'Monaco',
 			'MD' => 'il-Moldova',
 			'ME' => 'il-Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Gżejjer Marshall',
 			'MK' => 'il-Maċedonja ta’ Fuq',
 			'ML' => 'il-Mali',
 			'MM' => 'il-Myanmar/Burma',
 			'MN' => 'il-Mongolja',
 			'MO' => 'ir-Reġjun Amministrattiv Speċjali tal-Macao tar-Repubblika tal-Poplu taċ-Ċina',
 			'MO@alt=short' => 'il-Macao',
 			'MP' => 'Ġżejjer Mariana tat-Tramuntana',
 			'MQ' => 'Martinique',
 			'MR' => 'il-Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'il-Maldivi',
 			'MW' => 'il-Malawi',
 			'MX' => 'il-Messiku',
 			'MY' => 'il-Malasja',
 			'MZ' => 'il-Mozambique',
 			'NA' => 'in-Namibja',
 			'NC' => 'New Caledonia',
 			'NE' => 'in-Niġer',
 			'NF' => 'Gżira Norfolk',
 			'NG' => 'in-Niġerja',
 			'NI' => 'in-Nikaragwa',
 			'NL' => 'in-Netherlands',
 			'NO' => 'in-Norveġja',
 			'NP' => 'in-Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'OM' => 'l-Oman',
 			'PA' => 'il-Panama',
 			'PE' => 'il-Perù',
 			'PF' => 'Polineżja Franċiża',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'il-Filippini',
 			'PK' => 'il-Pakistan',
 			'PL' => 'il-Polonja',
 			'PM' => 'Saint Pierre u Miquelon',
 			'PN' => 'Gżejjer Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'it-Territorji Palestinjani',
 			'PS@alt=short' => 'il-Palestina',
 			'PT' => 'il-Portugall',
 			'PW' => 'Palau',
 			'PY' => 'il-Paragwaj',
 			'QA' => 'il-Qatar',
 			'RE' => 'Réunion',
 			'RO' => 'ir-Rumanija',
 			'RS' => 'is-Serbja',
 			'RU' => 'ir-Russja',
 			'RW' => 'ir-Rwanda',
 			'SA' => 'l-Arabja Sawdija',
 			'SB' => 'il-Gżejjer Solomon',
 			'SC' => 'is-Seychelles',
 			'SD' => 'is-Sudan',
 			'SE' => 'l-Iżvezja',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'is-Slovenja',
 			'SJ' => 'Svalbard u Jan Mayen',
 			'SK' => 'is-Slovakkja',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'is-Senegal',
 			'SO' => 'is-Somalja',
 			'SR' => 'is-Suriname',
 			'SS' => 'is-Sudan t’Isfel',
 			'ST' => 'São Tomé u Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'is-Sirja',
 			'SZ' => 'l-Eswatini',
 			'SZ@alt=variant' => 'is-Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'il-Gżejjer Turks u Caicos',
 			'TD' => 'iċ-Chad',
 			'TF' => 'It-Territorji Franċiżi tan-Nofsinhar',
 			'TG' => 'it-Togo',
 			'TH' => 'it-Tajlandja',
 			'TJ' => 'it-Taġikistan',
 			'TK' => 'it-Tokelau',
 			'TL' => 'Timor Leste',
 			'TL@alt=variant' => 'Timor tal-Lvant',
 			'TM' => 'it-Turkmenistan',
 			'TN' => 'it-Tuneżija',
 			'TO' => 'Tonga',
 			'TR' => 'it-Turkija',
 			'TT' => 'Trinidad u Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'it-Tajwan',
 			'TZ' => 'it-Tanzanija',
 			'UA' => 'l-Ukrajna',
 			'UG' => 'l-Uganda',
 			'UM' => 'Il-Gżejjer Minuri Mbiegħda tal-Istati Uniti',
 			'US' => 'l-Istati Uniti',
 			'US@alt=short' => 'US',
 			'UY' => 'l-Urugwaj',
 			'UZ' => 'l-Użbekistan',
 			'VA' => 'l-Istat tal-Belt tal-Vatikan',
 			'VC' => 'Saint Vincent u l-Grenadini',
 			'VE' => 'il-Venezwela',
 			'VG' => 'il-Gżejjer Verġni Brittaniċi',
 			'VI' => 'il-Gżejjer Verġni tal-Istati Uniti',
 			'VN' => 'il-Vjetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis u Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'il-Kosovo',
 			'YE' => 'il-Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'l-Afrika t’Isfel',
 			'ZM' => 'iż-Żambja',
 			'ZW' => 'iż-Żimbabwe',
 			'ZZ' => 'Reġjun Mhux Magħruf',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'REVISED' => 'Ortografija Irriveda',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalendarju',
 			'collation' => 'Kollazjoni',
 			'currency' => 'Munita',
 			'numbers' => 'Numri',

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
 				'buddhist' => q{Kalendarju Buddist},
 				'chinese' => q{Kalendarju Ċiniż},
 				'dangi' => q{Kalendarju Dangi},
 				'ethiopic' => q{Kalendarju Etjopiku},
 				'gregorian' => q{Kalendarju Gregorjan},
 				'hebrew' => q{Kalendarju Ebrajk},
 				'islamic' => q{Kalendarju Iżlamiku},
 				'islamic-civil' => q{Kalendarju Islamiku-Ċivili},
 				'iso8601' => q{Kalendarju ISO-8601},
 				'japanese' => q{Kalendarju Ġappuniż},
 			},
 			'collation' => {
 				'big5han' => q{Ordni Ċiniż Tradizzjonali (Big5)},
 				'dictionary' => q{Ordni tad-Dizzjunarju},
 				'gb2312han' => q{Ordni Ċiniż Sempliċi (GB2312)},
 				'phonebook' => q{Ordni Telefonika},
 				'pinyin' => q{Ordni tal-Pinjin},
 				'standard' => q{Ordni Standard},
 				'stroke' => q{Ordni Maħżuża},
 				'traditional' => q{Tradizzjonali},
 			},
 			'numbers' => {
 				'latn' => q{Numri tal-Punent},
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
			'metric' => q{Metriku},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingwa: {0}',
 			'script' => 'Skript: {0}',
 			'region' => 'Reġjun: {0}',

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
			auxiliary => qr{[c y]},
			index => ['A', 'B', 'Ċ', 'C', 'D', 'E', 'F', 'Ġ', 'G', '{GĦ}', 'H', 'Ħ', 'I', '{IE*}', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Ż', 'Z'],
			main => qr{[aà b ċ d eè f ġ g {għ} h ħ iì j k l m n oò p q r s t uù v w x ż z]},
			punctuation => qr{[\- ‑ , ; \: ! ? . '‘’ "“” ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ċ', 'C', 'D', 'E', 'F', 'Ġ', 'G', '{GĦ}', 'H', 'Ħ', 'I', '{IE*}', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Ż', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karati),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karati),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} litri kull kilometru),
						'many' => q({0}-il litru kull kilometru),
						'one' => q({0} litru kull kilometru),
						'other' => q({0} litru kull kilometru),
						'two' => q({0} litri kull kilometru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} litri kull kilometru),
						'many' => q({0}-il litru kull kilometru),
						'one' => q({0} litru kull kilometru),
						'other' => q({0} litru kull kilometru),
						'two' => q({0} litri kull kilometru),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} megabytes),
						'many' => q({0}-il megabyte),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
						'two' => q({0} megabytes),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} megabytes),
						'many' => q({0}-il megabyte),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
						'two' => q({0} megabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} terabits),
						'many' => q({0} terabits),
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
						'two' => q({0} terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} terabits),
						'many' => q({0} terabits),
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
						'two' => q({0} terabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} terabytes),
						'many' => q({0} terabytes),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
						'two' => q({0} terabytes),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} terabytes),
						'many' => q({0} terabytes),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
						'two' => q({0} terabytes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} millisekondi),
						'many' => q({0}-il millisekonda),
						'name' => q(millisekondi),
						'one' => q({0} millisekonda),
						'other' => q({0} millisekonda),
						'two' => q({0} millisekondi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} millisekondi),
						'many' => q({0}-il millisekonda),
						'name' => q(millisekondi),
						'one' => q({0} millisekonda),
						'other' => q({0} millisekonda),
						'two' => q({0} millisekondi),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisek),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:iva|i|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:le|l|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, u {1}),
				2 => q({0} u {1}),
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
		'BYN' => {
			symbol => 'р.',
		},
		'EUR' => {
			display_name => {
				'currency' => q(ewro),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Lira Maltija),
			},
		},
		'PHP' => {
			symbol => 'PHP',
		},
		'XXX' => {
			display_name => {
				'currency' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'few' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'many' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'one' => q(Munita mhix magħrufa jew mhix valida),
				'other' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'two' => q(Munita Mhix Magħrufa jew Mhix Valida),
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
							'Jan',
							'Fra',
							'Mar',
							'Apr',
							'Mej',
							'Ġun',
							'Lul',
							'Aww',
							'Set',
							'Ott',
							'Nov',
							'Diċ'
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
							'Ġ',
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
							'Jannar',
							'Frar',
							'Marzu',
							'April',
							'Mejju',
							'Ġunju',
							'Lulju',
							'Awwissu',
							'Settembru',
							'Ottubru',
							'Novembru',
							'Diċembru'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Jn',
							'Fr',
							'Mz',
							'Ap',
							'Mj',
							'Ġn',
							'Lj',
							'Aw',
							'St',
							'Ob',
							'Nv',
							'Dċ'
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
						mon => 'Tne',
						tue => 'Tli',
						wed => 'Erb',
						thu => 'Ħam',
						fri => 'Ġim',
						sat => 'Sib',
						sun => 'Ħad'
					},
					narrow => {
						mon => 'T',
						tue => 'Tl',
						wed => 'Er',
						thu => 'Ħm',
						fri => 'Ġm',
						sat => 'Sb',
						sun => 'Ħd'
					},
					wide => {
						mon => 'It-Tnejn',
						tue => 'It-Tlieta',
						wed => 'L-Erbgħa',
						thu => 'Il-Ħamis',
						fri => 'Il-Ġimgħa',
						sat => 'Is-Sibt',
						sun => 'Il-Ħadd'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Tn',
						tue => 'Tl',
						wed => 'Er',
						thu => 'Ħm',
						fri => 'Ġm',
						sat => 'Sb',
						sun => 'Ħd'
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
					wide => {0 => '1el kwart',
						1 => '2ni kwart',
						2 => '3et kwart',
						3 => '4ba’ kwart'
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
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
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
				'0' => 'QK',
				'1' => 'WK'
			},
			wide => {
				'0' => 'Qabel Kristu',
				'1' => 'Wara Kristu'
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
			'full' => q{EEEE, d 'ta'’ MMMM y G},
			'long' => q{d 'ta'’ MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'ta'’ MMMM y},
			'long' => q{d 'ta'’ MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{dd/MM/y},
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
			MEd => q{E, M/d},
			MMMEd => q{E, d 'ta'’ MMM},
			MMMMd => q{d 'ta'’ MMMM},
			yMMMM => q{MMMM y},
			yyyyMEd => q{GGGGG E, dd-MM-y},
			yyyyMMM => q{GGGGG MMM y},
			yyyyMMMEd => q{GGGGG E, dd MMM y},
			yyyyMMMM => q{GGGGG MMMM y},
			yyyyMMMd => q{GGGGG dd MMM y},
			yyyyMd => q{GGGGG dd-MM-y},
		},
		'gregorian' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d 'ta'’ MMM, y G},
			GyMMMd => q{d MMM, y G},
			MEd => q{E, M-d},
			MMMEd => q{E, d 'ta'’ MMM},
			MMMMW => q{W 'ġimgħa' 'ta''' MMMM},
			MMMMd => q{d 'ta'’ MMMM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d 'ta'’ MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d 'ta'’ MMM, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ - y},
			yQQQQ => q{QQQQ - y},
			yw => q{w 'ġimgħa' 'ta''' Y},
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
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			h => {
				h => q{h–h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
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
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'ta'’ MMM – E, d 'ta'’ MMM},
				d => q{E, d – E d MMM},
			},
			MMMd => {
				M => q{d 'ta'’ MMM – d 'ta'’ MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
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
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d 'ta'’ MMM – E, d 'ta'’ MMM y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d 'ta'’ MMM y – E, d 'ta'’ MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{d – d MMM y},
				y => q{d MMM, y – d MMM, y},
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
		regionFormat => q(Ħin ta’ {0}),
		regionFormat => q({0} Ħin Standard),
		'Africa/Algiers' => {
			exemplarCity => q#l-Alġier#,
		},
		'America/Guatemala' => {
			exemplarCity => q#il-Gwatemala#,
		},
		'America/Jamaica' => {
			exemplarCity => q#il-Ġamajka#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrut#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasku#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ġerusalemm#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#il-Belt tal-Kuwajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosija#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#il-Georgia tan-Nofsinhar#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#Belt Mhux Magħruf#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ateni#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussell#,
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Ġibiltà#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Liżbona#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#il-Lussemburgu#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Valletta#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moska#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariġi#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Ruma#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokkolma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#il-Belt tal-Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vjenna#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavja#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ħin Ċentrali Ewropew tas-Sajf#,
				'generic' => q#Ħin Ċentrali Ewropew#,
				'standard' => q#Ħin Ċentrali Ewropew Standard#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Western' => {
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#il-Maldivi#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
