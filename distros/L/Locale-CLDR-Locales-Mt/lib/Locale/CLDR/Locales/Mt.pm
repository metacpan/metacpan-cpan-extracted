=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mt - Package for language Maltese

=cut

package Locale::CLDR::Locales::Mt;
# This file auto generated from Data\common\main\mt.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
 				'en_US' => 'Ingliż Amerikan',
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
 			'UK' => q{UK},
 			'US' => q{US},

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
			main => qr{[a à b ċ d e è f ġ g {għ} h ħ i ì j k l m n o ò p q r s t u ù v w x ż z]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ' ‘ ’ " “ ” ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ċ', 'C', 'D', 'E', 'F', 'Ġ', 'G', '{GĦ}', 'H', 'Ħ', 'I', '{IE*}', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Ż', 'Z'], };
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
	default		=> qq{“},
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
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(karati),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(karati),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} litri kull kilometru),
						'many' => q({0} litri kull kilometru),
						'name' => q(L/km),
						'one' => q({0} litru kull kilometru),
						'other' => q({0} litri kull kilometru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} litri kull kilometru),
						'many' => q({0} litri kull kilometru),
						'name' => q(L/km),
						'one' => q({0} litru kull kilometru),
						'other' => q({0} litri kull kilometru),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} megabytes),
						'many' => q({0} megabytes),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} megabytes),
						'many' => q({0} megabytes),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} terabits),
						'many' => q({0} terabits),
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} terabits),
						'many' => q({0} terabits),
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} terabytes),
						'many' => q({0} terabytes),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} terabytes),
						'many' => q({0} terabytes),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} millisekondi),
						'many' => q({0} millisekondi),
						'name' => q(millisekondi),
						'one' => q({0} millisekonda),
						'other' => q({0} millisekondi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} millisekondi),
						'many' => q({0} millisekondi),
						'name' => q(millisekondi),
						'one' => q({0} millisekonda),
						'other' => q({0} millisekondi),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'name' => q(millisek),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'name' => q(millisek),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
				},
				'short' => {
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} L/km),
						'many' => q({0} L/km),
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} L/km),
						'many' => q({0} L/km),
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(millisek),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(millisek),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, u {1}),
				2 => q({0} u {1}),
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
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
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
				'standard' => {
					'default' => '#,##0.###',
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
		'AED' => {
			symbol => 'AED',
		},
		'AFN' => {
			symbol => 'AFN',
		},
		'ALL' => {
			symbol => 'ALL',
		},
		'AMD' => {
			symbol => 'AMD',
		},
		'ANG' => {
			symbol => 'ANG',
		},
		'AOA' => {
			symbol => 'AOA',
		},
		'ARS' => {
			symbol => 'ARS',
		},
		'AUD' => {
			symbol => 'A$',
		},
		'AWG' => {
			symbol => 'AWG',
		},
		'AZN' => {
			symbol => 'AZN',
		},
		'BAM' => {
			symbol => 'BAM',
		},
		'BBD' => {
			symbol => 'BBD',
		},
		'BDT' => {
			symbol => 'BDT',
		},
		'BGN' => {
			symbol => 'BGN',
		},
		'BHD' => {
			symbol => 'BHD',
		},
		'BIF' => {
			symbol => 'BIF',
		},
		'BMD' => {
			symbol => 'BMD',
		},
		'BND' => {
			symbol => 'BND',
		},
		'BOB' => {
			symbol => 'BOB',
		},
		'BRL' => {
			symbol => 'R$',
		},
		'BSD' => {
			symbol => 'BSD',
		},
		'BTN' => {
			symbol => 'BTN',
		},
		'BWP' => {
			symbol => 'BWP',
		},
		'BYN' => {
			symbol => 'BYN',
		},
		'BYR' => {
			symbol => 'BYR',
		},
		'BZD' => {
			symbol => 'BZD',
		},
		'CDF' => {
			symbol => 'CDF',
		},
		'CHF' => {
			symbol => 'CHF',
		},
		'CLP' => {
			symbol => 'CLP',
		},
		'COP' => {
			symbol => 'COP',
		},
		'CRC' => {
			symbol => 'CRC',
		},
		'CUC' => {
			symbol => 'CUC',
		},
		'CUP' => {
			symbol => 'CUP',
		},
		'CVE' => {
			symbol => 'CVE',
		},
		'CZK' => {
			symbol => 'CZK',
		},
		'DJF' => {
			symbol => 'DJF',
		},
		'DOP' => {
			symbol => 'DOP',
		},
		'DZD' => {
			symbol => 'DZD',
		},
		'EGP' => {
			symbol => 'EGP',
		},
		'ERN' => {
			symbol => 'ERN',
		},
		'ETB' => {
			symbol => 'ETB',
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(ewro),
				'few' => q(ewro),
				'many' => q(ewro),
				'one' => q(ewro),
				'other' => q(ewro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
		},
		'FKP' => {
			symbol => 'FKP',
		},
		'GEL' => {
			symbol => 'GEL',
		},
		'GHS' => {
			symbol => 'GHS',
		},
		'GIP' => {
			symbol => 'GIP',
		},
		'GMD' => {
			symbol => 'GMD',
		},
		'GNF' => {
			symbol => 'GNF',
		},
		'GTQ' => {
			symbol => 'GTQ',
		},
		'GYD' => {
			symbol => 'GYD',
		},
		'HNL' => {
			symbol => 'HNL',
		},
		'HRK' => {
			symbol => 'HRK',
		},
		'HTG' => {
			symbol => 'HTG',
		},
		'HUF' => {
			symbol => 'HUF',
		},
		'IDR' => {
			symbol => 'IDR',
		},
		'ILS' => {
			symbol => '₪',
		},
		'INR' => {
			symbol => '₹',
		},
		'IQD' => {
			symbol => 'IQD',
		},
		'IRR' => {
			symbol => 'IRR',
		},
		'JMD' => {
			symbol => 'JMD',
		},
		'JOD' => {
			symbol => 'JOD',
		},
		'KES' => {
			symbol => 'KES',
		},
		'KGS' => {
			symbol => 'KGS',
		},
		'KHR' => {
			symbol => 'KHR',
		},
		'KMF' => {
			symbol => 'KMF',
		},
		'KPW' => {
			symbol => 'KPW',
		},
		'KRW' => {
			symbol => '₩',
		},
		'KWD' => {
			symbol => 'KWD',
		},
		'KYD' => {
			symbol => 'KYD',
		},
		'KZT' => {
			symbol => 'KZT',
		},
		'LAK' => {
			symbol => 'LAK',
		},
		'LBP' => {
			symbol => 'LBP',
		},
		'LKR' => {
			symbol => 'LKR',
		},
		'LRD' => {
			symbol => 'LRD',
		},
		'LYD' => {
			symbol => 'LYD',
		},
		'MAD' => {
			symbol => 'MAD',
		},
		'MDL' => {
			symbol => 'MDL',
		},
		'MGA' => {
			symbol => 'MGA',
		},
		'MKD' => {
			symbol => 'MKD',
		},
		'MMK' => {
			symbol => 'MMK',
		},
		'MNT' => {
			symbol => 'MNT',
		},
		'MOP' => {
			symbol => 'MOP',
		},
		'MRO' => {
			symbol => 'MRO',
		},
		'MTL' => {
			display_name => {
				'currency' => q(Lira Maltija),
			},
		},
		'MUR' => {
			symbol => 'MUR',
		},
		'MVR' => {
			symbol => 'MVR',
		},
		'MWK' => {
			symbol => 'MWK',
		},
		'MXN' => {
			symbol => 'MX$',
		},
		'MYR' => {
			symbol => 'MYR',
		},
		'MZN' => {
			symbol => 'MZN',
		},
		'NAD' => {
			symbol => 'NAD',
		},
		'NGN' => {
			symbol => 'NGN',
		},
		'NIO' => {
			symbol => 'NIO',
		},
		'NPR' => {
			symbol => 'Rs',
		},
		'NZD' => {
			symbol => 'NZ$',
		},
		'OMR' => {
			symbol => 'OMR',
		},
		'PAB' => {
			symbol => 'PAB',
		},
		'PEN' => {
			symbol => 'PEN',
		},
		'PGK' => {
			symbol => 'PGK',
		},
		'PHP' => {
			symbol => 'PHP',
		},
		'PKR' => {
			symbol => 'PKR',
		},
		'PLN' => {
			symbol => 'PLN',
		},
		'PYG' => {
			symbol => 'PYG',
		},
		'QAR' => {
			symbol => 'QAR',
		},
		'RON' => {
			symbol => 'RON',
		},
		'RSD' => {
			symbol => 'RSD',
		},
		'RUB' => {
			symbol => 'RUB',
		},
		'RWF' => {
			symbol => 'RWF',
		},
		'SAR' => {
			symbol => 'SAR',
		},
		'SBD' => {
			symbol => 'SBD',
		},
		'SCR' => {
			symbol => 'SCR',
		},
		'SDG' => {
			symbol => 'SDG',
		},
		'SEK' => {
			symbol => 'SEK',
		},
		'SGD' => {
			symbol => 'SGD',
		},
		'SHP' => {
			symbol => 'SHP',
		},
		'SLL' => {
			symbol => 'SLL',
		},
		'SOS' => {
			symbol => 'SOS',
		},
		'SRD' => {
			symbol => 'SRD',
		},
		'SSP' => {
			symbol => 'SSP',
		},
		'STD' => {
			symbol => 'STD',
		},
		'STN' => {
			symbol => 'STN',
		},
		'SYP' => {
			symbol => 'SYP',
		},
		'SZL' => {
			symbol => 'SZL',
		},
		'THB' => {
			symbol => 'THB',
		},
		'TJS' => {
			symbol => 'TJS',
		},
		'TMT' => {
			symbol => 'TMT',
		},
		'TND' => {
			symbol => 'TND',
		},
		'TOP' => {
			symbol => 'TOP',
		},
		'TRY' => {
			symbol => 'TRY',
		},
		'TTD' => {
			symbol => 'TTD',
		},
		'TWD' => {
			symbol => 'NT$',
		},
		'TZS' => {
			symbol => 'TZS',
		},
		'UAH' => {
			symbol => 'UAH',
		},
		'UGX' => {
			symbol => 'UGX',
		},
		'USD' => {
			symbol => 'US$',
		},
		'UYU' => {
			symbol => 'UYU',
		},
		'UZS' => {
			symbol => 'UZS',
		},
		'VEF' => {
			symbol => 'VEF',
		},
		'VND' => {
			symbol => '₫',
		},
		'VUV' => {
			symbol => 'VUV',
		},
		'WST' => {
			symbol => 'WST',
		},
		'XAF' => {
			symbol => 'FCFA',
		},
		'XCD' => {
			symbol => 'EC$',
		},
		'XOF' => {
			symbol => 'F CFA',
		},
		'XPF' => {
			symbol => 'CFPF',
		},
		'XXX' => {
			display_name => {
				'currency' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'few' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'many' => q(Munita Mhix Magħrufa jew Mhix Valida),
				'one' => q(Munita mhix magħrufa jew mhix valida),
				'other' => q(Munita Mhix Magħrufa jew Mhix Valida),
			},
		},
		'YER' => {
			symbol => 'YER',
		},
		'ZAR' => {
			symbol => 'ZAR',
		},
		'ZMW' => {
			symbol => 'ZMW',
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
					short => {
						mon => 'Tne',
						tue => 'Tli',
						wed => 'Erb',
						thu => 'Ħam',
						fri => 'Ġim',
						sat => 'Sib',
						sun => 'Ħad'
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
						mon => 'Tn',
						tue => 'Tl',
						wed => 'Er',
						thu => 'Ħm',
						fri => 'Ġm',
						sat => 'Sb',
						sun => 'Ħd'
					},
					short => {
						mon => 'Tne',
						tue => 'Tli',
						wed => 'Erb',
						thu => 'Ħam',
						fri => 'Ġim',
						sat => 'Sib',
						sun => 'Ħad'
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
					wide => {0 => '1el kwart',
						1 => '2ni kwart',
						2 => '3et kwart',
						3 => '4ba’ kwart'
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
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
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
			E => q{ccc},
			Ed => q{d, E},
			Gy => q{G y},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, d 'ta'’ MMM},
			MMMMd => q{d 'ta'’ MMMM},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			y => q{G y},
			yMMMM => q{MMMM y},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG E, dd-MM-y},
			yyyyMMM => q{GGGGG MMM y},
			yyyyMMMEd => q{GGGGG E, dd MMM y},
			yyyyMMMM => q{GGGGG MMMM y},
			yyyyMMMd => q{GGGGG dd MMM y},
			yyyyMd => q{GGGGG dd-MM-y},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d 'ta'’ MMM, y G},
			GyMMMd => q{d MMM, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, M-d},
			MMM => q{LLL},
			MMMEd => q{E, d 'ta'’ MMM},
			MMMMW => q{W 'ġimgħa' 'ta''' MMMM},
			MMMMd => q{d 'ta'’ MMMM},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
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
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
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
				h => q{h–h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
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
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'ta'’ MMM – E, d 'ta'’ MMM},
				d => q{E, d – E d MMM},
			},
			MMMd => {
				M => q{d 'ta'’ MMM – d 'ta'’ MMM},
				d => q{d – d MMM},
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
				h => q{h – h a},
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
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d 'ta'’ MMM – E, d 'ta'’ MMM y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d 'ta'’ MMM y – E, d 'ta'’ MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{d – d MMM y},
				y => q{d MMM, y – d MMM, y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
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
		regionFormat => q(Ħin ta’ {0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} Ħin Standard),
		fallbackFormat => q({1} ({0})),
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#l-Alġier#,
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
			exemplarCity => q#Cairo#,
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
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
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
			exemplarCity => q#Lome#,
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
			exemplarCity => q#Ndjamena#,
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
			exemplarCity => q#Sao Tome#,
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
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
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
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
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
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
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
			exemplarCity => q#il-Gwatemala#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
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
			exemplarCity => q#il-Ġamajka#,
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
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
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
			exemplarCity => q#Mazatlan#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico City#,
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
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad#,
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
			exemplarCity => q#Bejrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasku#,
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
			exemplarCity => q#Dushanbe#,
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
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ġerusalemm#,
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
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#il-Belt tal-Kuwajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
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
			exemplarCity => q#Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosija#,
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
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
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
			exemplarCity => q#Tehran#,
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
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#il-Georgia tan-Nofsinhar#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
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
		'Etc/Unknown' => {
			exemplarCity => q#Belt Mhux Magħruf#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ateni#,
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
			exemplarCity => q#Brussell#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucharest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Ġibiltà#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
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
			exemplarCity => q#Lisbona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#il-Lussemburgu#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Valletta#,
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
			exemplarCity => q#Moska#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariġi#,
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
			exemplarCity => q#Ruma#,
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
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokkolma#,
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
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#il-belt tal-Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vjenna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavja#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
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
			short => {
				'standard' => q#GMT#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#il-Maldivi#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
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
			exemplarCity => q#Marquesas#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
