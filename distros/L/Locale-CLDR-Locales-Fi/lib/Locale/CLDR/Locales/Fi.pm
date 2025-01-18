=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fi - Package for language Finnish

=cut

package Locale::CLDR::Locales::Fi;
# This file auto generated from Data\common\main\fi.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-cardinal-genitive','spellout-cardinal-partitive','spellout-cardinal-essive','spellout-cardinal-translative','spellout-cardinal-inessive','spellout-cardinal-elative','spellout-cardinal-illative','spellout-cardinal-adessive','spellout-cardinal-ablative','spellout-cardinal-allative','spellout-cardinal-plural','spellout-cardinal-genitive-plural','spellout-cardinal-partitive-plural','spellout-cardinal-essive-plural','spellout-cardinal-translative-plural','spellout-cardinal-inessive-plural','spellout-cardinal-elative-plural','spellout-cardinal-illative-plural','spellout-cardinal-adessive-plural','spellout-cardinal-ablative-plural','spellout-cardinal-allative-plural','spellout-ordinal','spellout-ordinal-genitive','spellout-ordinal-partitive','spellout-ordinal-essive','spellout-ordinal-translative','spellout-ordinal-inessive','spellout-ordinal-elative','spellout-ordinal-illative','spellout-ordinal-adessive','spellout-ordinal-ablative','spellout-ordinal-allative','spellout-ordinal-plural','spellout-ordinal-genitive-plural','spellout-ordinal-partitive-plural','spellout-ordinal-essive-plural','spellout-ordinal-translative-plural','spellout-ordinal-inessive-plural','spellout-ordinal-elative-plural','spellout-ordinal-illative-plural','spellout-ordinal-adessive-plural','spellout-ordinal-ablative-plural','spellout-ordinal-allative-plural' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nolla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolme),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemän),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksan),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksän),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenen),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmentä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sata[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sataa[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhat[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhatta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoona[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonaa[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardi[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardia[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoona[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaa[ →→]),
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
		'spellout-cardinal-ablative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollalta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdeltä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdelta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmelta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljältä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viideltä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudelta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemältä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksalta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksältä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeneltä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeneltä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadalta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadalta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannelta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannelta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonalta[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonalta[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardilta[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardilta[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonalta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonalta[ →→]),
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
		'spellout-cardinal-ablative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollilta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksiltä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksilta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmilta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljiltä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisiltä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusilta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemiltä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksilta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksiltä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeniltä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeniltä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadoilta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadoilta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansilta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansilta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonilta[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonilta[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeilta[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeilta[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonilta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonilta[ →→]),
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
		'spellout-cardinal-adessive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollalla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdellä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdella),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmella),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljällä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidellä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudella),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemällä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksalla),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksällä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenellä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenellä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadalla[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadalla[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannella[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannella[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonalla[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonalla[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardilla[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardilla[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonalla[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonalla[ →→]),
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
		'spellout-cardinal-adessive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollilla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksillä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksilla),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmilla),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljillä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisillä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusilla),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemillä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksilla),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksillä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenillä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenillä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadoilla[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadoilla[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansilla­[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansilla[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonilla[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonilla[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeilla[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeilla[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonilla[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonilla[ →→]),
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
		'spellout-cardinal-allative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollalle),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdelle),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdelle),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmelle),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljälle),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidelle),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudelle),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemälle),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksalle),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksälle),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenelle),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenelle[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadalle[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadalle[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannelle[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannelle[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonalle[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonalle[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardille[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardille[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonalle[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonalle[ →→]),
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
		'spellout-cardinal-allative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollille),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksille),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksille),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmille),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljille),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisille),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusille),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemille),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksille),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksille),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenille),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenille[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadoille[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadoille[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansille[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansille[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonille[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonille[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeille[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeille[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonille[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonille[ →→]),
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
		'spellout-cardinal-elative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollasta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdestä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdesta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmesta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljästä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidestä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudesta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemästä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksasta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksästä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenestä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenestä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadasta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadasta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannesta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannesta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonasta[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonasta[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardista[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardista[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonasta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonasta[ →→]),
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
		'spellout-cardinal-elative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollista),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksistä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksista),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmista),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljistä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisistä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusista),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemistä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksista),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksistä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenistä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenistä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadoista[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadoista[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansista[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansista[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonista[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonista[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeista[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeista[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonista[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonista[ →→]),
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
		'spellout-cardinal-essive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollana),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhtenä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahtena),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmena),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viitenä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuutena),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksana),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenenä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenenä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(satana[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­satana[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhantena[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhantena[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonana[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonana[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardina[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardina[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonana[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonana[ →→]),
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
		'spellout-cardinal-essive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollina),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksinä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksina),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmina),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljinä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisinä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusina),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitseminä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksina),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksinä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeninä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeninä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(satoina[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­satoina[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansina[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansina[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonina[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonina[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeina[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeina[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonina[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonina[ →→]),
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
		'spellout-cardinal-genitive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollan),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhden),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahden),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmen),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljän),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viiden),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuuden),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemän),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksan),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksän),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenen),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenen[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadan[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadan[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannen[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannen[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonan[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonan[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardin[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardin[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonan[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonan[ →→]),
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
		'spellout-cardinal-genitive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollien),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksien),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksien),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmien),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljien),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisien),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusien),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemien),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksien),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksien),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenien),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenien[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(satojen[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­satojen[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansien[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansien[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonien[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonien[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardien[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardien[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonien[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonien[ →→]),
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
		'spellout-cardinal-illative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollaan),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhteen),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahteen),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmeen),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljään),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viiteen),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuuteen),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemään),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksaan),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksään),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeneen),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeneen[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sataan[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sataan[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhanteen[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhanteen[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonaan[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonaan[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardiin[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardiin[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaan[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaan[ →→]),
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
		'spellout-cardinal-illative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nolliin),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksiin),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksiin),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmiin),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljiin),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisiin),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusiin),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemiin),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksiin),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksiin),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeniin),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeniin[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(satoihin[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­satoihin[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansiin­[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansiin­[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljooniin[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljooniin[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeihin[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeihin[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljooniin[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljooniin[ →→]),
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
		'spellout-cardinal-inessive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollassa),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdessä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdessa),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmessa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljässä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidessä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudessa),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemässä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksassa),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksässä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenessä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenessä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadassa[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadassa[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannessa[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannessa[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonassa[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonassa[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardissa[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardissa[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonassa[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonassa[ →→]),
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
		'spellout-cardinal-inessive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollissa),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksissä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksissa),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmissa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljissä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisissä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusissa),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemissä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksissa),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksissä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenissä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmenissä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadoissa[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadoissa[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansissa[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansissa[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonissa[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonissa[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeissa[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeissa[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonissa[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonissa[ →→]),
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
		'spellout-cardinal-partitive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollaa),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhtä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmea),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljää),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viittä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuutta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemää),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksaa),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksää),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmentä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmentä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sataa[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sataa[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhatta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhatta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonaa[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonaa[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardia[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardia[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaa[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaa[ →→]),
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
		'spellout-cardinal-partitive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollia),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksiä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksia),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmia),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljiä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisiä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusia),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemiä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksia),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksiä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeniä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeniä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(satoja[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­satoja[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansia[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansia[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonia[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonia[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeja[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeja[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonia[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonia[ →→]),
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
		'spellout-cardinal-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollat),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdet),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdet),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmet),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljät),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidet),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudet),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemät),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksat),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksät),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenet),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←-kymmenet[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadat[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←-sadat[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannet[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhannet[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonat[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardit[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonat[ →→]),
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
		'spellout-cardinal-translative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollaksi),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yhdeksi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdeksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmeksi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljäksi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viideksi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudeksi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemäksi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksaksi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksäksi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeneksi),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeneksi[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadaksi[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadaksi[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhanneksi[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhanneksi[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoonaksi[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljoonaksi[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardiksi[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardiksi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaksi[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoonaksi[ →→]),
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
		'spellout-cardinal-translative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nolliksi),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pilkku →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(yksiksi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kaksiksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmiksi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljiksi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viisiksi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuusiksi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemiksi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksiksi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksiksi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmeniksi),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←­kymmeniksi[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadoiksi[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­sadoiksi[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhansiksi[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­tuhansiksi[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljooniksi[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← miljooniksi[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeiksi[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miljardeiksi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljooniksi[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljooniksi[ →→]),
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
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
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
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollas),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäinen),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toinen),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmas),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljäs),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viides),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudes),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemäs),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksas),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksäs),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenes),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdestoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdestoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-larger←­kymmenes[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadas[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-larger←­sadas[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannes[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-larger←­tuhannes[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonas[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-larger← miljoonas[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardis[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-larger← miljardis[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonas[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-larger← biljoonas[ →→]),
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
		'spellout-ordinal-ablative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannelta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäiseltä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toiselta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannelta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänneltä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidenneltä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennelta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänneltä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannelta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänneltä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenenneltä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdenneltätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdenneltatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-ablative-larger←­kymmenenneltä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannelta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-ablative-larger←­sadannelta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennelta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-ablative-larger←­tuhannennelta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannelta[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-ablative-larger←­miljoonannelta[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnelta[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-ablative-larger←­miljardinnelta[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannelta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-ablative-larger←­biljoonannelta[ →→]),
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
		'spellout-ordinal-ablative-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennelta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-ablative=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-ablative=),
				},
			},
		},
		'spellout-ordinal-ablative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannilta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisiltä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisilta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannilta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänniltä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidenniltä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennilta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänniltä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannilta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänniltä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenenniltä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdenniltätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdenniltatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-ablative-plural-larger←­kymmenenniltä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannilta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-ablative-plural-larger←­sadannilta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennilta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-ablative-plural-larger←­tuhannennilta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannilta[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-ablative-plural-larger←­miljoonannilta[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnilta[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-ablative-plural-larger←­miljardinnilta[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannilta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-ablative-plural-larger←­biljoonannilta[ →→]),
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
		'spellout-ordinal-ablative-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennilta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-ablative-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-ablative-plural=),
				},
			},
		},
		'spellout-ordinal-adessive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannella),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisellä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisella),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannella),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännellä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennellä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennella),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännellä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannella),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännellä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennellä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennellätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennellatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-adessive-larger←­kymmenennellä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannella[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-adessive-larger←­sadannella[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennella[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-adessive-larger←­tuhannennella[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannella[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-adessive-larger←­miljoonannella[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnella[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-adessive-larger←­miljardinnella[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannella[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-adessive-larger←­biljoonannella[ →→]),
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
		'spellout-ordinal-adessive-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennella),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-adessive=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-adessive=),
				},
			},
		},
		'spellout-ordinal-adessive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannilla),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisillä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisilla),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannilla),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännillä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennillä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennilla),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännillä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannilla),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännillä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennillä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennillätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennillatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-adessive-plural-larger←­kymmenennillä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannilla[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-adessive-plural-larger←­sadannilla[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennilla[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-adessive-plural-larger←­tuhannennilla[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannilla[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-adessive-plural-larger←­miljoonannilla[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnilla[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-adessive-plural-larger←­miljardinnilla[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannilla[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-adessive-plural-larger←­biljoonannilla[ →→]),
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
		'spellout-ordinal-adessive-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennilla),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-adessive-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-adessive-plural=),
				},
			},
		},
		'spellout-ordinal-allative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannelle),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäiselle),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toiselle),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannelle),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännelle),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennelle),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennelle),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännelle),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannelle),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännelle),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennelle),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennelletoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennelletoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-allative-larger←­kymmenennelle[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannelle[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-allative-larger←­sadannelle[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennelle[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-allative-larger←­tuhannennelle[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannelle[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-allative-larger←­miljoonannelle[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnelle[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-allative-larger←­miljardinnelle[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannelle[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-allative-larger←­biljoonannelle[ →→]),
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
		'spellout-ordinal-allative-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennelle),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-allative=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-allative=),
				},
			},
		},
		'spellout-ordinal-allative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannille),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisille),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisille),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannille),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännille),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennille),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennille),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännille),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannille),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännille),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennille),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennilletoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennilletoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-allative-plural-larger←­kymmenennille[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannille[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-allative-plural-larger←­sadannille[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennille[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-allative-plural-larger←­tuhannennille[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannille[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-allative-plural-larger←­miljoonannille[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnille[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-allative-plural-larger←­miljardinnille[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannille[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-allative-plural-larger←­biljoonannille[ →→]),
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
		'spellout-ordinal-allative-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennille),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-allative-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-allative-plural=),
				},
			},
		},
		'spellout-ordinal-elative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannesta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisestä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisesta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannesta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännestä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennestä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennesta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännestä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannesta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännestä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennestä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennestätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennestatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-elative-larger←­kymmenennestä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannesta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-elative-larger←­sadannesta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennesta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-elative-larger←­tuhannennesta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannesta[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-elative-larger←­miljoonannesta[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnesta[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-elative-larger←­miljardinnesta[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannesta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-elative-larger←­biljoonannesta[ →→]),
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
		'spellout-ordinal-elative-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennesta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-elative=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-elative=),
				},
			},
		},
		'spellout-ordinal-elative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansista),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisistä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisista),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansista),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsistä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensistä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensista),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsistä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansista),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsistä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensistä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensistätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensistatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-elative-plural-larger←­kymmenensistä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansista[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-elative-plural-larger←­sadansista[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensista[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-elative-plural-larger←­tuhannensista[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansista[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-elative-plural-larger←­miljoonansista[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsista[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-elative-plural-larger←­miljardinsista[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansista[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-elative-plural-larger←­biljoonansista[ →→]),
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
		'spellout-ordinal-elative-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensista),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-elative-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-elative-plural=),
				},
			},
		},
		'spellout-ordinal-essive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollantena),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisenä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisena),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmantena),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljäntenä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidentenä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudentena),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemäntenä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksantena),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksäntenä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenentenä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdentenätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdentenatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-essive-larger←­kymmenentenä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadantena[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-essive-larger←­sadantena[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannentena[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-essive-larger←­tuhannentena[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonantena[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-essive-larger←­miljoonantena[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardintena[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-essive-larger←­miljardintena[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonantena[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-essive-larger←­biljoonantena[ →→]),
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
		'spellout-ordinal-essive-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdentena),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-essive=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-essive=),
				},
			},
		},
		'spellout-ordinal-essive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansina),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisinä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisina),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansina),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsinä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensinä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensina),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsinä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansina),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsinä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensinä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensinätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensinatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-essive-plural-larger←­kymmenensinä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansina[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-essive-plural-larger←­sadansina[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensina[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-essive-plural-larger←­tuhannensina[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansina[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-essive-plural-larger←­miljoonansina[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsina[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-essive-plural-larger←­miljardinsina[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansina[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-essive-plural-larger←­biljoonansina[ →→]),
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
		'spellout-ordinal-essive-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensina),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-essive-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-essive-plural=),
				},
			},
		},
		'spellout-ordinal-genitive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannen),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisen),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisen),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannen),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännen),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennen),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennen),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännen),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannen),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännen),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennen),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennentoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennentoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-genitive-larger←­kymmenennen[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannen[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-genitive-larger←­sadannen[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennen[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-genitive-larger←­tuhannennen[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannen[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-genitive-larger←­miljoonannen[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnen[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-genitive-larger←­miljardinnen[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannen[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-genitive-larger←­biljoonannen[ →→]),
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
		'spellout-ordinal-genitive-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennen),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-genitive=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-genitive=),
				},
			},
		},
		'spellout-ordinal-genitive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansien),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisten),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisten),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansien),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsien),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensien),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensien),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsien),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansien),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsien),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensien),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensientoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensientoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-genitive-plural-larger←­kymmenensien[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansien[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-genitive-plural-larger←­sadansien[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensien[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-genitive-plural-larger←­tuhannensien[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansien[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-genitive-plural-larger←­miljoonansien[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsien[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-genitive-plural-larger←­miljardinsien[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansien[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-genitive-plural-larger←­biljoonansien[ →→]),
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
		'spellout-ordinal-genitive-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensien),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-genitive-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-genitive-plural=),
				},
			},
		},
		'spellout-ordinal-illative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollanteen),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäiseen),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toiseen),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmanteen),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänteen),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidenteen),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudenteen),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänteen),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksanteen),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänteen),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenenteen),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdenteentoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdenteentoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-illative-larger←­kymmenenteen[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadanteen[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-illative-larger←­sadanteen[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannenteen[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-illative-larger←­tuhannenteen[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonanteen[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-illative-larger←­miljoonanteen[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinteen[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-illative-larger←­miljardinteen[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonanteen[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-illative-larger←­biljoonanteen[ →→]),
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
		'spellout-ordinal-illative-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdenteen),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-illative=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-illative=),
				},
			},
		},
		'spellout-ordinal-illative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansiin),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisiin),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisiin),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansiin),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsiin),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensiin),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensiin),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsiin),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansiin),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsiin),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensiin),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensiintoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensiintoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-illative-plural-larger←­kymmenensiin[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansiin[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-illative-plural-larger←­sadansiin[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensiin[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-illative-plural-larger←­tuhannensiin[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansiin[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-illative-plural-larger←­miljoonansiin[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsiin[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-illative-plural-larger←­miljardinsiin[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansiin[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-illative-plural-larger←­biljoonansiin[ →→]),
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
		'spellout-ordinal-illative-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensiin),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-illative-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-illative-plural=),
				},
			},
		},
		'spellout-ordinal-inessive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannessa),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisessä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisessa),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannessa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännessä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennessä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennessa),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännessä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannessa),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännessä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennessä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennessätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennessatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-inessive-larger←­kymmenennessä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannessa[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-inessive-larger←­sadannessa[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennessa[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-inessive-larger←­tuhannennessa[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannessa[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-inessive-larger←­miljoonannessa[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnessa[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-inessive-larger←­miljardinnessa[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannessa[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-inessive-larger←­biljoonannessa[ →→]),
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
		'spellout-ordinal-inessive-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennessa),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-inessive=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-inessive=),
				},
			},
		},
		'spellout-ordinal-inessive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansissa),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisissä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisissa),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansissa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsissä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensissä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensissa),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsissä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansissa),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsissä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensissä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensissätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensissatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-inessive-plural-larger←­kymmenensissä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansissa[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-inessive-plural-larger←­sadansissa[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensissa[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-inessive-plural-larger←­tuhannensissa[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansissa[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-inessive-plural-larger←­miljoonansissa[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsissa[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-inessive-plural-larger←­miljardinsissa[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansissa[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-inessive-plural-larger←­biljoonansissa[ →→]),
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
		'spellout-ordinal-inessive-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensissa),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-inessive-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-inessive-plural=),
				},
			},
		},
		'spellout-ordinal-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdes),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal=),
				},
			},
		},
		'spellout-ordinal-partitive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollatta),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäistä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toista),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmatta),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljättä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidettä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudetta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemättä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksatta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksättä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenettä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdettätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdettatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-partitive-larger←­kymmenettä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadatta[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-partitive-larger←­sadatta[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannetta[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-partitive-larger←­tuhannetta[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonatta[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-partitive-larger←­miljoonatta[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljarditta[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-partitive-larger←­miljarditta[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonatta[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-partitive-larger←­biljoonatta[ →→]),
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
		'spellout-ordinal-partitive-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdetta),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-partitive=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-partitive=),
				},
			},
		},
		'spellout-ordinal-partitive-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansia),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisiä),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisia),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansia),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsiä),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensiä),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensia),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsiä),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansia),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsiä),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensiä),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensiätoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensiatoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-partitive-plural-larger←­kymmenensiä[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansia[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-partitive-plural-larger←­sadansia[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensia[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-partitive-plural-larger←­tuhannensia[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansia[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-partitive-plural-larger←­miljoonansia[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsia[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-partitive-plural-larger←­miljardinsia[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansia[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-partitive-plural-larger←­biljoonansia[ →→]),
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
		'spellout-ordinal-partitive-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensia),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-partitive-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-partitive-plural=),
				},
			},
		},
		'spellout-ordinal-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollannet),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäiset),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toiset),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmannet),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljännet),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidennet),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudennet),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemännet),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksannet),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksännet),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenennet),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdennettoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdennettoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-plural-larger←­kymmenennet[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadannet[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-plural-larger←­sadannet[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannennet[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-plural-larger←­tuhannennet[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonannet[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-plural-larger←­miljoonannet[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinnet[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-plural-larger←­miljardinnet[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonannet[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-plural-larger←­biljoonannet[ →→]),
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
		'spellout-ordinal-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdennet),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-plural=),
				},
			},
		},
		'spellout-ordinal-translative' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollanneksi),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäiseksi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toiseksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmanneksi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänneksi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidenneksi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudenneksi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänneksi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksanneksi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänneksi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenenneksi),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdenneksitoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdenneksitoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-translative-larger←­kymmenenneksi[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadanneksi[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-translative-larger←­sadanneksi[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannenneksi[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-translative-larger←­tuhannenneksi[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonanneksi[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-translative-larger←­miljoonanneksi[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinneksi[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-translative-larger←­miljardinneksi[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonanneksi[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-translative-larger←­biljoonanneksi[ →→]),
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
		'spellout-ordinal-translative-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdenneksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-translative=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-translative=),
				},
			},
		},
		'spellout-ordinal-translative-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(miinus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nollansiksi),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ensimmäisiksi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(toisiksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kolmansiksi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(neljänsiksi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(viidensiksi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(kuudensiksi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seitsemänsiksi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(kahdeksansiksi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(yhdeksänsiksi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kymmenensiksi),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(yhdensiksitoista),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(kahdensiksitoista),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→toista),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-ordinal-translative-plural-larger←­kymmenensiksi[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sadansiksi[­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-ordinal-translative-plural-larger←­sadansiksi[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tuhannensiksi[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-ordinal-translative-plural-larger←­tuhannensiksi[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miljoonansiksi[­→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-ordinal-translative-plural-larger←­miljoonansiksi[­→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miljardinsiksi[­→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-ordinal-translative-plural-larger←­miljardinsiksi[­→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biljoonansiksi[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-ordinal-translative-plural-larger←­biljoonansiksi[ →→]),
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
		'spellout-ordinal-translative-plural-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(kahdensiksi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-translative-plural=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-ordinal-translative-plural=),
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
 				'ab' => 'abhaasi',
 				'ace' => 'atšeh',
 				'ach' => 'atšoli',
 				'ada' => 'adangme',
 				'ady' => 'adyge',
 				'ae' => 'avesta',
 				'aeb' => 'tunisianarabia',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ajp' => 'urduni',
 				'ak' => 'akan',
 				'akk' => 'akkadi',
 				'akz' => 'alabama',
 				'ale' => 'aleutti',
 				'aln' => 'gegi',
 				'alt' => 'altai',
 				'am' => 'amhara',
 				'an' => 'aragonia',
 				'ang' => 'muinaisenglanti',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabia',
 				'ar_001' => 'yleisarabia',
 				'arc' => 'valtakunnanaramea',
 				'arn' => 'mapudungun',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'algerianarabia',
 				'ars' => 'arabia – najd',
 				'arw' => 'arawak',
 				'ary' => 'marokonarabia',
 				'arz' => 'egyptinarabia',
 				'as' => 'assami',
 				'asa' => 'asu',
 				'ase' => 'amerikkalainen viittomakieli',
 				'ast' => 'asturia',
 				'atj' => 'atikamekw',
 				'av' => 'avaari',
 				'avk' => 'kotava',
 				'awa' => 'awadhi',
 				'ay' => 'aimara',
 				'az' => 'azeri',
 				'ba' => 'baškiiri',
 				'bal' => 'belutši',
 				'ban' => 'bali',
 				'bar' => 'baijeri',
 				'bas' => 'basaa',
 				'bax' => 'bamum',
 				'bbc' => 'batak-toba',
 				'bbj' => 'ghomala',
 				'be' => 'valkovenäjä',
 				'bej' => 'bedža',
 				'bem' => 'bemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bfd' => 'fut',
 				'bfq' => 'badaga',
 				'bg' => 'bulgaria',
 				'bgc' => 'haryanvi',
 				'bgn' => 'länsibelutši',
 				'bho' => 'bhodžpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'blo' => 'anii',
 				'blt' => 'tai dam',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tiibet',
 				'bpy' => 'bišnupria',
 				'bqi' => 'bahtiari',
 				'br' => 'bretoni',
 				'bra' => 'bradž',
 				'brh' => 'brahui',
 				'brx' => 'bodo',
 				'bs' => 'bosnia',
 				'bss' => 'koose',
 				'bua' => 'burjaatti',
 				'bug' => 'bugi',
 				'bum' => 'bulu',
 				'byn' => 'bilin',
 				'byv' => 'medumba',
 				'ca' => 'katalaani',
 				'cad' => 'caddo',
 				'car' => 'karibi',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'tšetšeeni',
 				'ceb' => 'cebuano',
 				'cgg' => 'kiga',
 				'ch' => 'tšamorro',
 				'chb' => 'tšibtša',
 				'chg' => 'tšagatai',
 				'chk' => 'chuuk',
 				'chm' => 'mari',
 				'chn' => 'chinook-jargon',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'cic' => 'chickasaw',
 				'ckb' => 'soranî',
 				'ckb@alt=menu' => 'kurdi – soranî',
 				'clc' => 'chilcotin',
 				'co' => 'korsika',
 				'cop' => 'kopti',
 				'cps' => 'capiznon',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'krimintataari',
 				'crh@alt=secondary' => 'kriminturkki',
 				'crj' => 'east cree (eteläinen)',
 				'crk' => 'plains cree',
 				'crl' => 'east cree (pohjoinen)',
 				'crm' => 'moose cree',
 				'crr' => 'pamlico',
 				'crs' => 'seychellienkreoli',
 				'cs' => 'tšekki',
 				'csb' => 'kašubi',
 				'csw' => 'swampy cree',
 				'cu' => 'kirkkoslaavi',
 				'cv' => 'tšuvassi',
 				'cy' => 'kymri',
 				'da' => 'tanska',
 				'dak' => 'dakota',
 				'dar' => 'dargi',
 				'dav' => 'taita',
 				'de' => 'saksa',
 				'de_AT' => 'itävallansaksa',
 				'de_CH' => 'sveitsinyläsaksa',
 				'del' => 'delaware',
 				'den' => 'slevi',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'djerma',
 				'doi' => 'dogri',
 				'dsb' => 'alasorbi',
 				'dtp' => 'dusun',
 				'dua' => 'duala',
 				'dum' => 'keskihollanti',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'djula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egl' => 'emilia',
 				'egy' => 'muinaisegypti',
 				'eka' => 'ekajuk',
 				'el' => 'kreikka',
 				'elx' => 'elami',
 				'en' => 'englanti',
 				'en_AU' => 'australianenglanti',
 				'en_CA' => 'kanadanenglanti',
 				'en_GB' => 'britannianenglanti',
 				'en_GB@alt=short' => 'englanti (Britannia)',
 				'en_US' => 'amerikanenglanti',
 				'en_US@alt=short' => 'englanti (USA)',
 				'enm' => 'keskienglanti',
 				'eo' => 'esperanto',
 				'es' => 'espanja',
 				'es_419' => 'amerikanespanja',
 				'es_ES' => 'euroopanespanja',
 				'es_MX' => 'meksikonespanja',
 				'esu' => 'alaskanjupik',
 				'et' => 'viro',
 				'eu' => 'baski',
 				'ewo' => 'ewondo',
 				'ext' => 'extremadura',
 				'fa' => 'persia',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulani',
 				'fi' => 'suomi',
 				'fil' => 'filipino',
 				'fit' => 'meänkieli',
 				'fj' => 'fidži',
 				'fo' => 'fääri',
 				'fon' => 'fon',
 				'fr' => 'ranska',
 				'fr_CA' => 'kanadanranska',
 				'fr_CH' => 'sveitsinranska',
 				'frc' => 'cajunranska',
 				'frm' => 'keskiranska',
 				'fro' => 'muinaisranska',
 				'frp' => 'arpitaani',
 				'frr' => 'pohjoisfriisi',
 				'frs' => 'itäfriisi',
 				'fur' => 'friuli',
 				'fy' => 'länsifriisi',
 				'ga' => 'iiri',
 				'gaa' => 'ga',
 				'gag' => 'gagauzi',
 				'gan' => 'gan-kiina',
 				'gay' => 'gajo',
 				'gba' => 'gbaja',
 				'gbz' => 'zoroastrialaisdari',
 				'gd' => 'gaeli',
 				'gez' => 'ge’ez',
 				'gil' => 'kiribati',
 				'gl' => 'galicia',
 				'glk' => 'gilaki',
 				'gmh' => 'keskiyläsaksa',
 				'gn' => 'guarani',
 				'goh' => 'muinaisyläsaksa',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gootti',
 				'grb' => 'grebo',
 				'grc' => 'muinaiskreikka',
 				'gsw' => 'sveitsinsaksa',
 				'gu' => 'gudžarati',
 				'guc' => 'wayuu',
 				'gur' => 'frafra',
 				'guz' => 'gusii',
 				'gv' => 'manksi',
 				'gwi' => 'gwitšin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'hakka-kiina',
 				'haw' => 'havaiji',
 				'hax' => 'haida (eteläinen)',
 				'he' => 'heprea',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hif' => 'fidžinhindi',
 				'hil' => 'hiligaino',
 				'hit' => 'heetti',
 				'hmn' => 'hmong',
 				'hnj' => 'hmong njua',
 				'ho' => 'hiri-motu',
 				'hr' => 'kroatia',
 				'hsb' => 'yläsorbi',
 				'hsn' => 'xiang-kiina',
 				'ht' => 'haiti',
 				'hu' => 'unkari',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armenia',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesia',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'sichuanin-yi',
 				'ik' => 'inupiaq',
 				'ikt' => 'Länsi-Kanadan inuktitut',
 				'ilo' => 'iloko',
 				'inh' => 'inguuši',
 				'io' => 'ido',
 				'is' => 'islanti',
 				'it' => 'italia',
 				'iu' => 'inuktitut',
 				'izh' => 'inkeroinen',
 				'ja' => 'japani',
 				'jam' => 'jamaikankreolienglanti',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'juutalaispersia',
 				'jrb' => 'juutalaisarabia',
 				'jut' => 'juutti',
 				'jv' => 'jaava',
 				'ka' => 'georgia',
 				'kaa' => 'karakalpakki',
 				'kab' => 'kabyyli',
 				'kac' => 'katšin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kavi',
 				'kbd' => 'kabardi',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kapverdenkreoli',
 				'ken' => 'kenyang',
 				'kfo' => 'norsunluurannikonkoro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotani',
 				'khq' => 'koyra chiini',
 				'khw' => 'khowar',
 				'ki' => 'kikuju',
 				'kiu' => 'kirmanjki',
 				'kj' => 'kuanjama',
 				'kk' => 'kazakki',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kl@alt=secondary' => 'grönlanti',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'korea',
 				'koi' => 'komipermjakki',
 				'kok' => 'konkani',
 				'kos' => 'kosrae',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karatšai-balkaari',
 				'kri' => 'krio',
 				'krj' => 'kinaray-a',
 				'krl' => 'karjala',
 				'kru' => 'kurukh',
 				'ks' => 'kašmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurdi',
 				'kum' => 'kumykki',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'korni',
 				'kwk' => 'kwakʼwala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirgiisi',
 				'la' => 'latina',
 				'lad' => 'ladino',
 				'lad@alt=secondary' => 'juutalaisespanja',
 				'lag' => 'lango',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburg',
 				'lez' => 'lezgi',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'ganda',
 				'li' => 'limburg',
 				'lij' => 'liguuri',
 				'lil' => 'lillooet',
 				'liv' => 'liivi',
 				'lkt' => 'lakota',
 				'lld' => 'ladin',
 				'lmo' => 'lombardi',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'louisianankreoli',
 				'loz' => 'lozi',
 				'lrc' => 'pohjoisluri',
 				'lsm' => 'samia',
 				'lt' => 'liettua',
 				'ltg' => 'latgalli',
 				'lu' => 'katanganluba',
 				'lua' => 'luluanluba',
 				'lui' => 'luiseño',
 				'lun' => 'lunda',
 				'lus' => 'lusai',
 				'luy' => 'luhya',
 				'lv' => 'latvia',
 				'lzh' => 'klassinen kiina',
 				'lzz' => 'lazi',
 				'mad' => 'madura',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makassar',
 				'man' => 'mandingo',
 				'mas' => 'maasai',
 				'mde' => 'maba',
 				'mdf' => 'mokša',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malagassi',
 				'mga' => 'keski-iiri',
 				'mgh' => 'makua-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshall',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedonia',
 				'ml' => 'malajalam',
 				'mn' => 'mongoli',
 				'mnc' => 'mantšu',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'mrj' => 'vuorimari',
 				'ms' => 'malaiji',
 				'mt' => 'malta',
 				'mua' => 'mundang',
 				'mul' => 'useita kieliä',
 				'mus' => 'creek',
 				'mwl' => 'mirandeesi',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'my' => 'burma',
 				'mye' => 'myene',
 				'myv' => 'ersä',
 				'mzn' => 'mazandarani',
 				'na' => 'nauru',
 				'nan' => 'min nan -kiina',
 				'nap' => 'napoli',
 				'naq' => 'nama',
 				'nb' => 'norjan bokmål',
 				'nd' => 'pohjois-ndebele',
 				'nds' => 'alasaksa',
 				'nds_NL' => 'alankomaidenalasaksa',
 				'ne' => 'nepali',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'njo' => 'ao naga',
 				'nl' => 'hollanti',
 				'nl_BE' => 'flaami',
 				'nmg' => 'kwasio',
 				'nn' => 'norjan nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norja',
 				'nog' => 'nogai',
 				'non' => 'muinaisnorja',
 				'nov' => 'novial',
 				'nqo' => 'n’ko',
 				'nr' => 'etelä-ndebele',
 				'nso' => 'pohjoissotho',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'klassinen newari',
 				'ny' => 'njandža',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitaani',
 				'oj' => 'odžibwa',
 				'ojb' => 'luoteis-odžibwa',
 				'ojc' => 'keskiojibwa',
 				'ojs' => 'oji-cree',
 				'ojw' => 'länsi-odžibwa',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'orija',
 				'os' => 'osseetti',
 				'osa' => 'osage',
 				'ota' => 'osmani',
 				'pa' => 'pandžabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamentu',
 				'pau' => 'palau',
 				'pcd' => 'picardi',
 				'pcm' => 'nigerianpidgin',
 				'pdc' => 'pennsylvaniansaksa',
 				'pdt' => 'plautdietsch',
 				'peo' => 'muinaispersia',
 				'pfl' => 'pfaltsi',
 				'phn' => 'foinikia',
 				'pi' => 'paali',
 				'pis' => 'pijin',
 				'pl' => 'puola',
 				'pms' => 'piemonte',
 				'pnt' => 'pontoksenkreikka',
 				'pon' => 'pohnpei',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'muinaispreussi',
 				'pro' => 'muinaisprovensaali',
 				'ps' => 'paštu',
 				'pt' => 'portugali',
 				'pt_BR' => 'brasilianportugali',
 				'pt_PT' => 'euroopanportugali',
 				'qu' => 'ketšua',
 				'quc' => 'kʼicheʼ',
 				'qug' => 'chimborazonylänköketšua',
 				'raj' => 'radžastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rgn' => 'romagnoli',
 				'rhg' => 'rohinga',
 				'rif' => 'tarifit',
 				'rm' => 'retoromaani',
 				'rn' => 'rundi',
 				'ro' => 'romania',
 				'ro_MD' => 'moldova',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'rtm' => 'rotuma',
 				'ru' => 'venäjä',
 				'rue' => 'ruteeni',
 				'rug' => 'roviana',
 				'rup' => 'aromania',
 				'rw' => 'ruanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakuutti',
 				'sam' => 'samarianaramea',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'saz' => 'sauraštri',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardi',
 				'scn' => 'sisilia',
 				'sco' => 'skotti',
 				'sd' => 'sindhi',
 				'sdc' => 'sassarinsardi',
 				'sdh' => 'eteläkurdi',
 				'se' => 'pohjoissaame',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sei' => 'seri',
 				'sel' => 'selkuppi',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'muinaisiiri',
 				'sgs' => 'samogiitti',
 				'sh' => 'serbokroaatti',
 				'shi' => 'tašelhit',
 				'shn' => 'shan',
 				'shu' => 'tšadinarabia',
 				'si' => 'sinhala',
 				'sid' => 'sidamo',
 				'sk' => 'slovakki',
 				'skr' => 'saraiki',
 				'sl' => 'sloveeni',
 				'slh' => 'lushootseed (eteläinen)',
 				'sli' => 'sleesiansaksa',
 				'sly' => 'selayar',
 				'sm' => 'samoa',
 				'sma' => 'eteläsaame',
 				'smj' => 'luulajansaame',
 				'smn' => 'inarinsaame',
 				'sms' => 'koltansaame',
 				'sn' => 'šona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdi',
 				'sq' => 'albania',
 				'sr' => 'serbia',
 				'srn' => 'sranan',
 				'srr' => 'serer',
 				'ss' => 'swazi',
 				'ssy' => 'saho',
 				'st' => 'eteläsotho',
 				'stq' => 'saterlandinfriisi',
 				'str' => 'straits-salish',
 				'su' => 'sunda',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeri',
 				'sv' => 'ruotsi',
 				'sw' => 'swahili',
 				'sw_CD' => 'kongonswahili',
 				'swb' => 'komori',
 				'syc' => 'muinaissyyria',
 				'syr' => 'syyria',
 				'szl' => 'sleesia',
 				'ta' => 'tamili',
 				'tce' => 'etelätutchone',
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadžikki',
 				'tgx' => 'tagish',
 				'th' => 'thai',
 				'tht' => 'tahlta',
 				'ti' => 'tigrinja',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turkmeeni',
 				'tkl' => 'tokelau',
 				'tkr' => 'tsahuri',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tly' => 'tališi',
 				'tmh' => 'tamašek',
 				'tn' => 'tswana',
 				'to' => 'tonga',
 				'tog' => 'malawintonga',
 				'tok' => 'toki pona',
 				'tpi' => 'tok-pisin',
 				'tr' => 'turkki',
 				'tru' => 'turojo',
 				'trv' => 'taroko',
 				'trw' => 'torwali',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakonia',
 				'tsi' => 'tsimši',
 				'tt' => 'tataari',
 				'ttm' => 'pohjoinen tutchone',
 				'ttt' => 'tati',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahiti',
 				'tyv' => 'tuva',
 				'tzm' => 'keskiatlaksentamazight',
 				'udm' => 'udmurtti',
 				'ug' => 'uiguuri',
 				'uga' => 'ugarit',
 				'uk' => 'ukraina',
 				'umb' => 'mbundu',
 				'und' => 'tuntematon kieli',
 				'ur' => 'urdu',
 				'uz' => 'uzbekki',
 				've' => 'venda',
 				'vec' => 'venetsia',
 				'vep' => 'vepsä',
 				'vi' => 'vietnam',
 				'vls' => 'länsiflaami',
 				'vmf' => 'maininfrankki',
 				'vmw' => 'makhuwa',
 				'vo' => 'volapük',
 				'vot' => 'vatja',
 				'vro' => 'võro',
 				'vun' => 'vunjo',
 				'wa' => 'valloni',
 				'wae' => 'walser',
 				'wal' => 'wolaitta',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu-kiina',
 				'xal' => 'kalmukki',
 				'xh' => 'xhosa',
 				'xmf' => 'mingreli',
 				'xnr' => 'kangri',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japi',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddiš',
 				'yo' => 'joruba',
 				'yrl' => 'ñeengatú',
 				'yue' => 'kantoninkiina',
 				'yue@alt=menu' => 'kiina (kantonin)',
 				'za' => 'zhuang',
 				'zap' => 'zapoteekki',
 				'zbl' => 'blisskieli',
 				'zea' => 'seelanti',
 				'zen' => 'zenaga',
 				'zgh' => 'vakioitu tamazight',
 				'zh' => 'kiina',
 				'zh@alt=menu' => 'kiina (mandariini)',
 				'zh_Hans@alt=long' => 'mandariinikiina (yksinkertaistettu)',
 				'zh_Hant@alt=long' => 'mandariinikiina (perinteinen)',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'ei kielellistä sisältöä',
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
			'Adlm' => 'fulanin adlam-aakkosto',
 			'Afak' => 'afaka',
 			'Aghb' => 'kaukasianalbanialainen',
 			'Ahom' => 'ahom',
 			'Arab' => 'arabialainen',
 			'Arab@alt=variant' => 'persialaisarabialainen',
 			'Aran' => 'nastaliq',
 			'Armi' => 'valtakunnanaramealainen',
 			'Armn' => 'armenialainen',
 			'Avst' => 'avestalainen',
 			'Bali' => 'balilainen',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa',
 			'Batk' => 'batakilainen',
 			'Beng' => 'bengalilainen',
 			'Bhks' => 'sanskritin bhaiksuki-aakkosto',
 			'Blis' => 'bliss-symbolit',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille-pistekirjoitus',
 			'Bugi' => 'bugilainen',
 			'Buhd' => 'buhidilainen',
 			'Cakm' => 'chakmalainen',
 			'Cans' => 'kanadalaisten alkuperäiskansojen yhtenäistetty tavukirjoitus',
 			'Cari' => 'kaarialainen',
 			'Cham' => 'tšamilainen',
 			'Cher' => 'cherokeelainen',
 			'Chrs' => 'horemzi',
 			'Cirt' => 'cirth',
 			'Copt' => 'koptilainen',
 			'Cpmn' => 'kypro-minolainen',
 			'Cprt' => 'muinaiskyproslainen',
 			'Cyrl' => 'kyrillinen',
 			'Cyrs' => 'kyrillinen muinaiskirkkoslaavimuunnelma',
 			'Deva' => 'devanagari',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogri',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'Duployén pikakirjoitus',
 			'Egyd' => 'egyptiläinen demoottinen',
 			'Egyh' => 'egyptiläinen hieraattinen',
 			'Egyp' => 'egyptiläiset hieroglyfit',
 			'Elba' => 'elbasanilainen',
 			'Elym' => 'elymealainen',
 			'Ethi' => 'etiopialainen',
 			'Ethi@alt=secondary' => 'ge’ez',
 			'Geok' => 'muinaisgeorgialainen',
 			'Geok@alt=secondary' => 'khutsuri',
 			'Geor' => 'georgialainen',
 			'Geor@alt=secondary' => 'mkhedruli',
 			'Glag' => 'glagoliittinen',
 			'Gong' => 'gondin gunjala',
 			'Gonm' => 'masaram-gondi',
 			'Goth' => 'goottilainen',
 			'Gran' => 'grantha',
 			'Grek' => 'kreikkalainen',
 			'Gujr' => 'gudžaratilainen',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'kiinan han ja bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'kiinalainen han',
 			'Hano' => 'hanunoolainen',
 			'Hans' => 'yksinkertaistettu',
 			'Hans@alt=stand-alone' => 'yksinkertaistettu han',
 			'Hant' => 'perinteinen',
 			'Hant@alt=stand-alone' => 'perinteinen han',
 			'Hatr' => 'hatralainen',
 			'Hebr' => 'heprealainen',
 			'Hira' => 'hiragana',
 			'Hluw' => 'anatolialaiset hieroglyfit',
 			'Hmng' => 'pahawh hmong',
 			'Hmnp' => 'hmongin nyiakeng puachue',
 			'Hrkt' => 'japanin tavumerkistöt',
 			'Hung' => 'muinaisunkarilainen',
 			'Inds' => 'induslainen',
 			'Ital' => 'muinaisitalialainen',
 			'Jamo' => 'korean hangulin jamo-elementit',
 			'Java' => 'jaavalainen',
 			'Jpan' => 'japanilainen',
 			'Jurc' => 'džurtšen',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Kawi' => 'kawi',
 			'Khar' => 'kharosthi',
 			'Khmr' => 'khmeriläinen',
 			'Khoj' => 'khojki',
 			'Kits' => 'kitaanin pieni merkistö',
 			'Knda' => 'kannadalainen',
 			'Kore' => 'korealainen',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laolainen',
 			'Latf' => 'latinalainen fraktuuramuunnelma',
 			'Latg' => 'latinalainen gaelimuunnelma',
 			'Latn' => 'latinalainen',
 			'Lepc' => 'lepchalainen',
 			'Limb' => 'limbulainen',
 			'Lina' => 'lineaari-A',
 			'Linb' => 'lineaari-B',
 			'Lisu' => 'Fraserin aakkoset',
 			'Loma' => 'loma',
 			'Lyci' => 'lyykialainen',
 			'Lydi' => 'lyydialainen',
 			'Mahj' => 'mahajanilainen',
 			'Maka' => 'makassar',
 			'Mand' => 'mandealainen',
 			'Mani' => 'manikealainen',
 			'Marc' => 'tiibetiläinen marchan-kirjoitus',
 			'Maya' => 'maya-hieroglyfit',
 			'Medf' => 'medefaidrin',
 			'Mend' => 'mende',
 			'Merc' => 'meroiittinen kursiivikirjoitus',
 			'Mero' => 'meroiittinen',
 			'Mlym' => 'malajalamilainen',
 			'Modi' => 'modi-aakkoset',
 			'Mong' => 'mongolilainen',
 			'Moon' => 'moon-kohokirjoitus',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei',
 			'Mtei@alt=secondary' => 'meitei mayek',
 			'Mult' => 'multanilainen',
 			'Mymr' => 'burmalainen',
 			'Nagm' => 'Nagin mundariaakkoset',
 			'Nand' => 'nandinagari',
 			'Narb' => 'muinaispohjoisarabialainen',
 			'Nbat' => 'nabatealainen',
 			'Newa' => 'newarin newa-tavukirjoitus',
 			'Nkgb' => 'naxi geba',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogam',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'orijalainen',
 			'Osge' => 'osagen aakkosto',
 			'Osma' => 'osmanjalainen',
 			'Ougr' => 'vanha uiguurilainen',
 			'Palm' => 'palmyralainen',
 			'Pauc' => 'zotuallai',
 			'Perm' => 'muinaispermiläinen',
 			'Phag' => 'phags-pa',
 			'Phli' => 'piirtokirjoituspahlavilainen',
 			'Phlp' => 'psalttaripahlavilainen',
 			'Phlv' => 'kirjapahlavilainen',
 			'Phnx' => 'foinikialainen',
 			'Plrd' => 'Pollardin foneettinen',
 			'Prti' => 'piirtokirjoitusparthialainen',
 			'Qaag' => 'burmalainen zawgyi-toteutus',
 			'Rjng' => 'rejang',
 			'Rohg' => 'rohingalainen hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'riimukirjoitus',
 			'Samr' => 'samarianaramealainen',
 			'Sara' => 'sarati',
 			'Sarb' => 'muinaiseteläarabialainen',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'shaw’lainen',
 			'Shrd' => 'šarada',
 			'Sidd' => 'siddham-tavukirjoitus',
 			'Sind' => 'khudabadi',
 			'Sinh' => 'sinhalilainen',
 			'Sogd' => 'sogdialainen',
 			'Sogo' => 'muinaissogdialainen',
 			'Sora' => 'sorang sompeng',
 			'Soyo' => 'soyombo-kirjaimisto',
 			'Sund' => 'sundalainen',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syyrialainen',
 			'Syre' => 'syyrialainen estrangelo-muunnelma',
 			'Syrj' => 'syyrialainen läntinen muunnelma',
 			'Syrn' => 'syyrialainen itäinen muunnelma',
 			'Tagb' => 'tagbanwalainen',
 			'Takr' => 'takri',
 			'Tale' => 'tailelainen',
 			'Talu' => 'uusi tailuelainen',
 			'Taml' => 'tamililainen',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugulainen',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalogilainen',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailainen',
 			'Tibt' => 'tiibetiläinen',
 			'Tirh' => 'tirhuta',
 			'Tnsa' => 'tangsa',
 			'Toto' => 'toto',
 			'Ugar' => 'ugaritilainen',
 			'Vaii' => 'vailainen',
 			'Visp' => 'näkyvä puhe',
 			'Visp@alt=secondary' => 'Visible Speech',
 			'Vith' => 'vithkuqi',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wancholainen',
 			'Wole' => 'woleai',
 			'Xpeo' => 'muinaispersialainen',
 			'Xsux' => 'sumerilais-akkadilainen nuolenpääkirjoitus',
 			'Yezi' => 'jesidi',
 			'Yiii' => 'yiläinen',
 			'Zanb' => 'zanabazar-neliökirjaimisto',
 			'Zinh' => 'peritty',
 			'Zmth' => 'matemaattinen',
 			'Zsye' => 'emoji-symbolit',
 			'Zsym' => 'symbolit',
 			'Zxxx' => 'kirjoittamaton',
 			'Zyyy' => 'määrittämätön',
 			'Zzzz' => 'tuntematon kirjoitusjärjestelmä',

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
			'001' => 'maailma',
 			'002' => 'Afrikka',
 			'003' => 'Pohjois-Amerikka',
 			'005' => 'Etelä-Amerikka',
 			'009' => 'Oseania',
 			'011' => 'Länsi-Afrikka',
 			'013' => 'Väli-Amerikka',
 			'014' => 'Itä-Afrikka',
 			'015' => 'Pohjois-Afrikka',
 			'017' => 'Keski-Afrikka',
 			'018' => 'eteläinen Afrikka',
 			'019' => 'Amerikka',
 			'021' => 'pohjoinen Amerikka',
 			'029' => 'Karibia',
 			'030' => 'Itä-Aasia',
 			'034' => 'Etelä-Aasia',
 			'035' => 'Kaakkois-Aasia',
 			'039' => 'Etelä-Eurooppa',
 			'053' => 'Australaasia',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesian alue',
 			'061' => 'Polynesia',
 			'142' => 'Aasia',
 			'143' => 'Keski-Aasia',
 			'145' => 'Länsi-Aasia',
 			'150' => 'Eurooppa',
 			'151' => 'Itä-Eurooppa',
 			'154' => 'Pohjois-Eurooppa',
 			'155' => 'Länsi-Eurooppa',
 			'202' => 'Saharan eteläpuolinen Afrikka',
 			'419' => 'Latinalainen Amerikka',
 			'AC' => 'Ascension-saari',
 			'AD' => 'Andorra',
 			'AE' => 'Arabiemiirikunnat',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua ja Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentiina',
 			'AS' => 'Amerikan Samoa',
 			'AT' => 'Itävalta',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Ahvenanmaa',
 			'AZ' => 'Azerbaidžan',
 			'BA' => 'Bosnia ja Hertsegovina',
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
 			'BQ' => 'Karibian Alankomaat',
 			'BR' => 'Brasilia',
 			'BS' => 'Bahama',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet’nsaari',
 			'BW' => 'Botswana',
 			'BY' => 'Valko-Venäjä',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kookossaaret (Keelingsaaret)',
 			'CD' => 'Kongon demokraattinen tasavalta',
 			'CD@alt=variant' => 'Kongo-Kinshasa',
 			'CF' => 'Keski-Afrikan tasavalta',
 			'CG' => 'Kongon tasavalta',
 			'CG@alt=variant' => 'Kongo-Brazzaville',
 			'CH' => 'Sveitsi',
 			'CI' => 'Norsunluurannikko',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cookinsaaret',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kiina',
 			'CO' => 'Kolumbia',
 			'CP' => 'Clippertoninsaari',
 			'CQ' => 'Sark',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Joulusaari',
 			'CY' => 'Kypros',
 			'CZ' => 'Tšekki',
 			'CZ@alt=variant' => 'Tšekin tasavalta',
 			'DE' => 'Saksa',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Tanska',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikaaninen tasavalta',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta ja Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Viro',
 			'EG' => 'Egypti',
 			'EH' => 'Länsi-Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Espanja',
 			'ET' => 'Etiopia',
 			'EU' => 'Euroopan unioni',
 			'EZ' => 'euroalue',
 			'FI' => 'Suomi',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandinsaaret',
 			'FK@alt=variant' => 'Falklandinsaaret (Malvinassaaret)',
 			'FM' => 'Mikronesia',
 			'FO' => 'Färsaaret',
 			'FR' => 'Ranska',
 			'GA' => 'Gabon',
 			'GB' => 'Iso-Britannia',
 			'GB@alt=short' => 'Britannia',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Ranskan Guayana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönlanti',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Päiväntasaajan Guinea',
 			'GR' => 'Kreikka',
 			'GS' => 'Etelä-Georgia ja Eteläiset Sandwichinsaaret',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong – Kiinan erityishallintoalue',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard ja McDonaldinsaaret',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Unkari',
 			'IC' => 'Kanariansaaret',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanti',
 			'IL' => 'Israel',
 			'IM' => 'Mansaari',
 			'IN' => 'Intia',
 			'IO' => 'Brittiläinen Intian valtameren alue',
 			'IO@alt=chagos' => 'Chagossaaret',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islanti',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordania',
 			'JP' => 'Japani',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisia',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorit',
 			'KN' => 'Saint Kitts ja Nevis',
 			'KP' => 'Pohjois-Korea',
 			'KR' => 'Etelä-Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Caymansaaret',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Liettua',
 			'LU' => 'Luxemburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallinsaaret',
 			'MK' => 'Pohjois-Makedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao – Kiinan erityishallintoalue',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Pohjois-Mariaanit',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediivit',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Uusi-Kaledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkinsaari',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Alankomaat',
 			'NO' => 'Norja',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Uusi-Seelanti',
 			'NZ@alt=variant' => 'Aotearoa',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Ranskan Polynesia',
 			'PG' => 'Papua-Uusi-Guinea',
 			'PH' => 'Filippiinit',
 			'PK' => 'Pakistan',
 			'PL' => 'Puola',
 			'PM' => 'Saint-Pierre ja Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestiinalaisalue',
 			'PS@alt=short' => 'Palestiina',
 			'PT' => 'Portugali',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oseanian erillissaaret',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Venäjä',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Arabia',
 			'SB' => 'Salomonsaaret',
 			'SC' => 'Seychellit',
 			'SD' => 'Sudan',
 			'SE' => 'Ruotsi',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Huippuvuoret ja Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Etelä-Sudan',
 			'ST' => 'São Tomé ja Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syyria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swazimaa',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- ja Caicossaaret',
 			'TD' => 'Tšad',
 			'TF' => 'Ranskan eteläiset ja antarktiset alueet',
 			'TG' => 'Togo',
 			'TH' => 'Thaimaa',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Itä-Timor',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkki',
 			'TT' => 'Trinidad ja Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Yhdysvaltain erillissaaret',
 			'UN' => 'Yhdistyneet kansakunnat',
 			'UN@alt=short' => 'YK',
 			'US' => 'Yhdysvallat',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikaani',
 			'VC' => 'Saint Vincent ja Grenadiinit',
 			'VE' => 'Venezuela',
 			'VG' => 'Brittiläiset Neitsytsaaret',
 			'VI' => 'Yhdysvaltain Neitsytsaaret',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ja Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudoaksentit',
 			'XB' => 'kaksisuuntainen pseudo',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Etelä-Afrikka',
 			'ZM' => 'Sambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'tuntematon alue',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'saksan perinteinen oikeinkirjoitus',
 			'1994' => 'sloveenin resian murteen yhdenmukaistettu oikeinkirjoitus',
 			'1996' => 'saksan uusi oikeinkirjoitus',
 			'1606NICT' => 'myöhäiskeskiranska',
 			'1694ACAD' => 'varhaisnykyranska',
 			'1959ACAD' => 'valkovenäjän virallinen oikeinkirjoitus',
 			'ABL1943' => 'portugalin oikeinkirjoitus 1943',
 			'AKUAPEM' => 'akanin akuapem-murre',
 			'ALALC97' => 'amerikkalainen kirjastolatinaistus 1997',
 			'ALUKU' => 'alukun kreolimurre',
 			'AO1990' => 'portugalin oikeinkirjoitussopimus 1990',
 			'ARANES' => 'oksitaanin Aranin laakson variantti',
 			'AREVELA' => 'itäarmenialainen',
 			'AREVMDA' => 'länsiarmenialainen',
 			'ARKAIKA' => 'varhaisesperanto',
 			'ASANTE' => 'akanin asante-variantti',
 			'AUVERN' => 'oksitaanin Auvergnen variantti',
 			'BAKU1926' => 'yhtenäistetty turkkilainen latinalainen aakkosto',
 			'BALANKA' => 'aniin balankalaismurre',
 			'BARLA' => 'kapverdenkreolin barlaventolainen murreryhmä',
 			'BASICENG' => 'Ogdenin perusenglanti',
 			'BAUDDHA' => 'sanskriitin buddhalainen sekamuoto',
 			'BISCAYAN' => 'baskin biskajalaismurre',
 			'BISKE' => 'sloveenin resian San Giorgion/Bilan alamurre',
 			'BOHORIC' => 'sloveenin Bohorič-aakkosto',
 			'BOONT' => 'englannin boontling-murre',
 			'BORNHOLM' => 'Bornholmin murre',
 			'CISAUP' => 'oksitaanin luoteisitalialainen variantti',
 			'COLB1945' => 'portugalin oikeinkirjoitus 1945',
 			'CORNU' => 'englannin cornu-murre',
 			'CREISS' => 'oksitaanin Croissantin variantti',
 			'DAJNKO' => 'sloveenin Dajnko-aakkosto',
 			'EKAVSK' => 'serbian ekavialainen ääntämys',
 			'EMODENG' => 'varhaisnykyenglanti',
 			'FONIPA' => 'kansainvälinen foneettinen aakkosto IPA',
 			'FONKIRSH' => 'Kirshenbaumin foneettinen aakkosto',
 			'FONNAPA' => 'pohjoisamerikkalainen foneettinen aakkosto NAPA',
 			'FONUPA' => 'uralilainen foneettinen aakkosto UPA',
 			'FONUPA@alt=secondary' => 'suomalais-ugrilainen tarkekirjoitus',
 			'FONXSAMP' => 'foneettinen X-SAMPA-merkistö',
 			'GALLO' => 'galo',
 			'GASCON' => 'oksitaanin Gasconyn variantti',
 			'GRCLASS' => 'oksitaanin klassinen ortografia',
 			'GRITAL' => 'oksitaanin italialaisvaikutteinen ortografia',
 			'GRMISTR' => 'oksitaanin Mistral-vaikutteinen ortografia',
 			'HEPBURN' => 'japanin Hepburn-latinaistus',
 			'HOGNORSK' => 'norjan högnorsk',
 			'HSISTEMO' => 'esperanton h-kirjoitus',
 			'IJEKAVSK' => 'serbian ijekavialainen ääntämys',
 			'ITIHASA' => 'sanskriitin eeppinen muoto',
 			'IVANCHOV' => 'bulgarian 1899 ortografia',
 			'JAUER' => 'retoromaanin jauer-murre',
 			'JYUTPING' => 'kantoninkiinan jyutping-latinaistus',
 			'KKCOR' => 'kornin yleiskirjoitus',
 			'KOCIEWIE' => 'puolan kociewielainen murre',
 			'KSCOR' => 'kornin Kernowek-ortografia',
 			'LAUKIKA' => 'klassinen sanskriitti',
 			'LEMOSIN' => 'oksitaanin Limousin-alueen variantti',
 			'LENGADOC' => 'oksitaanin lengadocian variantti',
 			'LIPAW' => 'sloveenin resian Lipovazin/Lipovecin alamurre',
 			'LUNA1918' => 'venäjän ortografia 1918',
 			'METELKO' => 'sloveenin Metelko-aakkosto',
 			'MONOTON' => 'monotoninen kreikka',
 			'NDYUKA' => 'ndyukan kreolimurre',
 			'NEDIS' => 'sloveenin natisonen murre',
 			'NEWFOUND' => 'englannin newfoundlandilaismurre',
 			'NICARD' => 'oksitaanin Nizzan variantti',
 			'NJIVA' => 'sloveenin resian Gnivan/Njivan alamurre',
 			'NULIK' => 'nykyvolapük',
 			'OSOJS' => 'sloveenin resian Oseaccon/Osojanen alamurre',
 			'OXENDICT' => 'englannin Oxfordin sanakirjan oikeinkirjoitus',
 			'PAHAWH2' => 'pahawh-hmongin tavukirjoituksen toinen vaihe',
 			'PAHAWH3' => 'pahawh-hmongin tavukirjoituksen kolmas vaihe',
 			'PAHAWH4' => 'pahawh-hmongin tavukirjoituksen viimeinen vaihe',
 			'PAMAKA' => 'pamakan kreolimurre',
 			'PEANO' => 'taivutukseton latina',
 			'PETR1708' => 'venäjän Pietarin siviiliaakkosto 1708',
 			'PINYIN' => 'kiinan pinyin-latinaistus',
 			'POLYTON' => 'polytoninen kreikka',
 			'POSIX' => 'tietokonemäärittely POSIX',
 			'PROVENC' => 'provensaali',
 			'PUTER' => 'retoromaanin puter-muoto',
 			'REVISED' => 'uudistettu oikeinkirjoitus',
 			'RIGIK' => 'klassinen volapük',
 			'ROZAJ' => 'sloveenin resian murre',
 			'RUMGR' => 'retoromaanin rumantsch grischun -muoto',
 			'SAAHO' => 'afarin saho-murre',
 			'SCOTLAND' => 'skotlanninenglanti',
 			'SCOUSE' => 'englannin scouse-murre',
 			'SIMPLE' => 'yksinkertaistettu kielimuoto',
 			'SOLBA' => 'sloveenin resian Stolvizzan/Solbican alamurre',
 			'SOTAV' => 'kapverdenkreolin sotaventolainen murreryhmä',
 			'SPANGLIS' => 'spanglish',
 			'SURMIRAN' => 'retoromaanin surmiran-muoto',
 			'SURSILV' => 'retoromaanin sursilvan-muoto',
 			'SUTSILV' => 'retoromaanin sutsilvan-muoto',
 			'SYNNEJYL' => 'Etelä-Jyllannin kieli',
 			'TARASK' => 'valkovenäjän taraškevitsa-oikeinkirjoitus',
 			'TONGYONG' => 'taiwanilainen pinyinin',
 			'TUNUMIIT' => 'tunumiit',
 			'UCCOR' => 'kornin yhtenäiskirjoitus',
 			'UCRCOR' => 'kornin uusittu yhtenäiskirjoitus',
 			'ULSTER' => 'skotin ulster-murre',
 			'UNIFON' => 'englannin foneeminen unifon-aakkosto',
 			'VAIDIKA' => 'sanskriitin veda-murre',
 			'VALENCIA' => 'katalaanin valencian murre',
 			'VALLADER' => 'reoromaanin vallader-muoto',
 			'VECDRUKA' => 'varhaislatvia',
 			'VIVARAUP' => 'oksitaanin vivaro-alpiininen variantti',
 			'WADEGILE' => 'kiinan Wade-Giles-latinaistus',
 			'XSISTEMO' => 'esperanton x-kirjoitus',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalenteri',
 			'cf' => 'valuuttojen esitysmuoto',
 			'colalternate' => 'symbolit ohittava lajittelu',
 			'colbackwards' => 'painomerkkien lajittelu',
 			'colcasefirst' => 'isojen ja pienten kirjainten järjestys',
 			'colcaselevel' => 'aakkoslajien lajittelu',
 			'collation' => 'lajittelujärjestys',
 			'colnormalization' => 'normalisoitu lajittelu',
 			'colnumeric' => 'numeroiden lajittelu',
 			'colstrength' => 'lajittelun taso',
 			'currency' => 'valuutta',
 			'hc' => 'tuntijärjestelmä',
 			'lb' => 'rivinvaihtotyyli',
 			'ms' => 'mittajärjestelmä',
 			'numbers' => 'numerot',
 			'timezone' => 'aikavyöhyke',
 			'va' => 'maavalinnan muunnelma',
 			'x' => 'yksityiskäyttö',

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
 				'buddhist' => q{buddhalainen kalenteri},
 				'chinese' => q{kiinalainen kalenteri},
 				'coptic' => q{koptilainen kalenteri},
 				'dangi' => q{dangilainen kalenteri},
 				'ethiopic' => q{etiopialainen kalenteri},
 				'ethiopic-amete-alem' => q{etiopialainen amete alem -kalenteri},
 				'gregorian' => q{gregoriaaninen kalenteri},
 				'hebrew' => q{juutalainen kalenteri},
 				'indian' => q{intialainen kalenteri},
 				'islamic' => q{hidžra-kalenteri},
 				'islamic-civil' => q{hidžra-siviilikalenteri (tabulaarinen, perjantaiepookki)},
 				'islamic-rgsa' => q{hidžra-kalenteri (saudiarabialainen)},
 				'islamic-tbla' => q{hidžra-matemaattinen kalenteri (tabulaarinen, torstaiepookki)},
 				'islamic-umalqura' => q{hidžra-kalenteri, Umm al-Qura},
 				'iso8601' => q{ISO 8601 -kalenteri},
 				'japanese' => q{japanilainen kalenteri},
 				'persian' => q{persialainen kalenteri},
 				'roc' => q{Kiinan tasavallan kalenteri},
 			},
 			'cf' => {
 				'account' => q{valuuttojen laskentatoimen esitysmuoto},
 				'standard' => q{valuuttojen vakioesitysmuoto},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{symbolit huomioiva lajittelu},
 				'shifted' => q{symbolit ohittava lajittelu},
 			},
 			'colbackwards' => {
 				'no' => q{painomerkkien normaali lajittelu},
 				'yes' => q{painomerkkien käänteinen lajittelu},
 			},
 			'colcasefirst' => {
 				'lower' => q{pienet kirjaimet edeltävät isoja},
 				'no' => q{isojen ja pienten kirjainten normaalijärjestys},
 				'upper' => q{isot kirjaimet edeltävät pieniä},
 			},
 			'colcaselevel' => {
 				'no' => q{isojen ja pienten kirjainten lajittelu yhdessä},
 				'yes' => q{isojen ja pienten kirjainten lajittelu erikseen},
 			},
 			'collation' => {
 				'big5han' => q{perinteinen kiinalainen järjestys Big5},
 				'compat' => q{aiempi lajittelujärjestys yhteensopivuutta varten},
 				'dictionary' => q{sanakirjajärjestys},
 				'ducet' => q{Unicoden oletusjärjestys},
 				'emoji' => q{emojien lajittelujärjestys},
 				'eor' => q{yleiseurooppalainen lajittelujärjestys},
 				'gb2312han' => q{yksinkertaistettu kiinalainen järjestys GB2312},
 				'phonebook' => q{puhelinluettelojärjestys},
 				'phonetic' => q{äänteellinen järjestys},
 				'pinyin' => q{pinyin-järjestys},
 				'search' => q{yleishakujärjestys},
 				'searchjl' => q{haku hangul-alkukonsonantin mukaan},
 				'standard' => q{normaalijärjestys},
 				'stroke' => q{piirtojärjestys},
 				'traditional' => q{perinteinen järjestys},
 				'unihan' => q{radikaali- ja piirtojärjestys},
 				'zhuyin' => q{zhuyin-järjestys},
 			},
 			'colnormalization' => {
 				'no' => q{lajittelu ilman normalisointia},
 				'yes' => q{lajittelu Unicode-normalisoituna},
 			},
 			'colnumeric' => {
 				'no' => q{numero-numerolta lajittelu},
 				'yes' => q{numeroden lajittelu lukuina},
 			},
 			'colstrength' => {
 				'identical' => q{kaikkien merkkien lajittelu},
 				'primary' => q{vain peruskirjainten lajittelu},
 				'quaternary' => q{painomerkit ja aakkoslajit tai merkkileveydet ja kana-merkit huomioiva lajittelu},
 				'secondary' => q{painomerkit huomioiva lajittelu},
 				'tertiary' => q{painomerkit ja aakkoslajit tai merkkileveydet huomioiva lajittelu},
 			},
 			'd0' => {
 				'fwidth' => q{ideogrammin levyinen},
 				'hwidth' => q{ideogrammin puolikkaan levyinen},
 				'npinyin' => q{numeerinen muunnos},
 			},
 			'hc' => {
 				'h11' => q{12 tunnin järjestelmä (0–11)},
 				'h12' => q{12 tunnin järjestelmä (1–12)},
 				'h23' => q{24 tunnin järjestelmä (0–23)},
 				'h24' => q{24 tunnin järjestelmä (1–24)},
 			},
 			'lb' => {
 				'loose' => q{väljä rivinvaihto},
 				'normal' => q{normaali rivinvaihto},
 				'strict' => q{tarkka rivinvaihto},
 			},
 			'm0' => {
 				'bgn' => q{BGN-latinaistus},
 				'ungegn' => q{UNGEGN-latinaistus},
 			},
 			'ms' => {
 				'metric' => q{metrijärjestelmä},
 				'uksystem' => q{brittiläinen mittajärjestelmä},
 				'ussystem' => q{yhdysvaltalainen mittajärjestelmä},
 			},
 			'numbers' => {
 				'ahom' => q{ahom-numerot},
 				'arab' => q{arabialaiset numerot},
 				'arabext' => q{laajennetut arabialaiset numerot},
 				'armn' => q{armenialaiset numerot},
 				'armnlow' => q{armenialaiset piennumerot},
 				'bali' => q{balilaiset numerot},
 				'beng' => q{bengalilaiset numerot},
 				'brah' => q{brahmilaiset numerot},
 				'cakm' => q{chakmalaiset numerot},
 				'cham' => q{cham-numerot},
 				'cyrl' => q{kyrilliset numerot},
 				'deva' => q{devanagarinumerot},
 				'diak' => q{dives akuru -numerot},
 				'ethi' => q{etiopialaiset numerot},
 				'finance' => q{talousnumerot},
 				'fullwide' => q{ideografin levyiset numerot},
 				'geor' => q{georgialaiset numerot},
 				'gong' => q{gondin gunjala-numerot},
 				'gonm' => q{gondin masaram-numerot},
 				'grek' => q{kreikkalaiset numerot},
 				'greklow' => q{kreikkalaiset piennumerot},
 				'gujr' => q{gudžaratilaiset numerot},
 				'guru' => q{gurmukhilaiset numerot},
 				'hanidec' => q{kiinalaiset desimaalinumerot},
 				'hans' => q{yksinkertaistetut kiinalaiset numerot},
 				'hansfin' => q{yksinkertaistetut kiinalaiset talousnumerot},
 				'hant' => q{perinteiset kiinalaiset numerot},
 				'hantfin' => q{perinteiset kiinalaiset talousnumerot},
 				'hebr' => q{heprealaiset numerot},
 				'hmng' => q{pahawh hmong -numerot},
 				'hmnp' => q{hmongin nyiakeng puachue -numerot},
 				'java' => q{jaavalaiset numerot},
 				'jpan' => q{japanilaiset numerot},
 				'jpanfin' => q{japanilaiset talousnumerot},
 				'kali' => q{kayah li -numerot},
 				'kawi' => q{kawilaiset numerot},
 				'khmr' => q{khmeriläiset numerot},
 				'knda' => q{kannadalaiset numerot},
 				'lana' => q{taithamin hora-numerot},
 				'lanatham' => q{taithamin tham-numerot},
 				'laoo' => q{laolaiset numerot},
 				'latn' => q{länsimaiset numerot},
 				'lepc' => q{lepchanumerot},
 				'limb' => q{limbunumerot},
 				'mathbold' => q{matemaattiset lihavoidut numerot},
 				'mathdbl' => q{matemaattiset kaksoislyöntinumerot},
 				'mathmono' => q{matemaattiset tasalevyiset numerot},
 				'mathsanb' => q{matemaattiset pääteviivattomat lihavoidut numerot},
 				'mathsans' => q{matemaattiset pääteviivattomat numerot},
 				'mlym' => q{malajalamilaiset numerot},
 				'modi' => q{modi-numerot},
 				'mong' => q{mongolialaiset numerot},
 				'mroo' => q{mro-numerot},
 				'mtei' => q{meetei mayek -numerot},
 				'mymr' => q{burmalaiset numerot},
 				'mymrshan' => q{myanmarin shan-numerot},
 				'mymrtlng' => q{myanmarin tai laing -numerot},
 				'nagm' => q{Nagin mundarinumerot},
 				'native' => q{kielen omat numerot},
 				'nkoo' => q{n’ko-numerot},
 				'olck' => q{ol chiki -numerot},
 				'orya' => q{orijalaiset numerot},
 				'osma' => q{osmanjalaiset numerot},
 				'rohg' => q{hanifilaisen rohingyan numerot},
 				'roman' => q{roomalaiset numerot},
 				'romanlow' => q{roomalaiset piennumerot},
 				'saur' => q{saurashtra-numerot},
 				'shrd' => q{šarada-numerot},
 				'sind' => q{khutabadi-numerot},
 				'sinh' => q{sinhalan lith-numerot},
 				'sora' => q{sora sompeng -numerot},
 				'sund' => q{sundalaiset numerot},
 				'takr' => q{takri-numerot},
 				'talu' => q{uudet tai lue -numerot},
 				'taml' => q{perinteiset tamilinumerot},
 				'tamldec' => q{tamilinumerot},
 				'telu' => q{telugulaiset numerot},
 				'thai' => q{thainumerot},
 				'tibt' => q{tiibetiläiset numerot},
 				'tirh' => q{tirhuta-numerot},
 				'tnsa' => q{tangsa-numerot},
 				'traditional' => q{perinteiset numerot},
 				'vaii' => q{vai-numerot},
 				'wara' => q{varang kshiti -numerot},
 				'wcho' => q{wancholaiset numerot},
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
			'metric' => q{metrinen},
 			'UK' => q{brittiläinen},
 			'US' => q{amerikkalainen},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'kieli: {0}',
 			'script' => 'kirjoitusjärjestelmä: {0}',
 			'region' => 'alue: {0}',

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
			auxiliary => qr{[áàăâãąā ćčċç ďð đ éèêěëėęē ğǧģ ǥ ȟħ íîïİįī ı ǩķ ĺľļł ńňñņ ŋ óòôőõ œ ŕř śŝşș ß ťţț ŧ úùûůűųū ýÿü źż ʒǯ þ æ ø]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Å', 'Ä', 'Ö'],
			main => qr{[a b c d e f g h i j k l m n o p q r sš t u v w x y zž å ä ö]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … ’ ” » ( ) \[ \] § @ * / \\ \& #]},
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
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}…{1}',
		};
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
						'name' => q(pääilmansuunta),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(pääilmansuunta),
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
						'1' => q(eksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(tsebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(tsebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(jobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(jobi{0}),
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
						'1' => q(sentti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(sentti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(tsepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(tsepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(jokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(jokto{0}),
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
						'1' => q(kvekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kvekto{0}),
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
						'1' => q(eksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hehto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hehto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(tsetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(tsetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(jotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(jotta{0}),
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
						'1' => q(kvetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kvetta{0}),
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
						'name' => q(G-voimat),
						'one' => q({0} G-voima),
						'other' => q({0} G-voimaa),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G-voimat),
						'one' => q({0} G-voima),
						'other' => q({0} G-voimaa),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metrit per sekunti toiseen),
						'one' => q({0} metri per sekunti toiseen),
						'other' => q({0} metriä per sekunti toiseen),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metrit per sekunti toiseen),
						'one' => q({0} metri per sekunti toiseen),
						'other' => q({0} metriä per sekunti toiseen),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(kulmaminuutit),
						'one' => q({0} kulmaminuutti),
						'other' => q({0} kulmaminuuttia),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(kulmaminuutit),
						'one' => q({0} kulmaminuutti),
						'other' => q({0} kulmaminuuttia),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(kulmasekunnit),
						'one' => q({0} kulmasekunti),
						'other' => q({0} kulmasekuntia),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(kulmasekunnit),
						'one' => q({0} kulmasekunti),
						'other' => q({0} kulmasekuntia),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(asteet),
						'one' => q({0} aste),
						'other' => q({0} astetta),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(asteet),
						'one' => q({0} aste),
						'other' => q({0} astetta),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiaanit),
						'one' => q({0} radiaani),
						'other' => q({0} radiaania),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiaanit),
						'one' => q({0} radiaani),
						'other' => q({0} radiaania),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(kierros),
						'one' => q({0} kierros),
						'other' => q({0} kierrosta),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(kierros),
						'one' => q({0} kierros),
						'other' => q({0} kierrosta),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(eekkerit),
						'one' => q({0} eekkeri),
						'other' => q({0} eekkeriä),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(eekkerit),
						'one' => q({0} eekkeri),
						'other' => q({0} eekkeriä),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hehtaarit),
						'one' => q({0} hehtaari),
						'other' => q({0} hehtaaria),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hehtaarit),
						'one' => q({0} hehtaari),
						'other' => q({0} hehtaaria),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(neliösenttimetrit),
						'one' => q({0} neliösenttimetri),
						'other' => q({0} neliösenttimetriä),
						'per' => q({0} / neliösenttimetri),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(neliösenttimetrit),
						'one' => q({0} neliösenttimetri),
						'other' => q({0} neliösenttimetriä),
						'per' => q({0} / neliösenttimetri),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(neliöjalat),
						'one' => q({0} neliöjalka),
						'other' => q({0} neliöjalkaa),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(neliöjalat),
						'one' => q({0} neliöjalka),
						'other' => q({0} neliöjalkaa),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(neliötuumat),
						'one' => q({0} neliötuuma),
						'other' => q({0} neliötuumaa),
						'per' => q({0} / neliötuuma),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(neliötuumat),
						'one' => q({0} neliötuuma),
						'other' => q({0} neliötuumaa),
						'per' => q({0} / neliötuuma),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(neliökilometrit),
						'one' => q({0} neliökilometri),
						'other' => q({0} neliökilometriä),
						'per' => q({0} / neliökilometri),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(neliökilometrit),
						'one' => q({0} neliökilometri),
						'other' => q({0} neliökilometriä),
						'per' => q({0} / neliökilometri),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(neliömetrit),
						'one' => q({0} neliömetri),
						'other' => q({0} neliömetriä),
						'per' => q({0} / neliömetri),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(neliömetrit),
						'one' => q({0} neliömetri),
						'other' => q({0} neliömetriä),
						'per' => q({0} / neliömetri),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(neliömailit),
						'one' => q({0} neliömaili),
						'other' => q({0} neliömailia),
						'per' => q({0} / neliömaili),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(neliömailit),
						'one' => q({0} neliömaili),
						'other' => q({0} neliömailia),
						'per' => q({0} / neliömaili),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(neliöjaardit),
						'one' => q({0} neliöjaardi),
						'other' => q({0} neliöjaardia),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(neliöjaardit),
						'one' => q({0} neliöjaardi),
						'other' => q({0} neliöjaardia),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(kohteet),
						'one' => q({0} kohde),
						'other' => q({0} kohdetta),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(kohteet),
						'one' => q({0} kohde),
						'other' => q({0} kohdetta),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaatit),
						'one' => q({0} karaatti),
						'other' => q({0} karaattia),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaatit),
						'one' => q({0} karaatti),
						'other' => q({0} karaattia),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammat desilitrassa),
						'one' => q({0} milligramma desilitrassa),
						'other' => q({0} milligrammaa desilitrassa),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammat desilitrassa),
						'one' => q({0} milligramma desilitrassa),
						'other' => q({0} milligrammaa desilitrassa),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoolit litrassa),
						'one' => q({0} millimooli litrassa),
						'other' => q({0} millimoolia litrassa),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoolit litrassa),
						'one' => q({0} millimooli litrassa),
						'other' => q({0} millimoolia litrassa),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moolit),
						'one' => q({0} mooli),
						'other' => q({0} moolia),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moolit),
						'one' => q({0} mooli),
						'other' => q({0} moolia),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(prosentit),
						'one' => q({0} prosentti),
						'other' => q({0} prosenttia),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(prosentit),
						'one' => q({0} prosentti),
						'other' => q({0} prosenttia),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promillet),
						'one' => q({0} promille),
						'other' => q({0} promillea),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promillet),
						'one' => q({0} promille),
						'other' => q({0} promillea),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(miljoonasosat),
						'one' => q({0} miljoonasosa),
						'other' => q({0} miljoonasosaa),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(miljoonasosat),
						'one' => q({0} miljoonasosa),
						'other' => q({0} miljoonasosaa),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} peruspiste),
						'other' => q({0} peruspistettä),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} peruspiste),
						'other' => q({0} peruspistettä),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(miljardisosat),
						'one' => q({0} miljardisosa),
						'other' => q({0} miljardisosaa),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(miljardisosat),
						'one' => q({0} miljardisosa),
						'other' => q({0} miljardisosaa),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litrat / 100 kilometriä),
						'one' => q({0} litra / 100 km),
						'other' => q({0} litraa / 100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litrat / 100 kilometriä),
						'one' => q({0} litra / 100 km),
						'other' => q({0} litraa / 100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litrat / kilometri),
						'one' => q({0} litra / kilometri),
						'other' => q({0} litraa / kilometri),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litrat / kilometri),
						'one' => q({0} litra / kilometri),
						'other' => q({0} litraa / kilometri),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mailit / am. gallona),
						'one' => q({0} maili / am. gallona),
						'other' => q({0} mailia / am. gallona),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mailit / am. gallona),
						'one' => q({0} maili / am. gallona),
						'other' => q({0} mailia / am. gallona),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mailit / br. gallona),
						'one' => q({0} maili / br. gallona),
						'other' => q({0} mailia / br. gallona),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mailit / br. gallona),
						'one' => q({0} maili / br. gallona),
						'other' => q({0} mailia / br. gallona),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bitit),
						'one' => q({0} bitti),
						'other' => q({0} bittiä),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bitit),
						'one' => q({0} bitti),
						'other' => q({0} bittiä),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(tavut),
						'one' => q({0} tavu),
						'other' => q({0} tavua),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(tavut),
						'one' => q({0} tavu),
						'other' => q({0} tavua),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabitit),
						'one' => q({0} gigabitti),
						'other' => q({0} gigabittiä),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabitit),
						'one' => q({0} gigabitti),
						'other' => q({0} gigabittiä),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigatavut),
						'one' => q({0} gigatavu),
						'other' => q({0} gigatavua),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigatavut),
						'one' => q({0} gigatavu),
						'other' => q({0} gigatavua),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobitit),
						'one' => q({0} kilobitti),
						'other' => q({0} kilobittiä),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobitit),
						'one' => q({0} kilobitti),
						'other' => q({0} kilobittiä),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilotavut),
						'one' => q({0} kilotavu),
						'other' => q({0} kilotavua),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilotavut),
						'one' => q({0} kilotavu),
						'other' => q({0} kilotavua),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabitit),
						'one' => q({0} megabitti),
						'other' => q({0} megabittiä),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabitit),
						'one' => q({0} megabitti),
						'other' => q({0} megabittiä),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megatavut),
						'one' => q({0} megatavu),
						'other' => q({0} megatavua),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megatavut),
						'one' => q({0} megatavu),
						'other' => q({0} megatavua),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petatavut),
						'one' => q({0} petatavu),
						'other' => q({0} petatavua),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petatavut),
						'one' => q({0} petatavu),
						'other' => q({0} petatavua),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabitit),
						'one' => q({0} terabitti),
						'other' => q({0} terabittiä),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabitit),
						'one' => q({0} terabitti),
						'other' => q({0} terabittiä),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(teratavut),
						'one' => q({0} teratavu),
						'other' => q({0} teratavua),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(teratavut),
						'one' => q({0} teratavu),
						'other' => q({0} teratavua),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(vuosisadat),
						'one' => q({0} vuosisata),
						'other' => q({0} vuosisataa),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(vuosisadat),
						'one' => q({0} vuosisata),
						'other' => q({0} vuosisataa),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(päivät),
						'one' => q({0} päivä),
						'other' => q({0} päivää),
						'per' => q({0} / päivä),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(päivät),
						'one' => q({0} päivä),
						'other' => q({0} päivää),
						'per' => q({0} / päivä),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(vuosikymmenet),
						'one' => q({0} vuosikymmen),
						'other' => q({0} vuosikymmentä),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(vuosikymmenet),
						'one' => q({0} vuosikymmen),
						'other' => q({0} vuosikymmentä),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(tunnit),
						'one' => q({0} tunti),
						'other' => q({0} tuntia),
						'per' => q({0} / tunti),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(tunnit),
						'one' => q({0} tunti),
						'other' => q({0} tuntia),
						'per' => q({0} / tunti),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekunnit),
						'one' => q({0} mikrosekunti),
						'other' => q({0} mikrosekuntia),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekunnit),
						'one' => q({0} mikrosekunti),
						'other' => q({0} mikrosekuntia),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekunnit),
						'one' => q({0} millisekunti),
						'other' => q({0} millisekuntia),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekunnit),
						'one' => q({0} millisekunti),
						'other' => q({0} millisekuntia),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuutit),
						'one' => q({0} minuutti),
						'other' => q({0} minuuttia),
						'per' => q({0} / minuutti),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuutit),
						'one' => q({0} minuutti),
						'other' => q({0} minuuttia),
						'per' => q({0} / minuutti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(kuukaudet),
						'one' => q({0} kuukausi),
						'other' => q({0} kuukautta),
						'per' => q({0} / kuukausi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(kuukaudet),
						'one' => q({0} kuukausi),
						'other' => q({0} kuukautta),
						'per' => q({0} / kuukausi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekunnit),
						'one' => q({0} nanosekunti),
						'other' => q({0} nanosekuntia),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekunnit),
						'one' => q({0} nanosekunti),
						'other' => q({0} nanosekuntia),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(yöt),
						'one' => q({0} yö),
						'other' => q({0} yötä),
						'per' => q({0} / yö),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(yöt),
						'one' => q({0} yö),
						'other' => q({0} yötä),
						'per' => q({0} / yö),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(neljännekset),
						'one' => q({0} neljännes),
						'other' => q({0} neljännestä),
						'per' => q({0}/neljännes),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(neljännekset),
						'one' => q({0} neljännes),
						'other' => q({0} neljännestä),
						'per' => q({0}/neljännes),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekunnit),
						'one' => q({0} sekunti),
						'other' => q({0} sekuntia),
						'per' => q({0} / sekunti),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekunnit),
						'one' => q({0} sekunti),
						'other' => q({0} sekuntia),
						'per' => q({0} / sekunti),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(viikot),
						'one' => q({0} viikko),
						'other' => q({0} viikkoa),
						'per' => q({0} / viikko),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(viikot),
						'one' => q({0} viikko),
						'other' => q({0} viikkoa),
						'per' => q({0} / viikko),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vuodet),
						'one' => q({0} vuosi),
						'other' => q({0} vuotta),
						'per' => q({0} / vuosi),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vuodet),
						'one' => q({0} vuosi),
						'other' => q({0} vuotta),
						'per' => q({0} / vuosi),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampeerit),
						'one' => q({0} ampeeri),
						'other' => q({0} ampeeria),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampeerit),
						'one' => q({0} ampeeri),
						'other' => q({0} ampeeria),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliampeerit),
						'one' => q({0} milliampeeri),
						'other' => q({0} milliampeeria),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliampeerit),
						'one' => q({0} milliampeeri),
						'other' => q({0} milliampeeria),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohmit),
						'one' => q({0} ohmi),
						'other' => q({0} ohmia),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohmit),
						'one' => q({0} ohmi),
						'other' => q({0} ohmia),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(voltit),
						'one' => q({0} voltti),
						'other' => q({0} volttia),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(voltit),
						'one' => q({0} voltti),
						'other' => q({0} volttia),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(brittiläiset termiset yksiköt),
						'one' => q({0} brittiläinen terminen yksikkö),
						'other' => q({0} brittiläistä termistä yksikköä),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(brittiläiset termiset yksiköt),
						'one' => q({0} brittiläinen terminen yksikkö),
						'other' => q({0} brittiläistä termistä yksikköä),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalorit),
						'one' => q({0} kalori),
						'other' => q({0} kaloria),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalorit),
						'one' => q({0} kalori),
						'other' => q({0} kaloria),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronivoltit),
						'one' => q({0} elektronivoltti),
						'other' => q({0} elektronivolttia),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronivoltit),
						'one' => q({0} elektronivoltti),
						'other' => q({0} elektronivolttia),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kilokalorit),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloria),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kilokalorit),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloria),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joulet),
						'one' => q({0} joule),
						'other' => q({0} joulea),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joulet),
						'one' => q({0} joule),
						'other' => q({0} joulea),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalorit),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloria),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalorit),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloria),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoulet),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulea),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoulet),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulea),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowattitunnit),
						'one' => q({0} kilowattitunti),
						'other' => q({0} kilowattituntia),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowattitunnit),
						'one' => q({0} kilowattitunti),
						'other' => q({0} kilowattituntia),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowattitunnit / 100 kilometriä),
						'one' => q({0} kilowattitunti 100 kilometrillä),
						'other' => q({0} kilowattituntia 100 kilometrillä),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowattitunnit / 100 kilometriä),
						'one' => q({0} kilowattitunti 100 kilometrillä),
						'other' => q({0} kilowattituntia 100 kilometrillä),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtonit),
						'one' => q({0} newton),
						'other' => q({0} newtonia),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtonit),
						'one' => q({0} newton),
						'other' => q({0} newtonia),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pauna-voimat),
						'one' => q({0} pauna-voima),
						'other' => q({0} pauna-voimaa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pauna-voimat),
						'one' => q({0} pauna-voima),
						'other' => q({0} pauna-voimaa),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertsit),
						'one' => q({0} gigahertsi),
						'other' => q({0} gigahertsiä),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertsit),
						'one' => q({0} gigahertsi),
						'other' => q({0} gigahertsiä),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertsit),
						'one' => q({0} hertsi),
						'other' => q({0} hertsiä),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertsit),
						'one' => q({0} hertsi),
						'other' => q({0} hertsiä),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertsit),
						'one' => q({0} kilohertsi),
						'other' => q({0} kilohertsiä),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertsit),
						'one' => q({0} kilohertsi),
						'other' => q({0} kilohertsiä),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertsit),
						'one' => q({0} megahertsi),
						'other' => q({0} megahertsiä),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertsit),
						'one' => q({0} megahertsi),
						'other' => q({0} megahertsiä),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pisteet senttimetrillä),
						'one' => q({0} piste senttimetrillä),
						'other' => q({0} pistettä senttimetrillä),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pisteet senttimetrillä),
						'one' => q({0} piste senttimetrillä),
						'other' => q({0} pistettä senttimetrillä),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pisteet tuumalla),
						'one' => q({0} piste tuumalla),
						'other' => q({0} pistettä tuumalla),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pisteet tuumalla),
						'one' => q({0} piste tuumalla),
						'other' => q({0} pistettä tuumalla),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em-väli),
						'one' => q({0} em-väli),
						'other' => q({0} em-väliä),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em-väli),
						'one' => q({0} em-väli),
						'other' => q({0} em-väliä),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikselit),
						'one' => q({0} megapikseliä),
						'other' => q({0} megapikseliä),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikselit),
						'one' => q({0} megapikseliä),
						'other' => q({0} megapikseliä),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikselit),
						'one' => q({0} pikseli),
						'other' => q({0} pikseliä),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikselit),
						'one' => q({0} pikseli),
						'other' => q({0} pikseliä),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pikselit/senttimetri),
						'one' => q({0} pikseli / senttimetri),
						'other' => q({0} pikseliä / senttimetri),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pikselit/senttimetri),
						'one' => q({0} pikseli / senttimetri),
						'other' => q({0} pikseliä / senttimetri),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pikselit tuumalla),
						'one' => q({0} pikseli tuumalla),
						'other' => q({0} pikseliä tuumalla),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pikselit tuumalla),
						'one' => q({0} pikseli tuumalla),
						'other' => q({0} pikseliä tuumalla),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiset yksiköt),
						'one' => q({0} astronominen yksikkö),
						'other' => q({0} astronomista yksikköä),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiset yksiköt),
						'one' => q({0} astronominen yksikkö),
						'other' => q({0} astronomista yksikköä),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(senttimetrit),
						'one' => q({0} senttimetri),
						'other' => q({0} senttimetriä),
						'per' => q({0} / senttimetri),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(senttimetrit),
						'one' => q({0} senttimetri),
						'other' => q({0} senttimetriä),
						'per' => q({0} / senttimetri),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimetrit),
						'one' => q({0} desimetri),
						'other' => q({0} desimetriä),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimetrit),
						'one' => q({0} desimetri),
						'other' => q({0} desimetriä),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Maan säteet),
						'one' => q({0} Maan säde),
						'other' => q({0} Maan sädettä),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Maan säteet),
						'one' => q({0} Maan säde),
						'other' => q({0} Maan sädettä),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(sylet),
						'one' => q({0} syli),
						'other' => q({0} syltä),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(sylet),
						'one' => q({0} syli),
						'other' => q({0} syltä),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(jalat),
						'one' => q({0} jalka),
						'other' => q({0} jalkaa),
						'per' => q({0} / jalka),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(jalat),
						'one' => q({0} jalka),
						'other' => q({0} jalkaa),
						'per' => q({0} / jalka),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongit),
						'one' => q({0} furlong),
						'other' => q({0} furlongia),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongit),
						'one' => q({0} furlong),
						'other' => q({0} furlongia),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tuumat),
						'one' => q({0} tuuma),
						'other' => q({0} tuumaa),
						'per' => q({0} / tuuma),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tuumat),
						'one' => q({0} tuuma),
						'other' => q({0} tuumaa),
						'per' => q({0} / tuuma),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometrit),
						'one' => q({0} kilometri),
						'other' => q({0} kilometriä),
						'per' => q({0} / kilometri),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometrit),
						'one' => q({0} kilometri),
						'other' => q({0} kilometriä),
						'per' => q({0} / kilometri),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(valovuodet),
						'one' => q({0} valovuosi),
						'other' => q({0} valovuotta),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(valovuodet),
						'one' => q({0} valovuosi),
						'other' => q({0} valovuotta),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metrit),
						'one' => q({0} metri),
						'other' => q({0} metriä),
						'per' => q({0} / metri),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metrit),
						'one' => q({0} metri),
						'other' => q({0} metriä),
						'per' => q({0} / metri),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometrit),
						'one' => q({0} mikrometri),
						'other' => q({0} mikrometriä),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometrit),
						'one' => q({0} mikrometri),
						'other' => q({0} mikrometriä),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mailit),
						'one' => q({0} maili),
						'other' => q({0} mailia),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mailit),
						'one' => q({0} maili),
						'other' => q({0} mailia),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(peninkulmat),
						'one' => q({0} peninkulma),
						'other' => q({0} peninkulmaa),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(peninkulmat),
						'one' => q({0} peninkulma),
						'other' => q({0} peninkulmaa),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetrit),
						'one' => q({0} millimetri),
						'other' => q({0} millimetriä),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetrit),
						'one' => q({0} millimetri),
						'other' => q({0} millimetriä),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometrit),
						'one' => q({0} nanometri),
						'other' => q({0} nanometriä),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometrit),
						'one' => q({0} nanometri),
						'other' => q({0} nanometriä),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(meripeninkulmat),
						'one' => q({0} meripeninkulma),
						'other' => q({0} meripeninkulmaa),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(meripeninkulmat),
						'one' => q({0} meripeninkulma),
						'other' => q({0} meripeninkulmaa),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsekit),
						'one' => q({0} parsek),
						'other' => q({0} parsekia),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsekit),
						'one' => q({0} parsek),
						'other' => q({0} parsekia),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometrit),
						'one' => q({0} pikometri),
						'other' => q({0} pikometriä),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometrit),
						'one' => q({0} pikometri),
						'other' => q({0} pikometriä),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} auringon säde),
						'other' => q({0} auringon sädettä),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} auringon säde),
						'other' => q({0} auringon sädettä),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jaardit),
						'one' => q({0} jaardi),
						'other' => q({0} jaardia),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jaardit),
						'one' => q({0} jaardi),
						'other' => q({0} jaardia),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandelat),
						'one' => q({0} kandela),
						'other' => q({0} kandelaa),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandelat),
						'one' => q({0} kandela),
						'other' => q({0} kandelaa),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(luumenit),
						'one' => q({0} luumen),
						'other' => q({0} luumenia),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(luumenit),
						'one' => q({0} luumen),
						'other' => q({0} luumenia),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luksit),
						'one' => q({0} luksi),
						'other' => q({0} luksia),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luksit),
						'one' => q({0} luksi),
						'other' => q({0} luksia),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} Auringon luminositeetti),
						'other' => q({0} Auringon luminositeettia),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} Auringon luminositeetti),
						'other' => q({0} Auringon luminositeettia),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karaatit),
						'one' => q({0} karaatti),
						'other' => q({0} karaattia),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karaatit),
						'one' => q({0} karaatti),
						'other' => q({0} karaattia),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} atomimassayksikkö),
						'other' => q({0} atomimassayksikköä),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} atomimassayksikkö),
						'other' => q({0} atomimassayksikköä),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} Maan massa),
						'other' => q({0} Maan massaa),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} Maan massa),
						'other' => q({0} Maan massaa),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammat),
						'one' => q({0} gramma),
						'other' => q({0} grammaa),
						'per' => q({0} / gramma),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammat),
						'one' => q({0} gramma),
						'other' => q({0} grammaa),
						'per' => q({0} / gramma),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogrammat),
						'one' => q({0} kilogramma),
						'other' => q({0} kilogrammaa),
						'per' => q({0} / kilogramma),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogrammat),
						'one' => q({0} kilogramma),
						'other' => q({0} kilogrammaa),
						'per' => q({0} / kilogramma),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogrammat),
						'one' => q({0} mikrogramma),
						'other' => q({0} mikrogrammaa),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogrammat),
						'one' => q({0} mikrogramma),
						'other' => q({0} mikrogrammaa),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligrammat),
						'one' => q({0} milligramma),
						'other' => q({0} milligrammaa),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligrammat),
						'one' => q({0} milligramma),
						'other' => q({0} milligrammaa),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unssit),
						'one' => q({0} unssi),
						'other' => q({0} unssia),
						'per' => q({0} / unssi),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unssit),
						'one' => q({0} unssi),
						'other' => q({0} unssia),
						'per' => q({0} / unssi),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy-unssit),
						'one' => q({0} troy-unssi),
						'other' => q({0} troy-unssia),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy-unssit),
						'one' => q({0} troy-unssi),
						'other' => q({0} troy-unssia),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(paunat),
						'one' => q({0} pauna),
						'other' => q({0} paunaa),
						'per' => q({0} / pauna),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(paunat),
						'one' => q({0} pauna),
						'other' => q({0} paunaa),
						'per' => q({0} / pauna),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} auringon massa),
						'other' => q({0} auringon massaa),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} auringon massa),
						'other' => q({0} auringon massaa),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stonet),
						'one' => q({0} stone),
						'other' => q({0} stonea),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stonet),
						'one' => q({0} stone),
						'other' => q({0} stonea),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(am. tonnit),
						'one' => q({0} am. tonni),
						'other' => q({0} am. tonnia),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(am. tonnit),
						'one' => q({0} am. tonni),
						'other' => q({0} am. tonnia),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonnit),
						'one' => q({0} tonni),
						'other' => q({0} tonnia),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonnit),
						'one' => q({0} tonni),
						'other' => q({0} tonnia),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatit),
						'one' => q({0} gigawatti),
						'other' => q({0} gigawattia),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatit),
						'one' => q({0} gigawatti),
						'other' => q({0} gigawattia),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hevosvoimat),
						'one' => q({0} hevosvoima),
						'other' => q({0} hevosvoimaa),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hevosvoimat),
						'one' => q({0} hevosvoima),
						'other' => q({0} hevosvoimaa),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatit),
						'one' => q({0} kilowatti),
						'other' => q({0} kilowattia),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatit),
						'one' => q({0} kilowatti),
						'other' => q({0} kilowattia),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatit),
						'one' => q({0} megawatti),
						'other' => q({0} megawattia),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatit),
						'one' => q({0} megawatti),
						'other' => q({0} megawattia),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwatit),
						'one' => q({0} milliwatti),
						'other' => q({0} milliwattia),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwatit),
						'one' => q({0} milliwatti),
						'other' => q({0} milliwattia),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watit),
						'one' => q({0} watti),
						'other' => q({0} wattia),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watit),
						'one' => q({0} watti),
						'other' => q({0} wattia),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(neliö{0}),
						'one' => q(neliö{0}),
						'other' => q(neliö{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(neliö{0}),
						'one' => q(neliö{0}),
						'other' => q(neliö{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kuutio{0}),
						'one' => q(kuutio{0}),
						'other' => q(kuutio{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kuutio{0}),
						'one' => q(kuutio{0}),
						'other' => q(kuutio{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(normaali-ilmakehät),
						'one' => q({0} normaali-ilmakehä),
						'other' => q({0} normaali-ilmakehää),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(normaali-ilmakehät),
						'one' => q({0} normaali-ilmakehä),
						'other' => q({0} normaali-ilmakehää),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baarit),
						'one' => q({0} baari),
						'other' => q({0} baaria),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baarit),
						'one' => q({0} baari),
						'other' => q({0} baaria),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hehtopascalit),
						'one' => q({0} hehtopascal),
						'other' => q({0} hehtopascalia),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hehtopascalit),
						'one' => q({0} hehtopascal),
						'other' => q({0} hehtopascalia),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(elohopeatuumat),
						'one' => q({0} elohopeatuuma),
						'other' => q({0} elohopeatuumaa),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(elohopeatuumat),
						'one' => q({0} elohopeatuuma),
						'other' => q({0} elohopeatuumaa),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascalit),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalia),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascalit),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalia),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascalit),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalia),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascalit),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalia),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibaarit),
						'one' => q({0} millibaari),
						'other' => q({0} millibaaria),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibaarit),
						'one' => q({0} millibaari),
						'other' => q({0} millibaaria),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(elohopeamillimetrit),
						'one' => q({0} elohopeamillimetri),
						'other' => q({0} elohopeamillimetriä),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(elohopeamillimetrit),
						'one' => q({0} elohopeamillimetri),
						'other' => q({0} elohopeamillimetriä),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascalit),
						'one' => q({0} pascal),
						'other' => q({0} pascalia),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascalit),
						'one' => q({0} pascal),
						'other' => q({0} pascalia),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(paunat / neliötuuma),
						'one' => q({0} pauna / neliötuuma),
						'other' => q({0} paunaa / neliötuuma),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(paunat / neliötuuma),
						'one' => q({0} pauna / neliötuuma),
						'other' => q({0} paunaa / neliötuuma),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(bofori),
						'one' => q({0} bofori),
						'other' => q({0} boforia),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(bofori),
						'one' => q({0} bofori),
						'other' => q({0} boforia),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometrit tunnissa),
						'one' => q({0} kilometri tunnissa),
						'other' => q({0} kilometriä tunnissa),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometrit tunnissa),
						'one' => q({0} kilometri tunnissa),
						'other' => q({0} kilometriä tunnissa),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(solmut),
						'one' => q({0} solmu),
						'other' => q({0} solmua),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(solmut),
						'one' => q({0} solmu),
						'other' => q({0} solmua),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metrit sekunnissa),
						'one' => q({0} metri sekunnissa),
						'other' => q({0} metriä sekunnissa),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metrit sekunnissa),
						'one' => q({0} metri sekunnissa),
						'other' => q({0} metriä sekunnissa),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mailit tunnissa),
						'one' => q({0} maili tunnissa),
						'other' => q({0} mailia tunnissa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mailit tunnissa),
						'one' => q({0} maili tunnissa),
						'other' => q({0} mailia tunnissa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(celsiusasteet),
						'one' => q({0} celsiusaste),
						'other' => q({0} celsiusastetta),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(celsiusasteet),
						'one' => q({0} celsiusaste),
						'other' => q({0} celsiusastetta),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(fahrenheitasteet),
						'one' => q({0} fahrenheitaste),
						'other' => q({0} fahrenheitastetta),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(fahrenheitasteet),
						'one' => q({0} fahrenheitaste),
						'other' => q({0} fahrenheitastetta),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(asteet),
						'one' => q({0} aste),
						'other' => q({0} astetta),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(asteet),
						'one' => q({0} aste),
						'other' => q({0} astetta),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvinit),
						'one' => q({0} kelvin),
						'other' => q({0} kelviniä),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvinit),
						'one' => q({0} kelvin),
						'other' => q({0} kelviniä),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newtonmetrit),
						'one' => q({0} newtonmetri),
						'other' => q({0} newtonmetriä),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtonmetrit),
						'one' => q({0} newtonmetri),
						'other' => q({0} newtonmetriä),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pauna-jalat),
						'one' => q({0} pauna-jalka),
						'other' => q({0} pauna-jalkaa),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pauna-jalat),
						'one' => q({0} pauna-jalka),
						'other' => q({0} pauna-jalkaa),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(eekkerijalat),
						'one' => q({0} eekkerijalka),
						'other' => q({0} eekkerijalkaa),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(eekkerijalat),
						'one' => q({0} eekkerijalka),
						'other' => q({0} eekkerijalkaa),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} barreli),
						'other' => q({0} barrelia),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} barreli),
						'other' => q({0} barrelia),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushelit),
						'one' => q({0} busheli),
						'other' => q({0} bushelia),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushelit),
						'one' => q({0} busheli),
						'other' => q({0} bushelia),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(senttilitrat),
						'one' => q({0} senttilitra),
						'other' => q({0} senttilitraa),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(senttilitrat),
						'one' => q({0} senttilitra),
						'other' => q({0} senttilitraa),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kuutiosenttimetrit),
						'one' => q({0} kuutiosenttimetri),
						'other' => q({0} kuutiosenttimetriä),
						'per' => q({0} / kuutiosenttimetri),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kuutiosenttimetrit),
						'one' => q({0} kuutiosenttimetri),
						'other' => q({0} kuutiosenttimetriä),
						'per' => q({0} / kuutiosenttimetri),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kuutiojalat),
						'one' => q({0} kuutiojalka),
						'other' => q({0} kuutiojalkaa),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kuutiojalat),
						'one' => q({0} kuutiojalka),
						'other' => q({0} kuutiojalkaa),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kuutiotuumat),
						'one' => q({0} kuutiotuuma),
						'other' => q({0} kuutiotuumaa),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kuutiotuumat),
						'one' => q({0} kuutiotuuma),
						'other' => q({0} kuutiotuumaa),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kuutiokilometrit),
						'one' => q({0} kuutiokilometri),
						'other' => q({0} kuutiokilometriä),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kuutiokilometrit),
						'one' => q({0} kuutiokilometri),
						'other' => q({0} kuutiokilometriä),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kuutiometrit),
						'one' => q({0} kuutiometri),
						'other' => q({0} kuutiometriä),
						'per' => q({0} / kuutiometri),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kuutiometrit),
						'one' => q({0} kuutiometri),
						'other' => q({0} kuutiometriä),
						'per' => q({0} / kuutiometri),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kuutiomailit),
						'one' => q({0} kuutiomaili),
						'other' => q({0} kuutiomailia),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kuutiomailit),
						'one' => q({0} kuutiomaili),
						'other' => q({0} kuutiomailia),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kuutiojaardit),
						'one' => q({0} kuutiojaardi),
						'other' => q({0} kuutiojaardia),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kuutiojaardit),
						'one' => q({0} kuutiojaardi),
						'other' => q({0} kuutiojaardia),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kupit),
						'one' => q({0} kuppi),
						'other' => q({0} kuppia),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kupit),
						'one' => q({0} kuppi),
						'other' => q({0} kuppia),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(teekupit),
						'one' => q({0} teekuppi),
						'other' => q({0} teekuppia),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(teekupit),
						'one' => q({0} teekuppi),
						'other' => q({0} teekuppia),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitrat),
						'one' => q({0} desilitra),
						'other' => q({0} desilitraa),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitrat),
						'one' => q({0} desilitra),
						'other' => q({0} desilitraa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(jälkiruokalusikat),
						'one' => q({0} jälkiruokalusikka),
						'other' => q({0} jälkiruokalusikkaa),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(jälkiruokalusikat),
						'one' => q({0} jälkiruokalusikka),
						'other' => q({0} jälkiruokalusikkaa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(br. jälkiruokalusikat),
						'one' => q({0} br. jälkiruokalusikka),
						'other' => q({0} br. jälkiruokalusikkaa),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(br. jälkiruokalusikat),
						'one' => q({0} br. jälkiruokalusikka),
						'other' => q({0} br. jälkiruokalusikkaa),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(nesteunssit),
						'one' => q({0} nesteunssi),
						'other' => q({0} nesteunssia),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(nesteunssit),
						'one' => q({0} nesteunssi),
						'other' => q({0} nesteunssia),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(br. nesteunssit),
						'one' => q({0} br. nesteunssi),
						'other' => q({0} br. nesteunssia),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(br. nesteunssit),
						'one' => q({0} br. nesteunssi),
						'other' => q({0} br. nesteunssia),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(am. gallonat),
						'one' => q({0} am. gallona),
						'other' => q({0} am. gallonaa),
						'per' => q({0} / am. gallona),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(am. gallonat),
						'one' => q({0} am. gallona),
						'other' => q({0} am. gallonaa),
						'per' => q({0} / am. gallona),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(br. gallonat),
						'one' => q({0} br. gallona),
						'other' => q({0} br. gallonaa),
						'per' => q({0} / br. gallona),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(br. gallonat),
						'one' => q({0} br. gallona),
						'other' => q({0} br. gallonaa),
						'per' => q({0} / br. gallona),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hehtolitrat),
						'one' => q({0} hehtolitra),
						'other' => q({0} hehtolitraa),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hehtolitrat),
						'one' => q({0} hehtolitra),
						'other' => q({0} hehtolitraa),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litrat),
						'one' => q({0} litra),
						'other' => q({0} litraa),
						'per' => q({0} / litra),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litrat),
						'one' => q({0} litra),
						'other' => q({0} litraa),
						'per' => q({0} / litra),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitrat),
						'one' => q({0} megalitra),
						'other' => q({0} megalitraa),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitrat),
						'one' => q({0} megalitra),
						'other' => q({0} megalitraa),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitrat),
						'one' => q({0} millilitra),
						'other' => q({0} millilitraa),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitrat),
						'one' => q({0} millilitra),
						'other' => q({0} millilitraa),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintit),
						'one' => q({0} pint),
						'other' => q({0} pinttiä),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintit),
						'one' => q({0} pint),
						'other' => q({0} pinttiä),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(tuopit),
						'one' => q({0} tuoppi),
						'other' => q({0} tuoppia),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(tuopit),
						'one' => q({0} tuoppi),
						'other' => q({0} tuoppia),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(neljännesgallonat),
						'one' => q({0} neljännesgallona),
						'other' => q({0} neljännesgallonaa),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(neljännesgallonat),
						'one' => q({0} neljännesgallona),
						'other' => q({0} neljännesgallonaa),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(br. neljännesgallonat),
						'one' => q({0} br. neljännesgallona),
						'other' => q({0} br. neljännesgallonaa),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(br. neljännesgallonat),
						'one' => q({0} br. neljännesgallona),
						'other' => q({0} br. neljännesgallonaa),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ruokalusikat),
						'one' => q({0} ruokalusikka),
						'other' => q({0} ruokalusikkaa),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ruokalusikat),
						'one' => q({0} ruokalusikka),
						'other' => q({0} ruokalusikkaa),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(teelusikat),
						'one' => q({0} teelusikka),
						'other' => q({0} teelusikkaa),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(teelusikat),
						'one' => q({0} teelusikka),
						'other' => q({0} teelusikkaa),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(suunta),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(suunta),
					},
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
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}rev),
						'other' => q({0}rev),
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
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
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
						'one' => q({0} kohde),
						'other' => q({0} kohdetta),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0} kohde),
						'other' => q({0} kohdetta),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}ka),
						'other' => q({0}ka),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}ka),
						'other' => q({0}ka),
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
						'name' => q(mol),
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
						'one' => q({0}mol),
						'other' => q({0}mol),
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
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0}mpg-am),
						'other' => q({0}mpg-am),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0}mpg-am),
						'other' => q({0}mpg-am),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0}mpg-br),
						'other' => q({0}mpg-br),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mpg-br),
						'other' => q({0}mpg-br),
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
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0}t),
						'other' => q({0}t),
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
						'one' => q({0}Gt),
						'other' => q({0}Gt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0}Gt),
						'other' => q({0}Gt),
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
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}kt),
						'other' => q({0}kt),
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
						'one' => q({0}Mt),
						'other' => q({0}Mt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}Mt),
						'other' => q({0}Mt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}Pt),
						'other' => q({0}Pt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q({0}Pt),
						'other' => q({0}Pt),
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
						'one' => q({0}Tt),
						'other' => q({0}Tt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}Tt),
						'other' => q({0}Tt),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}pv),
						'other' => q({0}pv),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}pv),
						'other' => q({0}pv),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'hour' => {
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
						'one' => q({0}kk),
						'other' => q({0}kk),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}kk),
						'other' => q({0}kk),
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
						'name' => q(yöt),
						'one' => q({0}yö),
						'other' => q({0}yöt),
						'per' => q({0}/yö),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(yöt),
						'one' => q({0}yö),
						'other' => q({0}yöt),
						'per' => q({0}/yö),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0}vk),
						'other' => q({0}vk),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}vk),
						'other' => q({0}vk),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}v),
						'other' => q({0}v),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}v),
						'other' => q({0}v),
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
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
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
						'one' => q({0}US therm),
						'other' => q({0}US therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}US therm),
						'other' => q({0}US therm),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100 km),
						'other' => q({0}kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100 km),
						'other' => q({0}kWh/100 km),
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
						'name' => q(piste),
						'one' => q({0}piste),
						'other' => q({0}pistettä),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(piste),
						'one' => q({0}piste),
						'other' => q({0}pistettä),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
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
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/′),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/′),
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
						'per' => q({0}/″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/″),
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
						'one' => q({0}vv),
						'other' => q({0}vv),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}vv),
						'other' => q({0}vv),
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
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}pnk),
						'other' => q({0}pnk),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}pnk),
						'other' => q({0}pnk),
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
						'one' => q({0}mpk),
						'other' => q({0}mpk),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}mpk),
						'other' => q({0}mpk),
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
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
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
					'mass-carat' => {
						'one' => q({0}ka),
						'other' => q({0}ka),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}ka),
						'other' => q({0}ka),
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
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0}graani),
						'other' => q({0}graania),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}graani),
						'other' => q({0}graania),
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
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
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
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
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
						'name' => q(am.tn),
						'one' => q({0}am.tn),
						'other' => q({0}am.tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(am.tn),
						'one' => q({0}am.tn),
						'other' => q({0}am.tn),
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
						'one' => q({0}hv),
						'other' => q({0}hv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hv),
						'other' => q({0}hv),
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
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
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
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
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
						'one' => q({0}kp),
						'other' => q({0}kp),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}kp),
						'other' => q({0}kp),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}tkp),
						'other' => q({0}tkp),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}tkp),
						'other' => q({0}tkp),
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
						'one' => q({0}jrkl),
						'other' => q({0}jrkl),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0}jrkl),
						'other' => q({0}jrkl),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0}dram),
						'other' => q({0}dramia),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0}dram),
						'other' => q({0}dramia),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gtt),
						'one' => q({0}gtt),
						'other' => q({0}gtt),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gtt),
						'one' => q({0}gtt),
						'other' => q({0}gtt),
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
						'one' => q({0}fl oz br.),
						'other' => q({0}fl oz br.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz br.),
						'other' => q({0}fl oz br.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(am.gal),
						'one' => q({0}am.gal),
						'other' => q({0}am.gal),
						'per' => q({0}/am.gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(am.gal),
						'one' => q({0}am.gal),
						'other' => q({0}am.gal),
						'per' => q({0}/am.gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(br.gal),
						'one' => q({0}br.gal),
						'other' => q({0}br.gal),
						'per' => q({0}/br.gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(br.gal),
						'one' => q({0}br.gal),
						'other' => q({0}br.gal),
						'per' => q({0}/br.gal),
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
						'other' => q({0}jiggeriä),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}jigger),
						'other' => q({0}jiggeriä),
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
						'one' => q({0}ripaus),
						'other' => q({0}ripausta),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0}ripaus),
						'other' => q({0}ripausta),
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
						'one' => q({0}tp),
						'other' => q({0}tp),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}tp),
						'other' => q({0}tp),
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
						'one' => q({0}qt br.),
						'other' => q({0}qt br.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}qt br.),
						'other' => q({0}qt br.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}rkl),
						'other' => q({0}rkl),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}rkl),
						'other' => q({0}rkl),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tl),
						'other' => q({0}tl),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tl),
						'other' => q({0}tl),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ilmansuunta),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ilmansuunta),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
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
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunamit),
						'one' => q({0} dunam),
						'other' => q({0} dunamia),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunamit),
						'one' => q({0} dunam),
						'other' => q({0} dunamia),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(kohde),
						'one' => q({0} kohde),
						'other' => q({0} kohde),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(kohde),
						'one' => q({0} kohde),
						'other' => q({0} kohde),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ka),
						'one' => q({0} ka),
						'other' => q({0} ka),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ka),
						'one' => q({0} ka),
						'other' => q({0} ka),
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
					'concentr-mole' => {
						'name' => q(mooli),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mooli),
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
					'concentr-permyriad' => {
						'name' => q(peruspiste),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(peruspiste),
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
						'name' => q(mpg-am),
						'one' => q({0} mpg-am),
						'other' => q({0} mpg-am),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg-am),
						'one' => q({0} mpg-am),
						'other' => q({0} mpg-am),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg-br),
						'one' => q({0} mpg-br),
						'other' => q({0} mpg-br),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg-br),
						'one' => q({0} mpg-br),
						'other' => q({0} mpg-br),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}P),
						'south' => q({0}E),
						'west' => q({0}L),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}P),
						'south' => q({0}E),
						'west' => q({0}L),
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
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Gt),
						'one' => q({0} Gt),
						'other' => q({0} Gt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Gt),
						'one' => q({0} Gt),
						'other' => q({0} Gt),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mt),
						'one' => q({0} Mt),
						'other' => q({0} Mt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mt),
						'one' => q({0} Mt),
						'other' => q({0} Mt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Pt),
						'one' => q({0} Pt),
						'other' => q({0} Pt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Pt),
						'one' => q({0} Pt),
						'other' => q({0} Pt),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(Tt),
						'one' => q({0} Tt),
						'other' => q({0} Tt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(Tt),
						'one' => q({0} Tt),
						'other' => q({0} Tt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(vs),
						'one' => q({0} vs),
						'other' => q({0} vs),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(vs),
						'one' => q({0} vs),
						'other' => q({0} vs),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(pv),
						'one' => q({0} pv),
						'other' => q({0} pv),
						'per' => q({0}/pv),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(pv),
						'one' => q({0} pv),
						'other' => q({0} pv),
						'per' => q({0}/pv),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(kk),
						'one' => q({0} kk),
						'other' => q({0} kk),
						'per' => q({0}/kk),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(kk),
						'one' => q({0} kk),
						'other' => q({0} kk),
						'per' => q({0}/kk),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(yöt),
						'one' => q({0} yö),
						'other' => q({0} yö),
						'per' => q({0}/yö),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(yöt),
						'one' => q({0} yö),
						'other' => q({0} yö),
						'per' => q({0}/yö),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(q),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(q),
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
						'name' => q(vk),
						'one' => q({0} vk),
						'other' => q({0} vk),
						'per' => q({0}/vk),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vk),
						'one' => q({0} vk),
						'other' => q({0} vk),
						'per' => q({0}/vk),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(v),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(v),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
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
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronivoltti),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronivoltti),
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
						'name' => q(pauna-voima),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pauna-voima),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pisteet),
						'one' => q({0} piste),
						'other' => q({0} pistettä),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pisteet),
						'one' => q({0} piste),
						'other' => q({0} pistettä),
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
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(vv),
						'one' => q({0} vv),
						'other' => q({0} vv),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(vv),
						'one' => q({0} vv),
						'other' => q({0} vv),
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
					'length-mile-scandinavian' => {
						'name' => q(pnk),
						'one' => q({0} pnk),
						'other' => q({0} pnk),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(pnk),
						'one' => q({0} pnk),
						'other' => q({0} pnk),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mpk),
						'one' => q({0} mpk),
						'other' => q({0} mpk),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mpk),
						'one' => q({0} mpk),
						'other' => q({0} mpk),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(auringon säteet),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(auringon säteet),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(Auringon luminositeetit),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Auringon luminositeetit),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ka),
						'one' => q({0} ka),
						'other' => q({0} ka),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ka),
						'one' => q({0} ka),
						'other' => q({0} ka),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(atomimassayksiköt),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(atomimassayksiköt),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Maan massat),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Maan massat),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(graanit),
						'one' => q({0} graani),
						'other' => q({0} graania),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(graanit),
						'one' => q({0} graani),
						'other' => q({0} graania),
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
					'mass-solar-mass' => {
						'name' => q(auringon massat),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(auringon massat),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(am. tn),
						'one' => q({0} am. tn),
						'other' => q({0} am. tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(am. tn),
						'one' => q({0} am. tn),
						'other' => q({0} am. tn),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hv),
						'one' => q({0} hv),
						'other' => q({0} hv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hv),
						'one' => q({0} hv),
						'other' => q({0} hv),
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
					'volume-barrel' => {
						'name' => q(barrelit),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrelit),
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
						'name' => q(kp),
						'one' => q({0} kp),
						'other' => q({0} kp),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kp),
						'one' => q({0} kp),
						'other' => q({0} kp),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(tkp),
						'one' => q({0} tkp),
						'other' => q({0} tkp),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(tkp),
						'one' => q({0} tkp),
						'other' => q({0} tkp),
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
						'name' => q(jrkl),
						'one' => q({0} jrkl),
						'other' => q({0} jrkl),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(jrkl),
						'one' => q({0} jrkl),
						'other' => q({0} jrkl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(br. jrkl),
						'one' => q({0} br. jrkl),
						'other' => q({0} br. jrkl),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(br. jrkl),
						'one' => q({0} br. jrkl),
						'other' => q({0} br. jrkl),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dramit),
						'one' => q({0} dram),
						'other' => q({0} dramia),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dramit),
						'one' => q({0} dram),
						'other' => q({0} dramia),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tipat),
						'one' => q({0} tippa),
						'other' => q({0} tippaa),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tipat),
						'one' => q({0} tippa),
						'other' => q({0} tippaa),
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
						'name' => q(br. nesteunssi),
						'one' => q({0} fl oz br.),
						'other' => q({0} fl oz br.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(br. nesteunssi),
						'one' => q({0} fl oz br.),
						'other' => q({0} fl oz br.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(am. gal),
						'one' => q({0} am. gal),
						'other' => q({0} am. gal),
						'per' => q({0}/am. gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(am. gal),
						'one' => q({0} am. gal),
						'other' => q({0} am. gal),
						'per' => q({0}/am. gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(br. gal),
						'one' => q({0} br. gal),
						'other' => q({0} br. gal),
						'per' => q({0}/br. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(br. gal),
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
						'name' => q(jiggerit),
						'one' => q({0} jigger),
						'other' => q({0} jiggeriä),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jiggerit),
						'one' => q({0} jigger),
						'other' => q({0} jiggeriä),
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
						'name' => q(ripaus),
						'one' => q({0} ripaus),
						'other' => q({0} ripausta),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ripaus),
						'one' => q({0} ripaus),
						'other' => q({0} ripausta),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(tp),
						'one' => q({0} tp),
						'other' => q({0} tp),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(tp),
						'one' => q({0} tp),
						'other' => q({0} tp),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt br),
						'one' => q({0} qt br.),
						'other' => q({0} qt br.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt br),
						'one' => q({0} qt br.),
						'other' => q({0} qt br.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(rkl),
						'one' => q({0} rkl),
						'other' => q({0} rkl),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(rkl),
						'one' => q({0} rkl),
						'other' => q({0} rkl),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:kyllä|k|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ei|e|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} ja {1}),
				2 => q({0} ja {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'minusSign' => q(−),
			'nan' => q(epäluku),
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
					'one' => '0 tuhat',
					'other' => '0 tuhatta',
				},
				'10000' => {
					'one' => '00 tuhatta',
					'other' => '00 tuhatta',
				},
				'100000' => {
					'one' => '000 tuhatta',
					'other' => '000 tuhatta',
				},
				'1000000' => {
					'one' => '0 miljoona',
					'other' => '0 miljoonaa',
				},
				'10000000' => {
					'one' => '00 miljoonaa',
					'other' => '00 miljoonaa',
				},
				'100000000' => {
					'one' => '000 miljoonaa',
					'other' => '000 miljoonaa',
				},
				'1000000000' => {
					'one' => '0 miljardi',
					'other' => '0 miljardia',
				},
				'10000000000' => {
					'one' => '00 miljardia',
					'other' => '00 miljardia',
				},
				'100000000000' => {
					'one' => '000 miljardia',
					'other' => '000 miljardia',
				},
				'1000000000000' => {
					'one' => '0 biljoona',
					'other' => '0 biljoonaa',
				},
				'10000000000000' => {
					'one' => '00 biljoonaa',
					'other' => '00 biljoonaa',
				},
				'100000000000000' => {
					'one' => '000 biljoonaa',
					'other' => '000 biljoonaa',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 t'.'',
					'other' => '0 t'.'',
				},
				'10000' => {
					'one' => '00 t'.'',
					'other' => '00 t'.'',
				},
				'100000' => {
					'one' => '000 t'.'',
					'other' => '000 t'.'',
				},
				'1000000' => {
					'one' => '0 milj'.'',
					'other' => '0 milj'.'',
				},
				'10000000' => {
					'one' => '00 milj'.'',
					'other' => '00 milj'.'',
				},
				'100000000' => {
					'one' => '000 milj'.'',
					'other' => '000 milj'.'',
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
					'one' => '0 bilj'.'',
					'other' => '0 bilj'.'',
				},
				'10000000000000' => {
					'one' => '00 bilj'.'',
					'other' => '00 bilj'.'',
				},
				'100000000000000' => {
					'one' => '000 bilj'.'',
					'other' => '000 bilj'.'',
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
				'currency' => q(Andorran peseta),
				'one' => q(Andorran peseta),
				'other' => q(Andorran pesetaa),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Arabiemiirikuntien dirhami),
				'one' => q(Arabiemiirikuntien dirhami),
				'other' => q(Arabiemiirikuntien dirhamia),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afganistanin afgaani \(1927–2002\)),
				'one' => q(Afganistanin afgaani \(1927–2002\)),
				'other' => q(Afganistanin afgaania \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afganistanin afgaani),
				'one' => q(Afganistanin afgaani),
				'other' => q(Afganistanin afgaania),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albanian lek \(1946–1965\)),
				'one' => q(Albanian lek \(1946–1965\)),
				'other' => q(Albanian lekiä \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanian lek),
				'one' => q(Albanian lek),
				'other' => q(Albanian lekiä),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenian dram),
				'one' => q(Armenian dram),
				'other' => q(Armenian dramia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Alankomaiden Antillien guldeni),
				'one' => q(Alankomaiden Antillien guldeni),
				'other' => q(Alankomaiden Antillien guldenia),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angolan kwanza),
				'one' => q(Angolan kwanza),
				'other' => q(Angolan kwanzaa),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolan kwanza \(1977–1991\)),
				'one' => q(Angolan kwanza \(1977–1990\)),
				'other' => q(Angolan kwanzaa \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolan uusi kwanza \(1990–2000\)),
				'one' => q(Angolan uusi kwanza \(1990–2000\)),
				'other' => q(Angolan uutta kwanzaa \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolan kwanza reajustado \(1995–1999\)),
				'one' => q(Angolan kwanza reajustado \(1995–1999\)),
				'other' => q(Angolan kwanza reajustadoa \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentiinan austral),
				'one' => q(Argentiinan austral),
				'other' => q(Argentiinan australia),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Argentiinan ley-peso \(1970–1983\)),
				'one' => q(Argentiinan ley-peso \(1970–1983\)),
				'other' => q(Argentiinan ley-pesoa \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentiinan peso \(1881–1970\)),
				'one' => q(Argentiinan peso \(1881–1970\)),
				'other' => q(Argentiinan pesoa \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentiinan peso \(1983–1985\)),
				'one' => q(Argentiinan peso \(1983–1985\)),
				'other' => q(Argentiinan pesoa \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentiinan peso),
				'one' => q(Argentiinan peso),
				'other' => q(Argentiinan pesoa),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Itävallan šillinki),
				'one' => q(Itävallan šillinki),
				'other' => q(Itävallan šillinkiä),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(Australian dollari),
				'one' => q(Australian dollari),
				'other' => q(Australian dollaria),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruban floriini),
				'one' => q(Aruban floriini),
				'other' => q(Aruban floriinia),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbaidžanin manat \(1993–2006\)),
				'one' => q(Azerbaidžanin manat \(1993–2006\)),
				'other' => q(Azerbaidžanin manatia \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaidžanin manat),
				'one' => q(Azerbaidžanin manat),
				'other' => q(Azerbaidžanin manatia),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnia-Hertsegovinan dinaari \(1992–1994\)),
				'one' => q(Bosnia-Hertsegovinan dinaari \(1992–1994\)),
				'other' => q(Bosnia-Hertsegovinan dinaaria \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosnia-Hertsegovinan vaihdettava markka),
				'one' => q(Bosnia-Hertsegovinan vaihdettava markka),
				'other' => q(Bosnia-Hertsegovinan vaihdettavaa markkaa),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Bosnia-Hertsegovinan uusi dinaari \(1994–1997\)),
				'one' => q(Bosnia-Hertsegovinan uusi dinaari \(1994–1997\)),
				'other' => q(Bosnia-Hertsegovinan uutta dinaaria \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbadosin dollari),
				'one' => q(Barbadosin dollari),
				'other' => q(Barbadosin dollaria),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladeshin taka),
				'one' => q(Bangladeshin taka),
				'other' => q(Bangladeshin takaa),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgian vaihdettava frangi),
				'one' => q(Belgian vaihdettava frangi),
				'other' => q(Belgian vaihdettavaa frangia),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgian frangi),
				'one' => q(Belgian frangi),
				'other' => q(Belgian frangia),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgian rahoitusfrangi),
				'one' => q(Belgian rahoitusfrangi),
				'other' => q(Belgian rahoitusfrangia),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgarian kova lev),
				'one' => q(Bulgarian kova lev),
				'other' => q(Bulgarian kovaa leviä),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Bulgarian sosialistinen lev),
				'one' => q(Bulgarian sosialistinen lev),
				'other' => q(Bulgarian sosialistista leviä),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarian lev),
				'one' => q(Bulgarian lev),
				'other' => q(Bulgarian leviä),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bulgarian lev \(1879–1952\)),
				'one' => q(Bulgarian lev \(1879–1952\)),
				'other' => q(Bulgarian leviä \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrainin dinaari),
				'one' => q(Bahrainin dinaari),
				'other' => q(Bahrainin dinaaria),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundin frangi),
				'one' => q(Burundin frangi),
				'other' => q(Burundin frangia),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermudan dollari),
				'one' => q(Bermudan dollari),
				'other' => q(Bermudan dollaria),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunein dollari),
				'one' => q(Brunein dollari),
				'other' => q(Brunein dollaria),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolivian boliviano),
				'one' => q(Bolivian boliviano),
				'other' => q(Bolivian bolivianoa),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Bolivian boliviano \(1863–1963\)),
				'one' => q(Bolivian boliviano \(1863–1963\)),
				'other' => q(Bolivian bolivianoa \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivian peso),
				'one' => q(Bolivian peso),
				'other' => q(Bolivian pesoa),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivian mvdol),
				'one' => q(Bolivian mvdol),
				'other' => q(Bolivian mvdol’ia),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brasilian uusi cruzeiro \(1967–1986\)),
				'one' => q(Brasilian uusi cruzeiro \(1967–1986\)),
				'other' => q(Brasilian uutta cruzeiroa \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brasilian cruzado \(1986–1989\)),
				'one' => q(Brasilian cruzado \(1986–1989\)),
				'other' => q(Brasilian cruzadoa \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brasilian cruzeiro \(1990–1993\)),
				'one' => q(Brasilian cruzeiro \(1990–1993\)),
				'other' => q(Brasilian cruzeiroa \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(Brasilian real),
				'one' => q(Brasilian real),
				'other' => q(Brasilian realia),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brasilian uusi cruzado \(1989–1990\)),
				'one' => q(Brasilian uusi cruzado \(1989–1990\)),
				'other' => q(Brasilian uutta cruzadoa \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brasilian cruzeiro \(1993–1994\)),
				'one' => q(Brasilian cruzeiro \(1993–1994\)),
				'other' => q(Brasilian cruzeiroa \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brasilian cruzeiro \(1942–1967\)),
				'one' => q(Brasilian cruzeiro \(1942–1967\)),
				'other' => q(Brasilian cruzeiroa \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahaman dollari),
				'one' => q(Bahaman dollari),
				'other' => q(Bahaman dollaria),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutanin ngultrum),
				'one' => q(Bhutanin ngultrum),
				'other' => q(Bhutanin ngultrumia),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burman kyat),
				'one' => q(Burman kyat),
				'other' => q(Burman kyatia),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botswanan pula),
				'one' => q(Botswanan pula),
				'other' => q(Botswanan pulaa),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Valko-Venäjän uusi rupla \(1994–1999\)),
				'one' => q(Valko-Venäjän uusi rupla \(1994–1999\)),
				'other' => q(Valko-Venäjän uutta ruplaa \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Valko-Venäjän rupla),
				'one' => q(Valko-Venäjän rupla),
				'other' => q(Valko-Venäjän ruplaa),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Valko-Venäjän rupla \(2000–2016\)),
				'one' => q(Valko-Venäjän rupla \(2000–2016\)),
				'other' => q(Valko-Venäjän ruplaa \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Belizen dollari),
				'one' => q(Belizen dollari),
				'other' => q(Belizen dollaria),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Kanadan dollari),
				'one' => q(Kanadan dollari),
				'other' => q(Kanadan dollaria),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongon frangi),
				'one' => q(Kongon frangi),
				'other' => q(Kongon frangia),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Sveitsin WIR-euro),
				'one' => q(Sveitsin WIR-euro),
				'other' => q(Sveitsin WIR-euroa),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Sveitsin frangi),
				'one' => q(Sveitsin frangi),
				'other' => q(Sveitsin frangia),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Sveitsin WIR-frangi),
				'one' => q(Sveitsin WIR-frangi),
				'other' => q(Sveitsin WIR-frangia),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Chilen escudo),
				'one' => q(Chilen escudo),
				'other' => q(Chilen escudoa),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chilen unidades de fomento),
				'one' => q(Chilen unidades de fomento),
				'other' => q(Chilen unidades de fomentoa),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Chilen peso),
				'one' => q(Chilen peso),
				'other' => q(Chilen pesoa),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Kiinan juan \(offshore\)),
				'one' => q(Kiinan juan \(offshore\)),
				'other' => q(Kiinan juania \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Kiinan kansanpankin dollari),
				'one' => q(Kiinan kansanpankin dollari),
				'other' => q(Kiinan kansanpankin dollaria),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(Kiinan juan),
				'one' => q(Kiinan juan),
				'other' => q(Kiinan juania),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolumbian peso),
				'one' => q(Kolumbian peso),
				'other' => q(Kolumbian pesoa),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Kolumbian unidad de valor real),
				'one' => q(Kolumbian unidad de valor real),
				'other' => q(Kolumbian unidad de valor realia),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Costa Rican colón),
				'one' => q(Costa Rican colón),
				'other' => q(Costa Rican colónia),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbian dinaari \(2002–2006\)),
				'one' => q(Serbian dinaari \(2002–2006\)),
				'other' => q(Serbian dinaaria \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tšekkoslovakian kova koruna),
				'one' => q(Tšekkoslovakian kova koruna),
				'other' => q(Tšekkoslovakian kovaa korunaa),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kuuban vaihdettava peso),
				'one' => q(Kuuban vaihdettava peso),
				'other' => q(Kuuban vaihdettavaa pesoa),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuuban peso),
				'one' => q(Kuuban peso),
				'other' => q(Kuuban pesoa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kap Verden escudo),
				'one' => q(Kap Verden escudo),
				'other' => q(Kap Verden escudoa),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kyproksen punta),
				'one' => q(Kyproksen punta),
				'other' => q(Kyproksen puntaa),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Tšekin koruna),
				'one' => q(Tšekin koruna),
				'other' => q(Tšekin korunaa),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Itä-Saksan markka),
				'one' => q(Itä-Saksan markka),
				'other' => q(Itä-Saksan markkaa),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Saksan markka),
				'one' => q(Saksan markka),
				'other' => q(Saksan markkaa),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutin frangi),
				'one' => q(Djiboutin frangi),
				'other' => q(Djiboutin frangia),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Tanskan kruunu),
				'one' => q(Tanskan kruunu),
				'other' => q(Tanskan kruunua),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikaanisen tasavallan peso),
				'one' => q(Dominikaanisen tasavallan peso),
				'other' => q(Dominikaanisen tasavallan pesoa),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian dinaari),
				'one' => q(Algerian dinaari),
				'other' => q(Algerian dinaaria),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadorin sucre),
				'one' => q(Ecuadorin sucre),
				'other' => q(Ecuadorin sucrea),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ecuadorin UVC),
				'one' => q(Ecuadorin UVC),
				'other' => q(Ecuadorin UVC’ta),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Viron kruunu),
				'one' => q(Viron kruunu),
				'other' => q(Viron kruunua),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Egyptin punta),
				'one' => q(Egyptin punta),
				'other' => q(Egyptin puntaa),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrean nakfa),
				'one' => q(Eritrean nakfa),
				'other' => q(Eritrean nakfaa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Espanjan peseta \(A-tili\)),
				'one' => q(Espanjan peseta \(A-tili\)),
				'other' => q(Espanjan pesetaa \(A-tili\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Espanjan peseta \(vaihdettava tili\)),
				'one' => q(Espanjan peseta \(vaihdettava tili\)),
				'other' => q(Espanjan pesetaa \(vaihdettava tili\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(Espanjan peseta),
				'one' => q(Espanjan peseta),
				'other' => q(Espanjan pesetaa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etiopian birr),
				'one' => q(Etiopian birr),
				'other' => q(Etiopian birriä),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euroa),
			},
		},
		'FIM' => {
			symbol => 'mk',
			display_name => {
				'currency' => q(Suomen markka),
				'one' => q(Suomen markka),
				'other' => q(Suomen markkaa),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fidžin dollari),
				'one' => q(Fidžin dollari),
				'other' => q(Fidžin dollaria),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Falklandinsaarten punta),
				'one' => q(Falklandinsaarten punta),
				'other' => q(Falklandinsaarten puntaa),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Ranskan frangi),
				'one' => q(Ranskan frangi),
				'other' => q(Ranskan frangia),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Englannin punta),
				'one' => q(Englannin punta),
				'other' => q(Englannin puntaa),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgian kuponkilari),
				'one' => q(Georgian kuponkilari),
				'other' => q(Georgian kuponkilaria),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Georgian lari),
				'one' => q(Georgian lari),
				'other' => q(Georgian laria),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanan cedi \(1979–2007\)),
				'one' => q(Ghanan cedi \(1979–2007\)),
				'other' => q(Ghanan cediä \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanan cedi),
				'one' => q(Ghanan cedi),
				'other' => q(Ghanan cediä),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltarin punta),
				'one' => q(Gibraltarin punta),
				'other' => q(Gibraltarin puntaa),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambian dalasi),
				'one' => q(Gambian dalasi),
				'other' => q(Gambian dalasia),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Guinean frangi),
				'one' => q(Guinean frangi),
				'other' => q(Guinean frangia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinean syli),
				'one' => q(Guinean syli),
				'other' => q(Guinean syliä),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Päiväntasaajan Guinean ekwele),
				'one' => q(Päiväntasaajan Guinean ekwele),
				'other' => q(Päiväntasaajan Guinean ekweleä),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Kreikan drakma),
				'one' => q(Kreikan drakma),
				'other' => q(Kreikan drakmaa),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guatemalan quetzal),
				'one' => q(Guatemalan quetzal),
				'other' => q(Guatemalan quetzalia),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugalin Guinean escudo),
				'one' => q(Portugalin Guinean escudo),
				'other' => q(Portugalin Guinean escudoa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissaun peso),
				'one' => q(Guinea-Bissaun peso),
				'other' => q(Guinea-Bissaun pesoa),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Guyanan dollari),
				'one' => q(Guyanan dollari),
				'other' => q(Guyanan dollaria),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Hongkongin dollari),
				'one' => q(Hongkongin dollari),
				'other' => q(Hongkongin dollaria),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Hondurasin lempira),
				'one' => q(Hondurasin lempira),
				'other' => q(Hondurasin lempiraa),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroatian dinaari),
				'one' => q(Kroatian dinaari),
				'other' => q(Kroatian dinaaria),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kroatian kuna),
				'one' => q(Kroatian kuna),
				'other' => q(Kroatian kunaa),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitin gourde),
				'one' => q(Haitin gourde),
				'other' => q(Haitin gourdea),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Unkarin forintti),
				'one' => q(Unkarin forintti),
				'other' => q(Unkarin forinttia),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesian rupia),
				'one' => q(Indonesian rupia),
				'other' => q(Indonesian rupiaa),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irlannin punta),
				'one' => q(Irlannin punta),
				'other' => q(Irlannin puntaa),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israelin punta),
				'one' => q(Israelin punta),
				'other' => q(Israelin puntaa),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Israelin sekeli \(1980–1985\)),
				'one' => q(Israelin sekeli \(1980–1985\)),
				'other' => q(Israelin sekeliä \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(Israelin uusi sekeli),
				'one' => q(Israelin uusi sekeli),
				'other' => q(Israelin uutta sekeliä),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(Intian rupia),
				'one' => q(Intian rupia),
				'other' => q(Intian rupiaa),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irakin dinaari),
				'one' => q(Irakin dinaari),
				'other' => q(Irakin dinaaria),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iranin rial),
				'one' => q(Iranin rial),
				'other' => q(Iranin rialia),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Islannin kruunu \(1918–1981\)),
				'one' => q(Islannin kruunu \(1918–1981\)),
				'other' => q(Islannin kruunua \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Islannin kruunu),
				'one' => q(Islannin kruunu),
				'other' => q(Islannin kruunua),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italian liira),
				'one' => q(Italian liira),
				'other' => q(Italian liiraa),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaikan dollari),
				'one' => q(Jamaikan dollari),
				'other' => q(Jamaikan dollaria),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordanian dinaari),
				'one' => q(Jordanian dinaari),
				'other' => q(Jordanian dinaaria),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japanin jeni),
				'one' => q(Japanin jeni),
				'other' => q(Japanin jeniä),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenian šillinki),
				'one' => q(Kenian šillinki),
				'other' => q(Kenian šillinkiä),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgisian som),
				'one' => q(Kirgisian som),
				'other' => q(Kirgisian somia),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodžan riel),
				'one' => q(Kambodžan riel),
				'other' => q(Kambodžan rieliä),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komorien frangi),
				'one' => q(Komorien frangi),
				'other' => q(Komorien frangia),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Pohjois-Korean won),
				'one' => q(Pohjois-Korean won),
				'other' => q(Pohjois-Korean wonia),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Etelä-Korean hwan \(1953–1962\)),
				'one' => q(Etelä-Korean hwan \(1953–1962\)),
				'other' => q(Etelä-Korean hwania \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Etelä-Korean won \(1945–1953\)),
				'one' => q(Etelä-Korean won \(1945–1953\)),
				'other' => q(Etelä-Korean wonia \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(Etelä-Korean won),
				'one' => q(Etelä-Korean won),
				'other' => q(Etelä-Korean wonia),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwaitin dinaari),
				'one' => q(Kuwaitin dinaari),
				'other' => q(Kuwaitin dinaaria),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Caymansaarten dollari),
				'one' => q(Caymansaarten dollari),
				'other' => q(Caymansaarten dollaria),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kazakstanin tenge),
				'one' => q(Kazakstanin tenge),
				'other' => q(Kazakstanin tengeä),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laosin kip),
				'one' => q(Laosin kip),
				'other' => q(Laosin kipiä),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libanonin punta),
				'one' => q(Libanonin punta),
				'other' => q(Libanonin puntaa),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri Lankan rupia),
				'one' => q(Sri Lankan rupia),
				'other' => q(Sri Lankan rupiaa),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberian dollari),
				'one' => q(Liberian dollari),
				'other' => q(Liberian dollaria),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesothon loti),
				'one' => q(Lesothon loti),
				'other' => q(Lesothon lotia),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Liettuan liti),
				'one' => q(Liettuan liti),
				'other' => q(Liettuan litiä),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Liettuan talonas),
				'one' => q(Liettuan talonas),
				'other' => q(Liettuan talonasia),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxemburgin vaihdettava frangi),
				'one' => q(Luxemburgin vaihdettava frangi),
				'other' => q(Luxemburgin vaihdettavaa frangia),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxemburgin frangi),
				'one' => q(Luxemburgin frangi),
				'other' => q(Luxemburgin frangia),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxemburgin rahoitusfrangi),
				'one' => q(Luxemburgin rahoitusfrangi),
				'other' => q(Luxemburgin rahoitusfrangia),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Latvian lati),
				'one' => q(Latvian lati),
				'other' => q(Latvian latia),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvian rupla),
				'one' => q(Latvian rupla),
				'other' => q(Latvian ruplaa),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan dinaari),
				'one' => q(Libyan dinaari),
				'other' => q(Libyan dinaaria),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokon dirhami),
				'one' => q(Marokon dirhami),
				'other' => q(Marokon dirhamia),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokon frangi),
				'one' => q(Marokon frangi),
				'other' => q(Marokon frangia),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monacon frangi),
				'one' => q(Monacon frangi),
				'other' => q(Monacon frangia),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldovan kuponkileu),
				'one' => q(Moldovan kuponkileu),
				'other' => q(Moldovan kuponkileuta),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldovan leu),
				'one' => q(Moldovan leu),
				'other' => q(Moldovan leuta),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Madagaskarin ariary),
				'one' => q(Madagaskarin ariary),
				'other' => q(Madagaskarin ariarya),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskarin frangi),
				'one' => q(Madagaskarin frangi),
				'other' => q(Madagaskarin frangia),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedonian denaari),
				'one' => q(Makedonian denaari),
				'other' => q(Makedonian denaaria),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Makedonian dinaari \(1992–1993\)),
				'one' => q(Makedonian dinaari \(1992–1993\)),
				'other' => q(Makedonian dinaaria \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malin frangi),
				'one' => q(Malin frangi),
				'other' => q(Malin frangia),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanmarin kyat),
				'one' => q(Myanmarin kyat),
				'other' => q(Myanmarin kyatia),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongolian tugrik),
				'one' => q(Mongolian tugrik),
				'other' => q(Mongolian tugrikia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macaon pataca),
				'one' => q(Macaon pataca),
				'other' => q(Macaon patacaa),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritanian ouguiya \(1973–2017\)),
				'one' => q(Mauritanian ouguiya \(1973–2017\)),
				'other' => q(Mauritanian ouguiyaa \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritanian ouguiya),
				'one' => q(Mauritanian ouguiya),
				'other' => q(Mauritanian ouguiyaa),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltan liira),
				'one' => q(Maltan liira),
				'other' => q(Maltan liiraa),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltan punta),
				'one' => q(Maltan punta),
				'other' => q(Maltan puntaa),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mauritiuksen rupia),
				'one' => q(Mauritiuksen rupia),
				'other' => q(Mauritiuksen rupiaa),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Malediivien rupia \(1947–1981\)),
				'one' => q(Malediivien rupia \(1947–1981\)),
				'other' => q(Malediivien rupiaa \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Malediivien rufiyaa),
				'one' => q(Malediivien rufiyaa),
				'other' => q(Malediivien rufiyaata),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawin kwacha),
				'one' => q(Malawin kwacha),
				'other' => q(Malawin kwachaa),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Meksikon peso),
				'one' => q(Meksikon peso),
				'other' => q(Meksikon pesoa),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Meksikon hopeapeso \(1861–1992\)),
				'one' => q(Meksikon hopeapeso \(1861–1992\)),
				'other' => q(Meksikon hopeapesoa \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Meksikon UDI),
				'one' => q(Meksikon UDI),
				'other' => q(Meksikon UDI’ta),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malesian ringgit),
				'one' => q(Malesian ringgit),
				'other' => q(Malesian ringgitiä),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mosambikin escudo),
				'one' => q(Mosambikin escudo),
				'other' => q(Mosambikin escudoa),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mosambikin metical \(1980–2006\)),
				'one' => q(Mosambikin metical \(1980–2006\)),
				'other' => q(Mosambikin meticalia \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambikin metical),
				'one' => q(Mosambikin metical),
				'other' => q(Mosambikin meticalia),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibian dollari),
				'one' => q(Namibian dollari),
				'other' => q(Namibian dollaria),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigerian naira),
				'one' => q(Nigerian naira),
				'other' => q(Nigerian nairaa),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguan córdoba \(1988–1991\)),
				'one' => q(Nicaraguan córdoba \(1988–1991\)),
				'other' => q(Nicaraguan córdobaa \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nicaraguan córdoba),
				'one' => q(Nicaraguan córdoba),
				'other' => q(Nicaraguan córdobaa),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Alankomaiden guldeni),
				'one' => q(Alankomaiden guldeni),
				'other' => q(Alankomaiden guldenia),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norjan kruunu),
				'one' => q(Norjan kruunu),
				'other' => q(Norjan kruunua),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepalin rupia),
				'one' => q(Nepalin rupia),
				'other' => q(Nepalin rupiaa),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(Uuden-Seelannin dollari),
				'one' => q(Uuden-Seelannin dollari),
				'other' => q(Uuden-Seelannin dollaria),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omanin rial),
				'one' => q(Omanin rial),
				'other' => q(Omanin rialia),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panaman balboa),
				'one' => q(Panaman balboa),
				'other' => q(Panaman balboaa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Perun inti),
				'one' => q(Perun inti),
				'other' => q(Perun intiä),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Perun sol),
				'one' => q(Perun sol),
				'other' => q(Perun solia),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Perun sol \(1863–1965\)),
				'one' => q(Perun sol \(1863–1965\)),
				'other' => q(Perun solia \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua-Uuden-Guinean kina),
				'one' => q(Papua-Uuden-Guinean kina),
				'other' => q(Papua-Uuden-Guinean kinaa),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippiinien peso),
				'one' => q(Filippiinien peso),
				'other' => q(Filippiinien pesoa),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistanin rupia),
				'one' => q(Pakistanin rupia),
				'other' => q(Pakistanin rupiaa),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Puolan złoty),
				'one' => q(Puolan złoty),
				'other' => q(Puolan złotya),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Puolan złoty \(1950–1995\)),
				'one' => q(Puolan złoty \(1950–1995\)),
				'other' => q(Puolan złotya \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugalin escudo),
				'one' => q(Portugalin escudo),
				'other' => q(Portugalin escudoa),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguayn guarani),
				'one' => q(Paraguayn guarani),
				'other' => q(Paraguayn guarania),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatarin rial),
				'one' => q(Qatarin rial),
				'other' => q(Qatarin rialia),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodesian dollari),
				'one' => q(Rhodesian dollari),
				'other' => q(Rhodesian dollaria),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Romanian leu \(1952–2006\)),
				'one' => q(Romanian leu \(1952–2006\)),
				'other' => q(Romanian leuta \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Romanian leu),
				'one' => q(Romanian leu),
				'other' => q(Romanian leuta),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbian dinaari),
				'one' => q(Serbian dinaari),
				'other' => q(Serbian dinaaria),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Venäjän rupla),
				'one' => q(Venäjän rupla),
				'other' => q(Venäjän ruplaa),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Venäjän rupla \(1991–1998\)),
				'one' => q(Venäjän rupla \(1991–1998\)),
				'other' => q(Venäjän ruplaa \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruandan frangi),
				'one' => q(Ruandan frangi),
				'other' => q(Ruandan frangia),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi-Arabian rial),
				'one' => q(Saudi-Arabian rial),
				'other' => q(Saudi-Arabian rialia),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Salomonsaarten dollari),
				'one' => q(Salomonsaarten dollari),
				'other' => q(Salomonsaarten dollaria),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellien rupia),
				'one' => q(Seychellien rupia),
				'other' => q(Seychellien rupiaa),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudanin dinaari \(1992–2007\)),
				'one' => q(Sudanin dinaari \(1992–2007\)),
				'other' => q(Sudanin dinaaria \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanin punta),
				'one' => q(Sudanin punta),
				'other' => q(Sudanin puntaa),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudanin punta \(1957–1998\)),
				'one' => q(Sudanin punta \(1957–1998\)),
				'other' => q(Sudanin puntaa \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Ruotsin kruunu),
				'one' => q(Ruotsin kruunu),
				'other' => q(Ruotsin kruunua),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singaporen dollari),
				'one' => q(Singaporen dollari),
				'other' => q(Singaporen dollaria),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Saint Helenan punta),
				'one' => q(Saint Helenan punta),
				'other' => q(Saint Helenan puntaa),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovenian tolar),
				'one' => q(Slovenian tolar),
				'other' => q(Slovenian tolaria),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovakian koruna),
				'one' => q(Slovakian koruna),
				'other' => q(Slovakian korunaa),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leonen leone),
				'one' => q(Sierra Leonen leone),
				'other' => q(Sierra Leonen leonea),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leonen leone \(1964–2022\)),
				'one' => q(Sierra Leonen leone \(1964–2022\)),
				'other' => q(Sierra Leonen leonea \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalian šillinki),
				'one' => q(Somalian šillinki),
				'other' => q(Somalian šillinkiä),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinamen dollari),
				'one' => q(Surinamen dollari),
				'other' => q(Surinamen dollaria),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamen guldeni),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Etelä-Sudanin punta),
				'one' => q(Etelä-Sudanin punta),
				'other' => q(Etelä-Sudanin puntaa),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomén ja Príncipen dobra \(1977–2017\)),
				'one' => q(São Tomén ja Príncipen dobra \(1977–2017\)),
				'other' => q(São Tomén ja Príncipen dobraa \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(São Tomén ja Príncipen dobra),
				'one' => q(São Tomén ja Príncipen dobra),
				'other' => q(São Tomén ja Príncipen dobraa),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Neuvostoliiton rupla),
				'one' => q(Neuvostoliiton rupla),
				'other' => q(Neuvostoliiton ruplaa),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El Salvadorin colón),
				'one' => q(El Salvadorin colón),
				'other' => q(El Salvadorin colónia),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Syyrian punta),
				'one' => q(Syyrian punta),
				'other' => q(Syyrian puntaa),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazimaan lilangeni),
				'one' => q(Swazimaan lilangeni),
				'other' => q(Swazimaan lilangenia),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Thaimaan baht),
				'one' => q(Thaimaan baht),
				'other' => q(Thaimaan bahtia),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadžikistanin rupla),
				'one' => q(Tadžikistanin rupla),
				'other' => q(Tadžikistanin ruplaa),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadžikistanin somoni),
				'one' => q(Tadžikistanin somoni),
				'other' => q(Tadžikistanin somonia),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistanin manat \(1993–2009\)),
				'one' => q(Turkmenistanin manat \(1993–2009\)),
				'other' => q(Turkmenistanin manatia \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistanin manat),
				'one' => q(Turkmenistanin manat),
				'other' => q(Turkmenistanin manatia),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian dinaari),
				'one' => q(Tunisian dinaari),
				'other' => q(Tunisian dinaaria),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tongan pa’anga),
				'one' => q(Tongan pa’anga),
				'other' => q(Tongan pa’angaa),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timorin escudo),
				'one' => q(Timorin escudo),
				'other' => q(Timorin escudoa),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkin liira \(1922–2005\)),
				'one' => q(Turkin liira \(1922–2005\)),
				'other' => q(Turkin liiraa \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turkin liira),
				'one' => q(Turkin liira),
				'other' => q(Turkin liiraa),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidadin ja Tobagon dollari),
				'one' => q(Trinidadin ja Tobagon dollari),
				'other' => q(Trinidadin ja Tobagon dollaria),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(Taiwanin uusi dollari),
				'one' => q(Taiwanin uusi dollari),
				'other' => q(Taiwanin uutta dollaria),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tansanian šillinki),
				'one' => q(Tansanian šillinki),
				'other' => q(Tansanian šillinkiä),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukrainan hryvnia),
				'one' => q(Ukrainan hryvnia),
				'other' => q(Ukrainan hryvniaa),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrainan karbovanetz),
				'one' => q(Ukrainan karbovanetz),
				'other' => q(Ukrainan karbovanetzia),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandan šillinki \(1966–1987\)),
				'one' => q(Ugandan šillinki \(1966–1987\)),
				'other' => q(Ugandan šillinkiä \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandan šillinki),
				'one' => q(Ugandan šillinki),
				'other' => q(Ugandan šillinkiä),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Yhdysvaltain dollari),
				'one' => q(Yhdysvaltain dollari),
				'other' => q(Yhdysvaltain dollaria),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Yhdysvaltain dollari \(seuraava päivä\)),
				'one' => q(Yhdysvaltain dollari \(seuraava päivä\)),
				'other' => q(Yhdysvaltain dollaria \(seuraava päivä\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Yhdysvaltain dollari \(sama päivä\)),
				'one' => q(Yhdysvaltain dollari \(sama päivä\)),
				'other' => q(Yhdysvaltain dollaria \(sama päivä\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayn peso en unidades indexadas),
				'one' => q(Uruguayn peso en unidades indexadas),
				'other' => q(Uruguayn pesoa en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayn peso \(1975–1993\)),
				'one' => q(Uruguayn peso \(1975–1993\)),
				'other' => q(Uruguayn pesoa \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguayn peso),
				'one' => q(Uruguayn peso),
				'other' => q(Uruguayn pesoa),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(Uruguayn nimellinen palkkaindeksiyksikkö),
				'one' => q(Uruguayn nimellinen palkkaindeksiyksikkö),
				'other' => q(Uruguayn nimellistä palkkaindeksiyksikköä),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Uzbekistanin som),
				'one' => q(Uzbekistanin som),
				'other' => q(Uzbekistanin somia),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelan bolívar \(1871–2008\)),
				'one' => q(Venezuelan bolívar \(1871–2008\)),
				'other' => q(Venezuelan bolívaria \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venezuelan bolívar \(2008–2018\)),
				'one' => q(Venezuelan bolívar \(2008–2018\)),
				'other' => q(Venezuelan bolívaria \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuelan suvereeni bolívar),
				'one' => q(Venezuelan suvereeni bolívar),
				'other' => q(Venezuelan suvereenia bolívaria),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(Vietnamin dong),
				'one' => q(Vietnamin dong),
				'other' => q(Vietnamin dongia),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vietnamin dong \(1978–1985\)),
				'one' => q(Vietnamin dong \(1978–1985\)),
				'other' => q(Vietnamin dongia \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatun vatu),
				'one' => q(Vanuatun vatu),
				'other' => q(Vanuatun vatua),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoan tala),
				'one' => q(Samoan tala),
				'other' => q(Samoan talaa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-frangi BEAC),
				'one' => q(CFA-frangi BEAC),
				'other' => q(CFA-frangia BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(hopea),
				'one' => q(troy-unssi hopeaa),
				'other' => q(troy-unssia hopeaa),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(kulta),
				'one' => q(troy-unssi kultaa),
				'other' => q(troy-unssia kultaa),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(EURCO),
				'one' => q(EURCO),
				'other' => q(EURCO’a),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Euroopan rahayksikkö \(EMU\)),
				'one' => q(Euroopan rahayksikkö \(EMU\)),
				'other' => q(Euroopan rahayksikköä \(EMU\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(EUA \(XBC\)),
				'one' => q(EUA \(XBC\)),
				'other' => q(EUA’ta \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(EUA \(XBD\)),
				'one' => q(EUA \(XBD\)),
				'other' => q(EUA’ta \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(Itä-Karibian dollari),
				'one' => q(Itä-Karibian dollari),
				'other' => q(Itä-Karibian dollaria),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(erityisnosto-oikeus \(SDR\)),
				'one' => q(erityisnosto-oikeus \(SDR\)),
				'other' => q(erityisnosto-oikeutta \(SDR\)),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Euroopan valuuttayksikkö \(ECU\)),
				'one' => q(Euroopan valuuttayksikkö \(ECU\)),
				'other' => q(Euroopan valuuttayksikköä \(ECU\)),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Ranskan kultafrangi),
				'one' => q(Ranskan kultafrangi),
				'other' => q(Ranskan kultafrangia),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Ranskan UIC-frangi),
				'one' => q(Ranskan UIC-frangi),
				'other' => q(Ranskan UIC-frangia),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-frangi BCEAO),
				'one' => q(CFA-frangi BCEAO),
				'other' => q(CFA-frangia BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'one' => q(troy-unssi palladiumia),
				'other' => q(troy-unssia palladiumia),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(CFP-frangi),
				'one' => q(CFP-frangi),
				'other' => q(CFP-frangia),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'one' => q(troy-unssi platinaa),
				'other' => q(troy-unssia platinaa),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-rahastot),
				'one' => q(RINET-rahastoyksikkö),
				'other' => q(RINET-rahastoyksikköä),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(etelä-amerikkalaisen ALBA:n laskentayksikkö sucre),
				'one' => q(sucre),
				'other' => q(sucrea),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(testaustarkoitukseen varattu valuuttakoodi),
				'one' => q(testaustarkoitukseen varattu valuuttakoodi),
				'other' => q(testaustarkoitukseen varattua valuuttakoodia),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(afrikkalainen AfDB-laskentayksikkö),
				'one' => q(AfDB-laskentayksikkö),
				'other' => q(AfDB-laskentayksikköä),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(tuntematon rahayksikkö),
				'one' => q(tuntematon rahayksikkö),
				'other' => q(tuntematonta rahayksikköä),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemenin dinaari),
				'one' => q(Jemenin dinaari),
				'other' => q(Jemenin dinaaria),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemenin rial),
				'one' => q(Jemenin rial),
				'other' => q(Jemenin rialia),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslavian kova dinaari \(1966–1990\)),
				'one' => q(Jugoslavian kova dinaari \(1966–1990\)),
				'other' => q(Jugoslavian kovaa dinaaria \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslavian uusi dinaari \(1994–2002\)),
				'one' => q(Jugoslavian uusi dinaari \(1994–2002\)),
				'other' => q(Jugoslavian uutta dinaaria \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslavian vaihdettava dinaari \(1990–1992\)),
				'one' => q(Jugoslavian vaihdettava dinaari \(1990–1992\)),
				'other' => q(Jugoslavian vaihdettavaa dinaaria \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Jugoslavian uudistettu dinaari \(1992–1993\)),
				'one' => q(Jugoslavian uudistettu dinaari \(1992–1993\)),
				'other' => q(Jugoslavian uudistettua dinaaria \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Etelä-Afrikan rahoitusrandi),
				'one' => q(Etelä-Afrikan rahoitusrandi),
				'other' => q(Etelä-Afrikan rahoitusrandia),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Etelä-Afrikan randi),
				'one' => q(Etelä-Afrikan randi),
				'other' => q(Etelä-Afrikan randia),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Sambian kwacha \(1968–2012\)),
				'one' => q(Sambian kwacha \(1968–2012\)),
				'other' => q(Sambian kwachaa \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Sambian kwacha),
				'one' => q(Sambian kwacha),
				'other' => q(Sambian kwachaa),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zairen uusi zaire \(1993–1998\)),
				'one' => q(Zairen uusi zaire \(1993–1998\)),
				'other' => q(Zairen uutta zairea \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairen zaire \(1971–1993\)),
				'one' => q(Zairen zaire \(1971–1993\)),
				'other' => q(Zairen zairea \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwen dollari \(1980–2008\)),
				'one' => q(Zimbabwen dollari \(1980–2008\)),
				'other' => q(Zimbabwen dollaria \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwen dollari \(2009\)),
				'one' => q(Zimbabwen dollari \(2009\)),
				'other' => q(Zimbabwen dollaria \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwen dollari \(2008\)),
				'one' => q(Zimbabwen dollari \(2008\)),
				'other' => q(Zimbabwen dollaria \(2008\)),
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
							'thoutkuuta',
							'paopikuuta',
							'hathorkuuta',
							'koiakkuuta',
							'tobikuuta',
							'meshirkuuta',
							'paremhatkuuta',
							'paremoudekuuta',
							'pashonskuuta',
							'paonikuuta',
							'epipkuuta',
							'mesorikuuta',
							'pi-kogi-enavotkuuta'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'thout',
							'paopi',
							'hathor',
							'koiak',
							'toba',
							'meshir',
							'paremhat',
							'paremoude',
							'pashons',
							'paoni',
							'epip',
							'mesori',
							'pi kogi enavot'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'thoutkuu',
							'paopikuu',
							'hathorkuu',
							'koiakkuu',
							'tobikuu',
							'meshirkuu',
							'paremhatkuu',
							'paremoudekuu',
							'pashonskuu',
							'paonikuu',
							'epipkuu',
							'mesorikuu',
							'pi-kogi-enavotkuu'
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
							'mäskärämkuuta',
							'ṭəqəmtkuuta',
							'ḫədarkuuta',
							'taḫśaśkuuta',
							'ṭərrkuuta',
							'yäkatitkuuta',
							'mägabitkuuta',
							'miyazyakuuta',
							'gənbotkuuta',
							'sänekuuta',
							'ḥamlekuuta',
							'nähasekuuta',
							'ṗagumenkuuta'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'mäskärämkuu',
							'ṭəqəmtkuu',
							'ḫədarkuu',
							'taḫśaśkuu',
							'ṭərrkuu',
							'yäkatitkuu',
							'mägabitkuu',
							'miyazyakuu',
							'gənbotkuu',
							'sänekuu',
							'ḥamlekuu',
							'nähasekuu',
							'ṗagumenkuu'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'mäskärämkuu',
							'ṭəqəmtkuu',
							'ḫədarkuu',
							'taḫśaśkuu',
							'ṭərrkuu',
							'yäkatitkuu',
							'mägabitkuu',
							'miyazyakuu',
							'gənbotkuu',
							'sänekuu',
							'ḥamlekuu',
							'nähasekuu',
							'ṗagumenkuu'
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
							'tammi',
							'helmi',
							'maalis',
							'huhti',
							'touko',
							'kesä',
							'heinä',
							'elo',
							'syys',
							'loka',
							'marras',
							'joulu'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tammikuuta',
							'helmikuuta',
							'maaliskuuta',
							'huhtikuuta',
							'toukokuuta',
							'kesäkuuta',
							'heinäkuuta',
							'elokuuta',
							'syyskuuta',
							'lokakuuta',
							'marraskuuta',
							'joulukuuta'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'tammi',
							'helmi',
							'maalis',
							'huhti',
							'touko',
							'kesä',
							'heinä',
							'elo',
							'syys',
							'loka',
							'marras',
							'joulu'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'T',
							'H',
							'M',
							'H',
							'T',
							'K',
							'H',
							'E',
							'S',
							'L',
							'M',
							'J'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tammikuu',
							'helmikuu',
							'maaliskuu',
							'huhtikuu',
							'toukokuu',
							'kesäkuu',
							'heinäkuu',
							'elokuu',
							'syyskuu',
							'lokakuu',
							'marraskuu',
							'joulukuu'
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
							'tišrí',
							'hešván',
							'kislév',
							'tevét',
							'ševát',
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
					wide => {
						nonleap => [
							'tišríkuuta',
							'hešvánkuuta',
							'kislévkuuta',
							'tevétkuuta',
							'ševátkuuta',
							'adárkuuta I',
							'adárkuuta',
							'nisánkuuta',
							'ijjárkuuta',
							'sivánkuuta',
							'tammúzkuuta',
							'abkuuta',
							'elúlkuuta'
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
					narrow => {
						nonleap => [
							'T',
							'H',
							'K',
							'T',
							'S',
							'A',
							'A',
							'N',
							'I',
							'S',
							'T',
							'A',
							'E'
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
							'tišríkuu',
							'hešvánkuu',
							'kislévkuu',
							'tevétkuu',
							'ševátkuu',
							'adárkuu I',
							'adárkuu',
							'nisánkuu',
							'ijjárkuu',
							'sivánkuu',
							'tammúzkuu',
							'abkuu',
							'elúlkuu'
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
							'chaitrakuuta',
							'vaisakhakuuta',
							'jyaisthakuuta',
							'asadhakuuta',
							'sravanakuuta',
							'bhadrakuuta',
							'asvinakuuta',
							'kartikakuuta',
							'agrahayanakuuta',
							'pausakuuta',
							'maghakuuta',
							'phalgunakuuta'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
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
					wide => {
						nonleap => [
							'chaitrakuu',
							'vaisakhakuu',
							'jyaisthakuu',
							'asadhakuu',
							'sravanakuu',
							'bhadrakuu',
							'asvinakuu',
							'kartikakuu',
							'agrahayanakuu',
							'pausakuu',
							'maghakuu',
							'phalgunakuu'
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
							'džumada-l-ula',
							'džumada-l-akhira',
							'radžab',
							'ša’ban',
							'ramadan',
							'šawwal',
							'dhu-l-qa’da',
							'dhu-l-hiddža'
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
							'farvardinkuuta',
							'ordibeheštkuuta',
							'khordadkuuta',
							'tirkuuta',
							'mordadkuuta',
							'šahrivarkuuta',
							'mehrkuuta',
							'abankuuta',
							'azarkuuta',
							'deykuuta',
							'bahmankuuta',
							'esfandkuuta'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'farvardin',
							'ordibehešt',
							'khordad',
							'tir',
							'mordad',
							'šahrivar',
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
					wide => {
						nonleap => [
							'farvardinkuu',
							'ordibeheštkuu',
							'khordadkuu',
							'tirkuu',
							'mordadkuu',
							'šahrivarkuu',
							'mehrkuu',
							'abankuu',
							'azarkuu',
							'deykuu',
							'bahmankuu',
							'esfandkuu'
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
						mon => 'ma',
						tue => 'ti',
						wed => 'ke',
						thu => 'to',
						fri => 'pe',
						sat => 'la',
						sun => 'su'
					},
					wide => {
						mon => 'maanantaina',
						tue => 'tiistaina',
						wed => 'keskiviikkona',
						thu => 'torstaina',
						fri => 'perjantaina',
						sat => 'lauantaina',
						sun => 'sunnuntai'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'K',
						thu => 'T',
						fri => 'P',
						sat => 'L',
						sun => 'S'
					},
					wide => {
						mon => 'maanantai',
						tue => 'tiistai',
						wed => 'keskiviikko',
						thu => 'torstai',
						fri => 'perjantai',
						sat => 'lauantai',
						sun => 'sunnuntai'
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
					abbreviated => {0 => '1. nelj.',
						1 => '2. nelj.',
						2 => '3. nelj.',
						3 => '4. nelj.'
					},
					wide => {0 => '1. neljännes',
						1 => '2. neljännes',
						2 => '3. neljännes',
						3 => '4. neljännes'
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
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
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
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
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
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
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
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
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
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 500;
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
					'afternoon1' => q{iltap.},
					'am' => q{ap.},
					'evening1' => q{illalla},
					'midnight' => q{keskiyöllä},
					'morning1' => q{aamulla},
					'morning2' => q{aamup.},
					'night1' => q{yöllä},
					'noon' => q{keskip.},
					'pm' => q{ip.},
				},
				'narrow' => {
					'afternoon1' => q{ip.},
					'evening1' => q{illalla},
					'midnight' => q{ky.},
					'morning1' => q{aamulla},
					'morning2' => q{ap.},
					'night1' => q{yöllä},
					'noon' => q{kp.},
				},
				'wide' => {
					'afternoon1' => q{iltapäivällä},
					'evening1' => q{illalla},
					'midnight' => q{keskiyöllä},
					'morning1' => q{aamulla},
					'morning2' => q{aamupäivällä},
					'night1' => q{yöllä},
					'noon' => q{keskipäivällä},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{iltap.},
					'evening1' => q{ilta},
					'midnight' => q{keskiyö},
					'morning1' => q{aamu},
					'morning2' => q{aamup.},
					'night1' => q{yö},
				},
				'narrow' => {
					'afternoon1' => q{ip.},
					'evening1' => q{ilta},
					'midnight' => q{ky.},
					'morning1' => q{aamu},
					'morning2' => q{ap.},
					'night1' => q{yö},
					'noon' => q{kp.},
				},
				'wide' => {
					'afternoon1' => q{iltapäivä},
					'evening1' => q{ilta},
					'morning1' => q{aamu},
					'morning2' => q{aamupäivä},
					'night1' => q{yö},
					'noon' => q{keskipäivä},
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
				'0' => 'buddhalainen aika'
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
				'0' => 'eKr.',
				'1' => 'jKr.'
			},
			narrow => {
				'0' => 'eKr',
				'1' => 'jKr'
			},
			wide => {
				'0' => 'ennen Kristuksen syntymää',
				'1' => 'jälkeen Kristuksen syntymän'
			},
		},
		'hebrew' => {
			wide => {
				'0' => 'Anno Mundi'
			},
		},
		'indian' => {
			wide => {
				'0' => 'Saka-ajanlaskua'
			},
		},
		'islamic' => {
			wide => {
				'0' => 'hidžran jälkeen'
			},
		},
		'persian' => {
			wide => {
				'0' => 'Anno Persico'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'e. Kiinan tasav.',
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'ennen Kiinan tasavaltaa'
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
			'full' => q{cccc d.M.y},
			'long' => q{d.M.y},
			'medium' => q{d.M.y},
			'short' => q{d.M.y},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{cccc d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{cccc d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d.M.y},
			'short' => q{d.M.y},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
			'full' => q{H.mm.ss zzzz},
			'long' => q{H.mm.ss z},
			'medium' => q{H.mm.ss},
			'short' => q{H.mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
			H => q{H},
			Hm => q{H.mm},
			Hms => q{H.mm.ss},
			MEd => q{E d.M.},
			MMMEd => q{E d.M.},
			MMMd => q{d.M.},
			Md => q{d.M.},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
			y => q{y},
			yyyy => q{y},
			yyyyMEd => q{E d.M.y},
			yyyyMMMEd => q{E d.M.y},
			yyyyMMMd => q{d.M.y},
			yyyyMd => q{d.M.y},
		},
		'generic' => {
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E d.},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y G},
			H => q{H},
			Hm => q{H.mm},
			Hms => q{H.mm.ss},
			MEd => q{E d.M.},
			MMMEd => q{ccc d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{L.y G},
			yyyyMEd => q{E d.M.y G},
			yyyyMM => q{M.y G},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E d. MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMMccccd => q{cccc d. MMMM y G},
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
			EHm => q{E H.mm},
			EHms => q{E H.mm.ss},
			Ed => q{E d.},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E d.M.y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d.M.y G},
			GyMd => q{M.d.y G},
			H => q{H},
			Hm => q{H.mm},
			Hms => q{H.mm.ss},
			Hmsv => q{H.mm.ss v},
			Hmv => q{H.mm v},
			MEd => q{E d.M.},
			MMMEd => q{ccc d.M.},
			MMMMEd => q{ccc d. MMMM},
			MMMMW => q{LLLL'n' W. 'viikko'},
			MMMMd => q{d. MMMM},
			MMMd => q{d.M.},
			Md => q{d.M.},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss a v},
			hmv => q{h.mm a v},
			ms => q{m.ss},
			yM => q{L.y},
			yMEd => q{E d.M.y},
			yMM => q{M.y},
			yMMM => q{LLL y},
			yMMMEd => q{E d.M.y},
			yMMMM => q{LLLL y},
			yMMMMEd => q{E d. MMMM y},
			yMMMMccccd => q{cccc d. MMMM y},
			yMMMMd => q{d. MMMM y},
			yMMMd => q{d.M.y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'vuoden' Y 'viikko' w},
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
			Bhm => {
				B => q{h.mm B – h.mm B},
				h => q{h.mm–h.mm B},
				m => q{h.mm–h.mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y–M/y GGGGG},
				y => q{M/y–M/y GGGGG},
			},
			GyMEd => {
				G => q{E d.M.y GGGGG – E d.M.y GGGGG},
				M => q{E d.M.y – E d.M.y GGGGG},
				d => q{E d.M.y – E d.M.y GGGGG},
				y => q{E d.M.y – E d.M.y GGGGG},
			},
			GyMMM => {
				G => q{M.y G – M.y G},
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			GyMMMEd => {
				G => q{E d.M.y – E d.M.y G},
				M => q{E d.M. – E d.M.y G},
				d => q{E d.M. – E d.M.y G},
				y => q{E d.M.y – E d.M.y G},
			},
			GyMMMM => {
				G => q{LLLL y G – LLLL y G},
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			GyMMMMEd => {
				G => q{E d. MMMM y G – E d. MMMM y G},
				M => q{E d. MMMM – E d. MMMM y G},
				d => q{E d. – E d. MMMM y G},
				y => q{E d. MMMM y – E d. MMMM y G},
			},
			GyMMMMd => {
				G => q{d. MMMM y G – d. MMMM y G},
				M => q{d. MMMM – d. MMMM y G},
				d => q{d.–d. MMMM y G},
				y => q{d. MMMM y – d. MMMM y G},
			},
			GyMMMd => {
				G => q{d.M.y G – d.M.y G},
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y – d.M.y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y–d.M.y GGGGG},
				d => q{d.M.y–d.M.y GGGGG},
				y => q{d.M.y–d.M.y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H.mm–H.mm},
				m => q{H.mm–H.mm},
			},
			Hmv => {
				H => q{H.mm–H.mm v},
				m => q{H.mm–H.mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{L.–L.},
			},
			MEd => {
				M => q{E d.M. – E d.M.},
				d => q{E d. – E d.M.},
			},
			MMM => {
				M => q{LLL–LLLL},
			},
			MMMEd => {
				M => q{E d. MMMM – E d. MMMM},
				d => q{E d. – E d. MMMM},
			},
			MMMM => {
				M => q{LLL–LLLL},
			},
			MMMd => {
				M => q{d. MMMM – d. MMMM},
				d => q{d.–d. MMMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{LLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y G},
				d => q{E d.M.y – E d.M.y G},
				y => q{E d.M.y – E d.M.y G},
			},
			yMMM => {
				M => q{LLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMEd => {
				M => q{E d. MMMM – E d. MMMM y G},
				d => q{E d. – E d. MMMM y G},
				y => q{E d. MMMM y – E d. MMMM y G},
			},
			yMMMM => {
				M => q{LLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. MMMM – d. MMMM y G},
				d => q{d.–d. MMMM y G},
				y => q{d. MMMM y – d. MMMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'gregorian' => {
			Bhm => {
				B => q{h.mm B – h.mm B},
				h => q{h.mm–h.mm B},
				m => q{h.mm–h.mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y–M/y GGGGG},
				y => q{M/y–M/y GGGGG},
			},
			GyMEd => {
				G => q{E d.M.y GGGGG – E d.M.y GGGGG},
				M => q{E d.M.y – E d.M.y GGGGG},
				d => q{E d.M.y – E d.M.y GGGGG},
				y => q{E d.M.y – E d.M.y GGGGG},
			},
			GyMMM => {
				G => q{M.y G – M.y G},
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			GyMMMEd => {
				G => q{E d.M.y – E d.M.y G},
				M => q{E d.M. – E d.M.y G},
				d => q{E d.M – E d.M.y G},
				y => q{E d.M.y – E d.M.y G},
			},
			GyMMMM => {
				G => q{LLLL y G – LLLL y G},
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			GyMMMMEd => {
				G => q{E d. MMMM y G – E d. MMMM y G},
				M => q{E d. MMMM – E d. MMMM y G},
				d => q{E d. – E d. MMMM y G},
				y => q{E d. MMMM y – E d. MMMM y G},
			},
			GyMMMMd => {
				G => q{d. MMMM y G – d. MMMM y G},
				M => q{d. MMMM – d. MMMM y G},
				d => q{d.–d. MMMM y G},
				y => q{d. MMMM y – d. MMMM y G},
			},
			GyMMMd => {
				G => q{d.M.y. G – d.M.y G},
				M => q{d.M–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
			GyMd => {
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y–d.M.y GGGGG},
				d => q{d.M.y–d.M.y GGGGG},
				y => q{d.M.y–d.M.y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H.mm–H.mm},
				m => q{H.mm–H.mm},
			},
			Hmv => {
				H => q{H.mm–H.mm v},
				m => q{H.mm–H.mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{L.–L.},
			},
			MEd => {
				M => q{E d.M. – E d.M.},
				d => q{E d. – E d.M.},
			},
			MMM => {
				M => q{LLL–LLLL},
			},
			MMMEd => {
				M => q{E d. MMMM – E d. MMMM},
				d => q{E d. – E d. MMMM},
			},
			MMMM => {
				M => q{LLL–LLLL},
			},
			MMMMEd => {
				M => q{E d. MMMM – E d. MMMM},
				d => q{E d. – E d. MMMM},
			},
			MMMMd => {
				M => q{d. MMMM – d. MMMM},
				d => q{d.–d. MMMM},
			},
			MMMd => {
				M => q{d. MMMM – d. MMMM},
				d => q{d.–d. MMMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
			yM => {
				M => q{LLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y},
				d => q{E d.M.y – E d.M.y},
				y => q{E d.M.y – E d.M.y},
			},
			yMMM => {
				M => q{LLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMEd => {
				M => q{E d. MMMM – E d. MMMM y},
				d => q{E d. – E d. MMMM y},
				y => q{E d. MMMM y – E d. MMMM y},
			},
			yMMMM => {
				M => q{LLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMMEd => {
				M => q{E d. MMMM – E d. MMMM y},
				d => q{E d. – E d. MMMM y},
				y => q{E d. MMMM y – E d. MMMM y},
			},
			yMMMMd => {
				M => q{d. MMMM – d. MMMM y},
				d => q{d.–d. MMMM y},
				y => q{d. MMMM y – d. MMMM y},
			},
			yMMMd => {
				M => q{d. MMMM – d. MMMM y},
				d => q{d.–d. MMMM y},
				y => q{d. MMMM y – d. MMMM y},
			},
			yMd => {
				M => q{d.M.–d.M.y},
				d => q{d.–d.M.y},
				y => q{d.M.y–d.M.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+H.mm;-H.mm),
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(aikavyöhyke: {0}),
		regionFormat => q({0} (kesäaika)),
		regionFormat => q({0} (normaaliaika)),
		'Acre' => {
			long => {
				'daylight' => q#Acren kesäaika#,
				'generic' => q#Acren aika#,
				'standard' => q#Acren normaaliaika#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistanin aika#,
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
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Keski-Afrikan aika#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Itä-Afrikan aika#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Etelä-Afrikan aika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Länsi-Afrikan kesäaika#,
				'generic' => q#Länsi-Afrikan aika#,
				'standard' => q#Länsi-Afrikan normaaliaika#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaskan kesäaika#,
				'generic' => q#Alaskan aika#,
				'standard' => q#Alaskan normaaliaika#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatyn kesäaika#,
				'generic' => q#Almatyn aika#,
				'standard' => q#Almatyn normaaliaika#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonin kesäaika#,
				'generic' => q#Amazonin aika#,
				'standard' => q#Amazonin normaaliaika#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Godthab' => {
			exemplarCity => q#Godthåb#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de México#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Pohjois-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Pohjois-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Pohjois-Dakota#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago de Chile#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Scoresbysund#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
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
				'daylight' => q#Yhdysvaltain keskinen kesäaika#,
				'generic' => q#Yhdysvaltain keskinen aika#,
				'standard' => q#Yhdysvaltain keskinen normaaliaika#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Yhdysvaltain itäinen kesäaika#,
				'generic' => q#Yhdysvaltain itäinen aika#,
				'standard' => q#Yhdysvaltain itäinen normaaliaika#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Kalliovuorten kesäaika#,
				'generic' => q#Kalliovuorten aika#,
				'standard' => q#Kalliovuorten normaaliaika#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Yhdysvaltain Tyynenmeren kesäaika#,
				'generic' => q#Yhdysvaltain Tyynenmeren aika#,
				'standard' => q#Yhdysvaltain Tyynenmeren normaaliaika#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyrin kesäaika#,
				'generic' => q#Anadyrin aika#,
				'standard' => q#Anadyrin normaaliaika#,
			},
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquariensaari#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apian kesäaika#,
				'generic' => q#Apian aika#,
				'standard' => q#Apian normaaliaika#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtaw’n kesäaika#,
				'generic' => q#Aqtaw’n aika#,
				'standard' => q#Aqtaw’n normaaliaika#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtöben kesäaika#,
				'generic' => q#Aqtöben aika#,
				'standard' => q#Aqtöben normaaliaika#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Saudi-Arabian kesäaika#,
				'generic' => q#Saudi-Arabian aika#,
				'standard' => q#Saudi-Arabian normaaliaika#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentiinan kesäaika#,
				'generic' => q#Argentiinan aika#,
				'standard' => q#Argentiinan normaaliaika#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Länsi-Argentiinan kesäaika#,
				'generic' => q#Länsi-Argentiinan aika#,
				'standard' => q#Länsi-Argentiinan normaaliaika#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenian kesäaika#,
				'generic' => q#Armenian aika#,
				'standard' => q#Armenian normaaliaika#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtaw#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ašgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atıraw#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tšita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskos#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtšatka#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Masqat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjongjang#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanai#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qızılorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hồ Chí Minhin kaupunki#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Soul#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
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
				'daylight' => q#Kanadan Atlantin kesäaika#,
				'generic' => q#Kanadan Atlantin aika#,
				'standard' => q#Kanadan Atlantin normaaliaika#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorit#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariansaaret#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färsaaret#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Etelä-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Saint Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Keski-Australian kesäaika#,
				'generic' => q#Keski-Australian aika#,
				'standard' => q#Keski-Australian normaaliaika#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Läntisen Keski-Australian kesäaika#,
				'generic' => q#Läntisen Keski-Australian aika#,
				'standard' => q#Läntisen Keski-Australian normaaliaika#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Itä-Australian kesäaika#,
				'generic' => q#Itä-Australian aika#,
				'standard' => q#Itä-Australian normaaliaika#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Länsi-Australian kesäaika#,
				'generic' => q#Länsi-Australian aika#,
				'standard' => q#Länsi-Australian normaaliaika#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaidžanin kesäaika#,
				'generic' => q#Azerbaidžanin aika#,
				'standard' => q#Azerbaidžanin normaaliaika#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorien kesäaika#,
				'generic' => q#Azorien aika#,
				'standard' => q#Azorien normaaliaika#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeshin kesäaika#,
				'generic' => q#Bangladeshin aika#,
				'standard' => q#Bangladeshin normaaliaika#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutanin aika#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivian aika#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilian kesäaika#,
				'generic' => q#Brasilian aika#,
				'standard' => q#Brasilian normaaliaika#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunein aika#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kap Verden kesäaika#,
				'generic' => q#Kap Verden aika#,
				'standard' => q#Kap Verden normaaliaika#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Caseyn aika#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Tšamorron aika#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathamin kesäaika#,
				'generic' => q#Chathamin aika#,
				'standard' => q#Chathamin normaaliaika#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilen kesäaika#,
				'generic' => q#Chilen aika#,
				'standard' => q#Chilen normaaliaika#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kiinan kesäaika#,
				'generic' => q#Kiinan aika#,
				'standard' => q#Kiinan normaaliaika#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Joulusaaren aika#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kookossaarten aika#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbian kesäaika#,
				'generic' => q#Kolumbian aika#,
				'standard' => q#Kolumbian normaaliaika#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookinsaarten kesäaika#,
				'generic' => q#Cookinsaarten aika#,
				'standard' => q#Cookinsaarten normaaliaika#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuuban kesäaika#,
				'generic' => q#Kuuban aika#,
				'standard' => q#Kuuban normaaliaika#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davisin aika#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont d’Urvillen aika#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Itä-Timorin aika#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Pääsiäissaaren kesäaika#,
				'generic' => q#Pääsiäissaaren aika#,
				'standard' => q#Pääsiäissaaren normaaliaika#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadorin aika#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#UTC-yleisaika#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#tuntematon#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ateena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berliini#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bryssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chişinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kööpenhamina#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irlannin kesäaika#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mansaari#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiova#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			exemplarCity => q#Lontoo#,
			long => {
				'daylight' => q#Britannian kesäaika#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskova#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariisi#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riika#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rooma#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Tukholma#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinna#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikaani#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilna#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsova#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Keski-Euroopan kesäaika#,
				'generic' => q#Keski-Euroopan aika#,
				'standard' => q#Keski-Euroopan normaaliaika#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Itä-Euroopan kesäaika#,
				'generic' => q#Itä-Euroopan aika#,
				'standard' => q#Itä-Euroopan normaaliaika#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Itäisemmän Euroopan aika#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Länsi-Euroopan kesäaika#,
				'generic' => q#Länsi-Euroopan aika#,
				'standard' => q#Länsi-Euroopan normaaliaika#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandinsaarten kesäaika#,
				'generic' => q#Falklandinsaarten aika#,
				'standard' => q#Falklandinsaarten normaaliaika#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidžin kesäaika#,
				'generic' => q#Fidžin aika#,
				'standard' => q#Fidžin normaaliaika#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ranskan Guayanan aika#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ranskan eteläisten ja antarktisten alueiden aika#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichin normaaliaika#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galápagossaarten aika#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiersaarten aika#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgian kesäaika#,
				'generic' => q#Georgian aika#,
				'standard' => q#Georgian normaaliaika#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbertsaarten aika#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Itä-Grönlannin kesäaika#,
				'generic' => q#Itä-Grönlannin aika#,
				'standard' => q#Itä-Grönlannin normaaliaika#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Länsi-Grönlannin kesäaika#,
				'generic' => q#Länsi-Grönlannin aika#,
				'standard' => q#Länsi-Grönlannin normaaliaika#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guamin aika#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Arabiemiirikuntien normaaliaika#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyanan aika#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havaijin-Aleuttien kesäaika#,
				'generic' => q#Havaijin-Aleuttien aika#,
				'standard' => q#Havaijin-Aleuttien normaaliaika#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongin kesäaika#,
				'generic' => q#Hongkongin aika#,
				'standard' => q#Hongkongin normaaliaika#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovdin kesäaika#,
				'generic' => q#Hovdin aika#,
				'standard' => q#Hovdin normaaliaika#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Intian aika#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Joulusaari#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kookossaaret#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komorit#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelensaaret#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediivit#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Intian valtameren aika#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokiinan aika#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Keski-Indonesian aika#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Itä-Indonesian aika#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Länsi-Indonesian aika#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iranin kesäaika#,
				'generic' => q#Iranin aika#,
				'standard' => q#Iranin normaaliaika#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutskin kesäaika#,
				'generic' => q#Irkutskin aika#,
				'standard' => q#Irkutskin normaaliaika#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelin kesäaika#,
				'generic' => q#Israelin aika#,
				'standard' => q#Israelin normaaliaika#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japanin kesäaika#,
				'generic' => q#Japanin aika#,
				'standard' => q#Japanin normaaliaika#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Kamtšatkan kesäaika#,
				'generic' => q#Kamtšatkan aika#,
				'standard' => q#Kamtšatkan normaaliaika#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kazakstanin aika#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Itä-Kazakstanin aika#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Länsi-Kazakstanin aika#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean kesäaika#,
				'generic' => q#Korean aika#,
				'standard' => q#Korean normaaliaika#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraen aika#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarskin kesäaika#,
				'generic' => q#Krasnojarskin aika#,
				'standard' => q#Krasnojarskin normaaliaika#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisian aika#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Sri Lankan aika#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Linesaarten aika#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howen kesäaika#,
				'generic' => q#Lord Howen aika#,
				'standard' => q#Lord Howen normaaliaika#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macaon kesäaika#,
				'generic' => q#Macaon aika#,
				'standard' => q#Macaon normaaliaika#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadanin kesäaika#,
				'generic' => q#Magadanin aika#,
				'standard' => q#Magadanin normaaliaika#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malesian aika#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediivien aika#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesassaarten aika#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshallinsaarten aika#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritiuksen kesäaika#,
				'generic' => q#Mauritiuksen aika#,
				'standard' => q#Mauritiuksen normaaliaika#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsonin aika#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksikon Tyynenmeren kesäaika#,
				'generic' => q#Meksikon Tyynenmeren aika#,
				'standard' => q#Meksikon Tyynenmeren normaaliaika#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Batorin kesäaika#,
				'generic' => q#Ulan Batorin aika#,
				'standard' => q#Ulan Batorin normaaliaika#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskovan kesäaika#,
				'generic' => q#Moskovan aika#,
				'standard' => q#Moskovan normaaliaika#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarin aika#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Naurun aika#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalin aika#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Uuden-Kaledonian kesäaika#,
				'generic' => q#Uuden-Kaledonian aika#,
				'standard' => q#Uuden-Kaledonian normaaliaika#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Uuden-Seelannin kesäaika#,
				'generic' => q#Uuden-Seelannin aika#,
				'standard' => q#Uuden-Seelannin normaaliaika#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundlandin kesäaika#,
				'generic' => q#Newfoundlandin aika#,
				'standard' => q#Newfoundlandin normaaliaika#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuen aika#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolkinsaaren kesäaika#,
				'generic' => q#Norfolkinsaaren aika#,
				'standard' => q#Norfolkinsaaren normaaliaika#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronhan kesäaika#,
				'generic' => q#Fernando de Noronhan aika#,
				'standard' => q#Fernando de Noronhan normaaliaika#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Pohjois-Mariaanien aika#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirskin kesäaika#,
				'generic' => q#Novosibirskin aika#,
				'standard' => q#Novosibirskin normaaliaika#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omskin kesäaika#,
				'generic' => q#Omskin aika#,
				'standard' => q#Omskin normaaliaika#,
			},
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chathamsaaret#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pääsiäissaari#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambiersaaret#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesassaaret#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midwaysaaret#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistanin kesäaika#,
				'generic' => q#Pakistanin aika#,
				'standard' => q#Pakistanin normaaliaika#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palaun aika#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Uuden-Guinean aika#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayn kesäaika#,
				'generic' => q#Paraguayn aika#,
				'standard' => q#Paraguayn normaaliaika#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Perun kesäaika#,
				'generic' => q#Perun aika#,
				'standard' => q#Perun normaaliaika#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippiinien kesäaika#,
				'generic' => q#Filippiinien aika#,
				'standard' => q#Filippiinien normaaliaika#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixsaarten aika#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierren ja Miquelonin kesäaika#,
				'generic' => q#Saint-Pierren ja Miquelonin aika#,
				'standard' => q#Saint-Pierren ja Miquelonin normaaliaika#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairnin aika#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pohnpein aika#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjongjangin aika#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qızılordan kesäaika#,
				'generic' => q#Qızılordan aika#,
				'standard' => q#Qızılordan normaaliaika#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunionin aika#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotheran aika#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalinin kesäaika#,
				'generic' => q#Sahalinin aika#,
				'standard' => q#Sahalinin normaaliaika#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samaran kesäaika#,
				'generic' => q#Samaran aika#,
				'standard' => q#Samaran normaaliaika#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoan kesäaika#,
				'generic' => q#Samoan aika#,
				'standard' => q#Samoan normaaliaika#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychellien aika#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singaporen aika#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonsaarten aika#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Etelä-Georgian aika#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamen aika#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowan aika#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitin aika#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipein kesäaika#,
				'generic' => q#Taipein aika#,
				'standard' => q#Taipein normaaliaika#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistanin aika#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelaun aika#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongan kesäaika#,
				'generic' => q#Tongan aika#,
				'standard' => q#Tongan normaaliaika#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukin aika#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistanin kesäaika#,
				'generic' => q#Turkmenistanin aika#,
				'standard' => q#Turkmenistanin normaaliaika#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalun aika#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayn kesäaika#,
				'generic' => q#Uruguayn aika#,
				'standard' => q#Uruguayn normaaliaika#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistanin kesäaika#,
				'generic' => q#Uzbekistanin aika#,
				'standard' => q#Uzbekistanin normaaliaika#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatun kesäaika#,
				'generic' => q#Vanuatun aika#,
				'standard' => q#Vanuatun normaaliaika#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelan aika#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostokin kesäaika#,
				'generic' => q#Vladivostokin aika#,
				'standard' => q#Vladivostokin normaaliaika#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgogradin kesäaika#,
				'generic' => q#Volgogradin aika#,
				'standard' => q#Volgogradin normaaliaika#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostokin aika#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waken aika#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallisin ja Futunan aika#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutskin kesäaika#,
				'generic' => q#Jakutskin aika#,
				'standard' => q#Jakutskin normaaliaika#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgin kesäaika#,
				'generic' => q#Jekaterinburgin aika#,
				'standard' => q#Jekaterinburgin normaaliaika#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukonin aika#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
