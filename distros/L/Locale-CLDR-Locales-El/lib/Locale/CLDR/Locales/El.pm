=encoding utf8

=head1

Locale::CLDR::Locales::El - Package for language Greek

=cut

package Locale::CLDR::Locales::El;
# This file auto generated from Data/common/main/el.xml
#	on Mon 11 Apr  5:26:42 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'SentenceBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$STerm' => '[[$STerm] [; ;]]',
	]}
);
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-neuter','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-neuter' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(μείον →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(μηδέν),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← κόμμα →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(μία),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(δύο),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(τρεις),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(τέσσερις),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(πέντε),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(έξι),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(επτά),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(οκτώ),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(εννέα),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(δέκα),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(έντεκα),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(δώδεκα),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(δεκα­→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(είκοσι[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(τριάντα[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(σαράντα[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(πενήντα[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(εξήντα[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(εβδομήντα[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ογδόντα[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(εννενήντα[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(εκατό[ν →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(διακόσιες[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τριακόσιες[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(τετρακόσιες[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(πεντακόσιες[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(εξακόσιες[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(επτακόσιες[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(οκτακόσιες[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(εννιακόσιες[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(χίλιες[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← χίλιάδες[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμύριο[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμύρια[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμύριο[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμύρια[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμύριο[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμύρια[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμύριο[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμύρια[ →→]),
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
					rule => q(μείον →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(μηδέν),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← κόμμα →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ένας),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(δύο),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(τρεις),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(τέσσερις),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(πέντε),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(έξι),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(επτά),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(οκτώ),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(εννέα),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(δέκα),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(έντεκα),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(δώδεκα),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(δεκα­→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(είκοσι[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(τριάντα[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(σαράντα[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(πενήντα[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(εξήντα[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(εβδομήντα[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ογδόντα[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(εννενήντα[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(εκατό[ν →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(διακόσιοι[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τριακόσιοι[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(τετρακόσιοι[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(πεντακόσιοι[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(εξακόσιοι[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(επτακόσιοι[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(οκτακόσιοι[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(εννιακόσιοι[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(χίλιοι[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← χίλιάδες[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμύριο[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμύρια[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμύριο[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμύρια[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμύριο[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμύρια[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμύριο[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμύρια[ →→]),
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
					rule => q(μείον →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(μηδέν),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← κόμμα →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ένα),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(δύο),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(τρία),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(τέσσερα),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(πέντε),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(έξι),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(επτά),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(οκτώ),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(εννέα),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(δέκα),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(έντεκα),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(δώδεκα),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(δεκα­→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(είκοσι[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(τριάντα[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(σαράντα[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(πενήντα[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(εξήντα[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(εβδομήντα[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ογδόντα[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(εννενήντα[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(εκατό[ν →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(διακόσια[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τριακόσια[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(τετρακόσια[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(πεντακόσια[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(εξακόσια[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(επτακόσια[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(οκτακόσια[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(εννιακόσια[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(χίλια[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← χίλιάδες[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμύριο[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμύρια[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμύριο[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμύρια[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμύριο[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμύρια[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμύριο[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμύρια[ →→]),
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
					rule => q(μείον →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(μηδενική),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(πρώτη),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(δεύτερη),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(τρίτη),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(τέταρτη),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(πέμπτη),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(έκτη),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(έβδομη),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(όγδοη),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ένατη),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(δέκατη),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ενδέκατη),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(δωδέκατη),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(δέκατη[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(εικοστή[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(τριακοστή[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(τεσσαρακοστή[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(πεντηκοστή[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(εξηκοστή[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(εβδομηκοστή[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ογδοηκοστή[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(εννενηκοστή[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(εκατοστή[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(διακοσιοστή[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τριακοσιοστή[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(τρετρακοσιοστή[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(πεντακοσιοστή[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(εξακοσιοστή[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(επτακοσιοστή[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(οκτακοσιοστή[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(εννεακοσιοστή[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(χιλιοστή[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(δισχιλιοστή[ →→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(τρισχιλιοστή[ →→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(τετράκις χιλιοστή[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(πεντάκις χιλιοστή[ →→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(εξάκις χιλιοστή[ →→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(επτάκις χιλιοστή[ →→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(οκτάκις χιλιοστή[ →→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(εννεάκις χιλιοστή[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(1000),
					rule => q(δεκάκις χιλιοστή[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← χιλιοστή[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμυριοστή [ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμυριοστή[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμυριοστή[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμυριοστή[ →→]),
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
					rule => q(μείον →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(μηδενικός),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(πρώτος),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(δεύτερος),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(τρίτος),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(τέταρτος),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(πέμπτος),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(έκτος),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(έβδομος),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(όγδοος),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ένατος),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(δέκατος),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ενδέκατος),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(δωδέκατος),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(δέκατος[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(εικοστός[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(τριακοστός[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(τεσσαρακοστός[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(πεντηκοστός[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(εξηκοστός[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(εβδομηκοστός[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ογδοηκοστός[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(εννενηκοστός[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(εκατοστός[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(διακοσιοστός[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τριακοσιοστός[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(τετρακοσιοστός[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(πεντακοσιοστός[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(εξακοσιοστός[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(επτακοσιοστός[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(οκτακοσιοστός[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(εννεακοσιοστός[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(χιλιοστός[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(δισχιλιοστός[ →→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(τρισχιλιοστός[ →→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(τετράκις χιλιοστός[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(πεντάκις χιλιοστός[ →→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(εξάκις χιλιοστός[ →→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(επτάκις χιλιοστός[ →→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(οκτάκις χιλιοστός[ →→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(εννεάκις χιλιοστός[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(1000),
					rule => q(δεκάκις χιλιοστός[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← χιλιοστός[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμυριοστός [ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμυριοστός[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμυριοστός[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμυριοστός[ →→]),
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
					rule => q(μείον →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(μηδενικό),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(πρώτο),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(δεύτερο),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(τρίτο),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(τέταρτο),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(πέμπτο),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(έκτο),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(έβδομο),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(όγδο),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ένατο),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(δέκατο),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ενδέκατο),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(δωδέκατο),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(δέκατο[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(εικοστό[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(τριακοστό[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(τεσσαρακοστό[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(πεντηκοστό[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(εξηκοστό[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(εβδομηκοστό[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ογδοηκοστό[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(εννενηκοστό[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(εκατοστό[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(διακοσιοστό[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(τριακοσιοστό[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(τετρακοσιοστό[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(πεντακοσιοστό[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(εξακοσιοστός[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(επτακοσιοστό[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(οκτακοσιοστό[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(εννεακοσιοστό[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(χιλιοστό[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(δισχιλιοστό[ →→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(τρισχιλιοστό[ →→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(τετράκις χιλιοστό[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(πεντάκις χιλιοστό[ →→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(εξάκις χιλιοστό[ →→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(επτάκις χιλιοστό[ →→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(οκτάκις χιλιοστό[ →→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(εννεάκις χιλιοστό[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(1000),
					rule => q(δεκάκις χιλιοστό[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← χιλιοστό[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← εκατομμυριοστό [ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← δισεκατομμυριοστό[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← τρισεκατομμυριοστό[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← τετράκις εκατομμυριοστό[ →→]),
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
				'aa' => 'Αφάρ',
 				'ab' => 'Αμπχαζικά',
 				'ace' => 'Ατσινιζικά',
 				'ach' => 'Ακολί',
 				'ada' => 'Αντάνγκμε',
 				'ady' => 'Αντιγκέα',
 				'ae' => 'Αβεστάν',
 				'af' => 'Αφρικάανς',
 				'afh' => 'Αφριχίλι',
 				'agq' => 'Αγκέμ',
 				'ain' => 'Αϊνού',
 				'ak' => 'Ακάν',
 				'akk' => 'Ακάντιαν',
 				'ale' => 'Αλεούτ',
 				'alt' => 'Νότια Αλτάι',
 				'am' => 'Αμχαρικά',
 				'an' => 'Αραγονικά',
 				'ang' => 'Παλαιά Αγγλικά',
 				'anp' => 'Ανγκικά',
 				'ar' => 'Αραβικά',
 				'ar_001' => 'Σύγχρονα Τυπικά Αραβικά',
 				'arc' => 'Αραμαϊκά',
 				'arn' => 'Αραουκανικά',
 				'arp' => 'Αραπάχο',
 				'ars' => 'Αραβικά Νάτζντι',
 				'arw' => 'Αραγουάκ',
 				'as' => 'Ασαμικά',
 				'asa' => 'Άσου',
 				'ast' => 'Αστουριανά',
 				'av' => 'Αβαρικά',
 				'awa' => 'Αγουαντί',
 				'ay' => 'Αϊμάρα',
 				'az' => 'Αζερμπαϊτζανικά',
 				'az@alt=short' => 'Αζερικά',
 				'ba' => 'Μπασκίρ',
 				'bal' => 'Μπαλούτσι',
 				'ban' => 'Μπαλινίζ',
 				'bas' => 'Μπάσα',
 				'bax' => 'Μπαμούν',
 				'bbj' => 'Γκομάλα',
 				'be' => 'Λευκορωσικά',
 				'bej' => 'Μπέζα',
 				'bem' => 'Μπέμπα',
 				'bez' => 'Μπένα',
 				'bfd' => 'Μπαφούτ',
 				'bg' => 'Βουλγαρικά',
 				'bgn' => 'Δυτικά Μπαλοχικά',
 				'bho' => 'Μπότζπουρι',
 				'bi' => 'Μπισλάμα',
 				'bik' => 'Μπικόλ',
 				'bin' => 'Μπίνι',
 				'bkm' => 'Κομ',
 				'bla' => 'Σικσίκα',
 				'bm' => 'Μπαμπάρα',
 				'bn' => 'Βεγγαλικά',
 				'bo' => 'Θιβετιανά',
 				'br' => 'Βρετονικά',
 				'bra' => 'Μπρατζ',
 				'brx' => 'Μπόντο',
 				'bs' => 'Βοσνιακά',
 				'bss' => 'Ακόσι',
 				'bua' => 'Μπουριάτ',
 				'bug' => 'Μπουγκίζ',
 				'bum' => 'Μπουλού',
 				'byn' => 'Μπλιν',
 				'byv' => 'Μεντούμπα',
 				'ca' => 'Καταλανικά',
 				'cad' => 'Κάντο',
 				'car' => 'Καρίμπ',
 				'cay' => 'Καγιούγκα',
 				'cch' => 'Ατσάμ',
 				'ce' => 'Τσετσενικά',
 				'ceb' => 'Σεμπουάνο',
 				'cgg' => 'Τσίγκα',
 				'ch' => 'Τσαμόρο',
 				'chb' => 'Τσίμπτσα',
 				'chg' => 'Τσαγκατάι',
 				'chk' => 'Τσουκίζι',
 				'chm' => 'Μάρι',
 				'chn' => 'Ιδιωματικά Σινούκ',
 				'cho' => 'Τσόκτο',
 				'chp' => 'Τσίπιουαν',
 				'chr' => 'Τσερόκι',
 				'chy' => 'Τσεγιέν',
 				'ckb' => 'Κουρδικά Σοράνι',
 				'co' => 'Κορσικανικά',
 				'cop' => 'Κοπτικά',
 				'cr' => 'Κρι',
 				'crh' => 'Τουρκικά Κριμαίας',
 				'crs' => 'Κρεολικά Γαλλικά Σεϋχελλών',
 				'cs' => 'Τσεχικά',
 				'csb' => 'Κασούμπιαν',
 				'cu' => 'Εκκλησιαστικά Σλαβικά',
 				'cv' => 'Τσουβασικά',
 				'cy' => 'Ουαλικά',
 				'da' => 'Δανικά',
 				'dak' => 'Ντακότα',
 				'dar' => 'Ντάργκουα',
 				'dav' => 'Τάιτα',
 				'de' => 'Γερμανικά',
 				'de_AT' => 'Γερμανικά Αυστρίας',
 				'de_CH' => 'Υψηλά Γερμανικά Ελβετίας',
 				'del' => 'Ντέλαγουερ',
 				'den' => 'Σλαβικά',
 				'dgr' => 'Ντόγκριμπ',
 				'din' => 'Ντίνκα',
 				'dje' => 'Ζάρμα',
 				'doi' => 'Ντόγκρι',
 				'dsb' => 'Κάτω Σορβικά',
 				'dua' => 'Ντουάλα',
 				'dum' => 'Μέσα Ολλανδικά',
 				'dv' => 'Ντιβέχι',
 				'dyo' => 'Τζόλα-Φόνι',
 				'dyu' => 'Ντογιούλα',
 				'dz' => 'Ντζόνγκχα',
 				'dzg' => 'Νταζάγκα',
 				'ebu' => 'Έμπου',
 				'ee' => 'Έουε',
 				'efi' => 'Εφίκ',
 				'egy' => 'Αρχαία Αιγυπτιακά',
 				'eka' => 'Εκατζούκ',
 				'el' => 'Ελληνικά',
 				'elx' => 'Ελαμάιτ',
 				'en' => 'Αγγλικά',
 				'en_AU' => 'Αγγλικά Αυστραλίας',
 				'en_CA' => 'Αγγλικά Καναδά',
 				'en_GB' => 'Αγγλικά Βρετανίας',
 				'en_GB@alt=short' => 'Αγγλικά ΗΒ',
 				'en_US' => 'Αγγλικά Αμερικής',
 				'en_US@alt=short' => 'Αγγλικά ΗΠΑ',
 				'enm' => 'Μέσα Αγγλικά',
 				'eo' => 'Εσπεράντο',
 				'es' => 'Ισπανικά',
 				'es_419' => 'Ισπανικά Λατινικής Αμερικής',
 				'es_ES' => 'Ισπανικά Ευρώπης',
 				'es_MX' => 'Ισπανικά Μεξικού',
 				'et' => 'Εσθονικά',
 				'eu' => 'Βασκικά',
 				'ewo' => 'Εγουόντο',
 				'fa' => 'Περσικά',
 				'fan' => 'Φανγκ',
 				'fat' => 'Φάντι',
 				'ff' => 'Φουλά',
 				'fi' => 'Φινλανδικά',
 				'fil' => 'Φιλιππινικά',
 				'fj' => 'Φίτζι',
 				'fo' => 'Φεροϊκά',
 				'fon' => 'Φον',
 				'fr' => 'Γαλλικά',
 				'fr_CA' => 'Γαλλικά Καναδά',
 				'fr_CH' => 'Γαλλικά Ελβετίας',
 				'frc' => 'Γαλλικά (Λουιζιάνα)',
 				'frm' => 'Μέσα Γαλλικά',
 				'fro' => 'Παλαιά Γαλλικά',
 				'frr' => 'Βόρεια Φριζιανά',
 				'frs' => 'Ανατολικά Φριζιανά',
 				'fur' => 'Φριουλανικά',
 				'fy' => 'Δυτικά Φριζικά',
 				'ga' => 'Ιρλανδικά',
 				'gaa' => 'Γκα',
 				'gag' => 'Γκαγκάουζ',
 				'gay' => 'Γκάγιο',
 				'gba' => 'Γκμπάγια',
 				'gd' => 'Σκωτικά Κελτικά',
 				'gez' => 'Γκιζ',
 				'gil' => 'Γκιλμπερτίζ',
 				'gl' => 'Γαλικιανά',
 				'gmh' => 'Μέσα Άνω Γερμανικά',
 				'gn' => 'Γκουαρανί',
 				'goh' => 'Παλαιά Άνω Γερμανικά',
 				'gon' => 'Γκόντι',
 				'gor' => 'Γκοροντάλο',
 				'got' => 'Γοτθικά',
 				'grb' => 'Γκρίμπο',
 				'grc' => 'Αρχαία Ελληνικά',
 				'gsw' => 'Γερμανικά Ελβετίας',
 				'gu' => 'Γκουγιαράτι',
 				'guz' => 'Γκούσι',
 				'gv' => 'Μανξ',
 				'gwi' => 'Γκουίτσιν',
 				'ha' => 'Χάουσα',
 				'hai' => 'Χάιντα',
 				'haw' => 'Χαβαϊκά',
 				'he' => 'Εβραϊκά',
 				'hi' => 'Χίντι',
 				'hil' => 'Χιλιγκαϊνόν',
 				'hit' => 'Χιτίτε',
 				'hmn' => 'Χμονγκ',
 				'ho' => 'Χίρι Μότου',
 				'hr' => 'Κροατικά',
 				'hsb' => 'Άνω Σορβικά',
 				'ht' => 'Αϊτιανά',
 				'hu' => 'Ουγγρικά',
 				'hup' => 'Χούπα',
 				'hy' => 'Αρμενικά',
 				'hz' => 'Χερέρο',
 				'ia' => 'Ιντερλίνγκουα',
 				'iba' => 'Ιμπάν',
 				'ibb' => 'Ιμπίμπιο',
 				'id' => 'Ινδονησιακά',
 				'ie' => 'Ιντερλίνγκουε',
 				'ig' => 'Ίγκμπο',
 				'ii' => 'Σίτσουαν Γι',
 				'ik' => 'Ινουπιάκ',
 				'ilo' => 'Ιλόκο',
 				'inh' => 'Ινγκούς',
 				'io' => 'Ίντο',
 				'is' => 'Ισλανδικά',
 				'it' => 'Ιταλικά',
 				'iu' => 'Ινούκτιτουτ',
 				'ja' => 'Ιαπωνικά',
 				'jbo' => 'Λόζμπαν',
 				'jgo' => 'Νγκόμπα',
 				'jmc' => 'Ματσάμε',
 				'jpr' => 'Ιουδαϊκά-Περσικά',
 				'jrb' => 'Ιουδαϊκά-Αραβικά',
 				'jv' => 'Ιαβανικά',
 				'ka' => 'Γεωργιανά',
 				'kaa' => 'Κάρα-Καλπάκ',
 				'kab' => 'Καμπίλε',
 				'kac' => 'Κατσίν',
 				'kaj' => 'Τζου',
 				'kam' => 'Κάμπα',
 				'kaw' => 'Κάουι',
 				'kbd' => 'Καμπαρντιανά',
 				'kbl' => 'Κανέμπου',
 				'kcg' => 'Τιάπ',
 				'kde' => 'Μακόντε',
 				'kea' => 'Γλώσσα του Πράσινου Ακρωτηρίου',
 				'kfo' => 'Κόρο',
 				'kg' => 'Κονγκό',
 				'kha' => 'Κάσι',
 				'kho' => 'Κοτανικά',
 				'khq' => 'Κόιρα Τσίνι',
 				'ki' => 'Κικούγιου',
 				'kj' => 'Κουανιάμα',
 				'kk' => 'Καζακικά',
 				'kkj' => 'Κάκο',
 				'kl' => 'Καλαάλισουτ',
 				'kln' => 'Καλεντζίν',
 				'km' => 'Χμερ',
 				'kmb' => 'Κιμπούντου',
 				'kn' => 'Κανάντα',
 				'ko' => 'Κορεατικά',
 				'koi' => 'Κόμι-Περμιάκ',
 				'kok' => 'Κονκανικά',
 				'kos' => 'Κοσραενικά',
 				'kpe' => 'Κπέλε',
 				'kr' => 'Κανούρι',
 				'krc' => 'Καρατσάι-Μπαλκάρ',
 				'krl' => 'Καρελικά',
 				'kru' => 'Κουρούχ',
 				'ks' => 'Κασμιρικά',
 				'ksb' => 'Σαμπάλα',
 				'ksf' => 'Μπάφια',
 				'ksh' => 'Κολωνικά',
 				'ku' => 'Κουρδικά',
 				'kum' => 'Κουμγιούκ',
 				'kut' => 'Κουτενάι',
 				'kv' => 'Κόμι',
 				'kw' => 'Κορνουαλικά',
 				'ky' => 'Κιργιζικά',
 				'la' => 'Λατινικά',
 				'lad' => 'Λαδίνο',
 				'lag' => 'Λάνγκι',
 				'lah' => 'Λάχδα',
 				'lam' => 'Λάμπα',
 				'lb' => 'Λουξεμβουργιανά',
 				'lez' => 'Λεζγκικά',
 				'lg' => 'Γκάντα',
 				'li' => 'Λιμβουργιανά',
 				'lkt' => 'Λακότα',
 				'ln' => 'Λινγκάλα',
 				'lo' => 'Λαοτινά',
 				'lol' => 'Μόνγκο',
 				'lou' => 'Κρεολικά (Λουιζιάνα)',
 				'loz' => 'Λόζι',
 				'lrc' => 'Βόρεια Λούρι',
 				'lt' => 'Λιθουανικά',
 				'lu' => 'Λούμπα-Κατάνγκα',
 				'lua' => 'Λούμπα-Λουλούα',
 				'lui' => 'Λουισένο',
 				'lun' => 'Λούντα',
 				'luo' => 'Λούο',
 				'lus' => 'Μίζο',
 				'luy' => 'Λούχια',
 				'lv' => 'Λετονικά',
 				'mad' => 'Μαντουρίζ',
 				'maf' => 'Μάφα',
 				'mag' => 'Μαγκάχι',
 				'mai' => 'Μαϊτχίλι',
 				'mak' => 'Μακασάρ',
 				'man' => 'Μαντίνγκο',
 				'mas' => 'Μασάι',
 				'mde' => 'Μάμπα',
 				'mdf' => 'Μόκσα',
 				'mdr' => 'Μανδάρ',
 				'men' => 'Μέντε',
 				'mer' => 'Μέρου',
 				'mfe' => 'Μορισιέν',
 				'mg' => 'Μαλγασικά',
 				'mga' => 'Μέσα Ιρλανδικά',
 				'mgh' => 'Μακούβα-Μέτο',
 				'mgo' => 'Μέτα',
 				'mh' => 'Μαρσαλέζικα',
 				'mi' => 'Μαορί',
 				'mic' => 'Μικμάκ',
 				'min' => 'Μινανγκαμπάου',
 				'mk' => 'Σλαβομακεδονικά',
 				'ml' => 'Μαλαγιαλαμικά',
 				'mn' => 'Μογγολικά',
 				'mnc' => 'Μαντσού',
 				'mni' => 'Μανιπούρι',
 				'moh' => 'Μοχόκ',
 				'mos' => 'Μόσι',
 				'mr' => 'Μαραθικά',
 				'ms' => 'Μαλαισιανά',
 				'mt' => 'Μαλτεζικά',
 				'mua' => 'Μουντάνγκ',
 				'mul' => 'Πολλαπλές γλώσσες',
 				'mus' => 'Κρικ',
 				'mwl' => 'Μιραντεζικά',
 				'mwr' => 'Μαργουάρι',
 				'my' => 'Βιρμανικά',
 				'mye' => 'Μιένε',
 				'myv' => 'Έρζια',
 				'mzn' => 'Μαζαντεράνι',
 				'na' => 'Ναούρου',
 				'nap' => 'Ναπολιτανικά',
 				'naq' => 'Νάμα',
 				'nb' => 'Νορβηγικά Μποκμάλ',
 				'nd' => 'Βόρεια Ντεμπέλε',
 				'nds' => 'Κάτω Γερμανικά',
 				'nds_NL' => 'Κάτω Γερμανικά Ολλανδίας',
 				'ne' => 'Νεπαλικά',
 				'new' => 'Νεγουάρι',
 				'ng' => 'Ντόνγκα',
 				'nia' => 'Νίας',
 				'niu' => 'Νιούε',
 				'nl' => 'Ολλανδικά',
 				'nl_BE' => 'Φλαμανδικά',
 				'nmg' => 'Κβάσιο',
 				'nn' => 'Νορβηγικά Νινόρσκ',
 				'nnh' => 'Νγκιεμπούν',
 				'no' => 'Νορβηγικά',
 				'nog' => 'Νογκάι',
 				'non' => 'Παλαιά Νορβηγικά',
 				'nqo' => 'Ν’Κο',
 				'nr' => 'Νότια Ντεμπέλε',
 				'nso' => 'Βόρεια Σόθο',
 				'nus' => 'Νούερ',
 				'nv' => 'Νάβαχο',
 				'nwc' => 'Κλασικά Νεουάρι',
 				'ny' => 'Νιάντζα',
 				'nym' => 'Νιαμγουέζι',
 				'nyn' => 'Νιανκόλε',
 				'nyo' => 'Νιόρο',
 				'nzi' => 'Νζίμα',
 				'oc' => 'Οξιτανικά',
 				'oj' => 'Οζιβίγουα',
 				'om' => 'Ορόμο',
 				'or' => 'Όντια',
 				'os' => 'Οσετικά',
 				'osa' => 'Οσάζ',
 				'ota' => 'Οθωμανικά Τουρκικά',
 				'pa' => 'Παντζαπικά',
 				'pag' => 'Πανγκασινάν',
 				'pal' => 'Παχλάβι',
 				'pam' => 'Παμπάνγκα',
 				'pap' => 'Παπιαμέντο',
 				'pau' => 'Παλάουαν',
 				'pcm' => 'Πίτζιν Νιγηρίας',
 				'peo' => 'Αρχαία Περσικά',
 				'phn' => 'Φοινικικά',
 				'pi' => 'Πάλι',
 				'pl' => 'Πολωνικά',
 				'pon' => 'Πομπηικά',
 				'prg' => 'Πρωσικά',
 				'pro' => 'Παλαιά Προβανσάλ',
 				'ps' => 'Πάστο',
 				'pt' => 'Πορτογαλικά',
 				'pt_BR' => 'Πορτογαλικά Βραζιλίας',
 				'pt_PT' => 'Πορτογαλικά Ευρώπης',
 				'qu' => 'Κέτσουα',
 				'quc' => 'Κιτσέ',
 				'raj' => 'Ραζασθάνι',
 				'rap' => 'Ραπανούι',
 				'rar' => 'Ραροτονγκάν',
 				'rm' => 'Ρομανικά',
 				'rn' => 'Ρούντι',
 				'ro' => 'Ρουμανικά',
 				'ro_MD' => 'Μολδαβικά',
 				'rof' => 'Ρόμπο',
 				'rom' => 'Ρομανί',
 				'root' => 'Ρίζα',
 				'ru' => 'Ρωσικά',
 				'rup' => 'Αρομανικά',
 				'rw' => 'Κινιαρουάντα',
 				'rwk' => 'Ρουά',
 				'sa' => 'Σανσκριτικά',
 				'sad' => 'Σαντάγουε',
 				'sah' => 'Σαχά',
 				'sam' => 'Σαμαρίτικα Αραμαϊκά',
 				'saq' => 'Σαμπούρου',
 				'sas' => 'Σασάκ',
 				'sat' => 'Σαντάλι',
 				'sba' => 'Νγκαμπέι',
 				'sbp' => 'Σάνγκου',
 				'sc' => 'Σαρδηνιακά',
 				'scn' => 'Σικελικά',
 				'sco' => 'Σκωτικά',
 				'sd' => 'Σίντι',
 				'sdh' => 'Νότια Κουρδικά',
 				'se' => 'Βόρεια Σάμι',
 				'see' => 'Σένεκα',
 				'seh' => 'Σένα',
 				'sel' => 'Σελκούπ',
 				'ses' => 'Κοϊραμπόρο Σένι',
 				'sg' => 'Σάνγκο',
 				'sga' => 'Παλαιά Ιρλανδικά',
 				'sh' => 'Σερβοκροατικά',
 				'shi' => 'Τασελχίτ',
 				'shn' => 'Σαν',
 				'shu' => 'Αραβικά του Τσαντ',
 				'si' => 'Σινχαλεζικά',
 				'sid' => 'Σιντάμο',
 				'sk' => 'Σλοβακικά',
 				'sl' => 'Σλοβενικά',
 				'sm' => 'Σαμοανά',
 				'sma' => 'Νότια Σάμι',
 				'smj' => 'Λούλε Σάμι',
 				'smn' => 'Ινάρι Σάμι',
 				'sms' => 'Σκολτ Σάμι',
 				'sn' => 'Σόνα',
 				'snk' => 'Σονίνκε',
 				'so' => 'Σομαλικά',
 				'sog' => 'Σογκντιέν',
 				'sq' => 'Αλβανικά',
 				'sr' => 'Σερβικά',
 				'srn' => 'Σρανάν Τόνγκο',
 				'srr' => 'Σερέρ',
 				'ss' => 'Σουάτι',
 				'ssy' => 'Σάχο',
 				'st' => 'Νότια Σόθο',
 				'su' => 'Σουνδανικά',
 				'suk' => 'Σουκούμα',
 				'sus' => 'Σούσου',
 				'sux' => 'Σουμερικά',
 				'sv' => 'Σουηδικά',
 				'sw' => 'Σουαχίλι',
 				'sw_CD' => 'Κονγκό Σουαχίλι',
 				'swb' => 'Κομοριανά',
 				'syc' => 'Κλασικά Συριακά',
 				'syr' => 'Συριακά',
 				'ta' => 'Ταμιλικά',
 				'te' => 'Τελούγκου',
 				'tem' => 'Τίμνε',
 				'teo' => 'Τέσο',
 				'ter' => 'Τερένο',
 				'tet' => 'Τέτουμ',
 				'tg' => 'Τατζικικά',
 				'th' => 'Ταϊλανδικά',
 				'ti' => 'Τιγκρινικά',
 				'tig' => 'Τίγκρε',
 				'tiv' => 'Τιβ',
 				'tk' => 'Τουρκμενικά',
 				'tkl' => 'Τοκελάου',
 				'tl' => 'Τάγκαλογκ',
 				'tlh' => 'Κλίνγκον',
 				'tli' => 'Τλίνγκιτ',
 				'tmh' => 'Ταμασέκ',
 				'tn' => 'Τσουάνα',
 				'to' => 'Τονγκανικά',
 				'tog' => 'Νιάσα Τόνγκα',
 				'tpi' => 'Τοκ Πισίν',
 				'tr' => 'Τουρκικά',
 				'trv' => 'Ταρόκο',
 				'ts' => 'Τσόνγκα',
 				'tsi' => 'Τσίμσιαν',
 				'tt' => 'Ταταρικά',
 				'tum' => 'Τουμπούκα',
 				'tvl' => 'Τουβαλού',
 				'tw' => 'Τούι',
 				'twq' => 'Τασαβάκ',
 				'ty' => 'Ταϊτιανά',
 				'tyv' => 'Τουβινικά',
 				'tzm' => 'Ταμαζίτ Κεντρικού Μαρόκο',
 				'udm' => 'Ουντμούρτ',
 				'ug' => 'Ουιγκουρικά',
 				'ug@alt=variant' => 'Ουιγκούρ',
 				'uga' => 'Ουγκαριτικά',
 				'uk' => 'Ουκρανικά',
 				'umb' => 'Ουμπούντου',
 				'und' => 'Άγνωστη γλώσσα',
 				'ur' => 'Ουρντού',
 				'uz' => 'Ουζμπεκικά',
 				'vai' => 'Βάι',
 				've' => 'Βέντα',
 				'vi' => 'Βιετναμικά',
 				'vo' => 'Βολαπιούκ',
 				'vot' => 'Βότικ',
 				'vun' => 'Βούντζο',
 				'wa' => 'Βαλλωνικά',
 				'wae' => 'Βάλσερ',
 				'wal' => 'Γουολάιτα',
 				'war' => 'Γουάραϊ',
 				'was' => 'Γουασό',
 				'wbp' => 'Γουαρλπίρι',
 				'wo' => 'Γουόλοφ',
 				'wuu' => 'Κινεζικά Γου',
 				'xal' => 'Καλμίκ',
 				'xh' => 'Κόσα',
 				'xog' => 'Σόγκα',
 				'yao' => 'Γιάο',
 				'yap' => 'Γιαπίζ',
 				'yav' => 'Γιανγκμπέν',
 				'ybb' => 'Γιέμπα',
 				'yi' => 'Γίντις',
 				'yo' => 'Γιορούμπα',
 				'yue' => 'Καντονέζικα',
 				'za' => 'Ζουάνγκ',
 				'zap' => 'Ζάποτεκ',
 				'zbl' => 'Σύμβολα Bliss',
 				'zen' => 'Ζενάγκα',
 				'zgh' => 'Τυπικά Ταμαζίτ Μαρόκου',
 				'zh' => 'Κινεζικά',
 				'zh_Hans' => 'Απλοποιημένα Κινεζικά',
 				'zh_Hant' => 'Παραδοσιακά Κινεζικά',
 				'zu' => 'Ζουλού',
 				'zun' => 'Ζούνι',
 				'zxx' => 'Χωρίς γλωσσολογικό περιεχόμενο',
 				'zza' => 'Ζάζα',

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
			'Arab' => 'Αραβικό',
 			'Arab@alt=variant' => 'Περσικό-Αραβικό',
 			'Armi' => 'Αυτοκρατορικό Αραμαϊκό',
 			'Armn' => 'Αρμενικό',
 			'Avst' => 'Αβεστάν',
 			'Bali' => 'Μπαλινίζ',
 			'Batk' => 'Μπατάκ',
 			'Beng' => 'Μπενγκάλι',
 			'Blis' => 'Σύμβολα Bliss',
 			'Bopo' => 'Μποπομόφο',
 			'Brah' => 'Μπραχμί',
 			'Brai' => 'Μπράιγ',
 			'Bugi' => 'Μπούγκις',
 			'Buhd' => 'Μπουχίντ',
 			'Cakm' => 'Τσάκμα',
 			'Cans' => 'Ενοποιημένοι Καναδεζικοί Συλλαβισμοί Ιθαγενών',
 			'Cari' => 'Καριάν',
 			'Cham' => 'Τσαμ',
 			'Cher' => 'Τσερόκι',
 			'Cirt' => 'Σερθ',
 			'Copt' => 'Κοπτικό',
 			'Cprt' => 'Κυπριακό',
 			'Cyrl' => 'Κυριλλικό',
 			'Cyrs' => 'Παλαιό Εκκλησιαστικό Σλαβικό Κυριλλικό',
 			'Deva' => 'Ντεβαναγκάρι',
 			'Dsrt' => 'Ντεσερέ',
 			'Egyd' => 'Λαϊκό Αιγυπτιακό',
 			'Egyh' => 'Ιερατικό Αιγυπτιακό',
 			'Egyp' => 'Αιγυπτιακά Ιερογλυφικά',
 			'Ethi' => 'Αιθιοπικό',
 			'Geok' => 'Γεωργιανό Κχουτσούρι',
 			'Geor' => 'Γεωργιανό',
 			'Glag' => 'Γκλαγκολιτικό',
 			'Goth' => 'Γοτθικό',
 			'Grek' => 'Ελληνικό',
 			'Gujr' => 'Γκουγιαράτι',
 			'Guru' => 'Γκουρμουκχί',
 			'Hanb' => 'Χανμπ',
 			'Hang' => 'Χανγκούλ',
 			'Hani' => 'Χαν',
 			'Hano' => 'Χανούνου',
 			'Hans' => 'Απλοποιημένο',
 			'Hans@alt=stand-alone' => 'Απλοποιημένο Χαν',
 			'Hant' => 'Παραδοσιακό',
 			'Hant@alt=stand-alone' => 'Παραδοσιακό Χαν',
 			'Hebr' => 'Εβραϊκό',
 			'Hira' => 'Χιραγκάνα',
 			'Hmng' => 'Παχάχ Χμονγκ',
 			'Hrkt' => 'Κατακάνα ή Χιραγκάνα',
 			'Hung' => 'Παλαιό Ουγγρικό',
 			'Inds' => 'Ίνδους',
 			'Ital' => 'Παλαιό Ιταλικό',
 			'Jamo' => 'Τζάμο',
 			'Java' => 'Ιαβανεζικό',
 			'Jpan' => 'Ιαπωνικό',
 			'Kali' => 'Καγιάχ Λι',
 			'Kana' => 'Κατακάνα',
 			'Khar' => 'Καρόσθι',
 			'Khmr' => 'Χμερ',
 			'Knda' => 'Κανάντα',
 			'Kore' => 'Κορεατικό',
 			'Kthi' => 'Καϊθί',
 			'Lana' => 'Λάννα',
 			'Laoo' => 'Λαοτινό',
 			'Latf' => 'Φράκτουρ Λατινικό',
 			'Latg' => 'Γαελικό Λατινικό',
 			'Latn' => 'Λατινικό',
 			'Lepc' => 'Λέπτσα',
 			'Limb' => 'Λιμπού',
 			'Lina' => 'Γραμμικό Α',
 			'Linb' => 'Γραμμικό Β',
 			'Lyci' => 'Λυκιανικό',
 			'Lydi' => 'Λυδιανικό',
 			'Mand' => 'Μανδαϊκό',
 			'Mani' => 'Μανιχαϊκό',
 			'Maya' => 'Ιερογλυφικά Μάγια',
 			'Mero' => 'Μεροϊτικό',
 			'Mlym' => 'Μαλαγιάλαμ',
 			'Mong' => 'Μογγολικό',
 			'Moon' => 'Μουν',
 			'Mtei' => 'Μεϊτέι Μάγεκ',
 			'Mymr' => 'Μιανμάρ',
 			'Nkoo' => 'Ν’Κο',
 			'Ogam' => 'Όγκχαμ',
 			'Olck' => 'Ολ Τσίκι',
 			'Orkh' => 'Όρκχον',
 			'Orya' => 'Όντια',
 			'Osma' => 'Οσμάνγια',
 			'Perm' => 'Παλαιό Περμικό',
 			'Phag' => 'Παγκς-πα',
 			'Phli' => 'Επιγραφικό Παχλάβι',
 			'Phlp' => 'Ψάλτερ Παχλάβι',
 			'Phlv' => 'Μπουκ Παχλαβί',
 			'Phnx' => 'Φοινικικό',
 			'Plrd' => 'Φωνητικό Πόλαρντ',
 			'Prti' => 'Επιγραφικό Παρθιάν',
 			'Rjng' => 'Ρετζάνγκ',
 			'Roro' => 'Ρονγκορόνγκο',
 			'Runr' => 'Ρουνίκ',
 			'Samr' => 'Σαμαριτικό',
 			'Sara' => 'Σαράθι',
 			'Saur' => 'Σαουράστρα',
 			'Sgnw' => 'Νοηματική γραφή',
 			'Shaw' => 'Σαβιανό',
 			'Sinh' => 'Σινχάλα',
 			'Sund' => 'Σουνδανικό',
 			'Sylo' => 'Συλότι Νάγκρι',
 			'Syrc' => 'Συριακό',
 			'Syre' => 'Εστραντζέλο Συριακό',
 			'Syrj' => 'Δυτικό Συριακό',
 			'Syrn' => 'Ανατολικό Συριακό',
 			'Tagb' => 'Ταγκμάνγουα',
 			'Tale' => 'Τάι Λε',
 			'Talu' => 'Νέο Τάι Λούε',
 			'Taml' => 'Ταμίλ',
 			'Tavt' => 'Τάι Βιέτ',
 			'Telu' => 'Τελούγκου',
 			'Teng' => 'Τεγνγουάρ',
 			'Tfng' => 'Τιφινάγκ',
 			'Tglg' => 'Ταγκαλόγκ',
 			'Thaa' => 'Θαανά',
 			'Thai' => 'Ταϊλανδικό',
 			'Tibt' => 'Θιβετιανό',
 			'Ugar' => 'Ουγκαριτικό',
 			'Vaii' => 'Βάι',
 			'Visp' => 'Ορατή ομιλία',
 			'Xpeo' => 'Παλαιό Περσικό',
 			'Xsux' => 'Σούμερο-Ακάντιαν Κουνεϊφόρμ',
 			'Yiii' => 'Γι',
 			'Zinh' => 'Κληρονομημένο',
 			'Zmth' => 'Μαθηματική σημειογραφία',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Σύμβολα',
 			'Zxxx' => 'Άγραφο',
 			'Zyyy' => 'Κοινό',
 			'Zzzz' => 'Άγνωστη γραφή',

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
			'001' => 'Κόσμος',
 			'002' => 'Αφρική',
 			'003' => 'Βόρεια Αμερική',
 			'005' => 'Νότια Αμερική',
 			'009' => 'Ωκεανία',
 			'011' => 'Δυτική Αφρική',
 			'013' => 'Κεντρική Αμερική',
 			'014' => 'Ανατολική Αφρική',
 			'015' => 'Βόρεια Αφρική',
 			'017' => 'Μέση Αφρική',
 			'018' => 'Νότιος Αφρική',
 			'019' => 'Αμερική',
 			'021' => 'Βόρειος Αμερική',
 			'029' => 'Καραϊβική',
 			'030' => 'Ανατολική Ασία',
 			'034' => 'Νότια Ασία',
 			'035' => 'Νοτιοανατολική Ασία',
 			'039' => 'Νότια Ευρώπη',
 			'053' => 'Αυστραλασία',
 			'054' => 'Μελανησία',
 			'057' => 'Περιοχή Μικρονησίας',
 			'061' => 'Πολυνησία',
 			'142' => 'Ασία',
 			'143' => 'Κεντρική Ασία',
 			'145' => 'Δυτική Ασία',
 			'150' => 'Ευρώπη',
 			'151' => 'Ανατολική Ευρώπη',
 			'154' => 'Βόρεια Ευρώπη',
 			'155' => 'Δυτική Ευρώπη',
 			'202' => 'Υποσαχάρια Αφρική',
 			'419' => 'Λατινική Αμερική',
 			'AC' => 'Νήσος Ασενσιόν',
 			'AD' => 'Ανδόρα',
 			'AE' => 'Ηνωμένα Αραβικά Εμιράτα',
 			'AF' => 'Αφγανιστάν',
 			'AG' => 'Αντίγκουα και Μπαρμπούντα',
 			'AI' => 'Ανγκουίλα',
 			'AL' => 'Αλβανία',
 			'AM' => 'Αρμενία',
 			'AO' => 'Αγκόλα',
 			'AQ' => 'Ανταρκτική',
 			'AR' => 'Αργεντινή',
 			'AS' => 'Αμερικανική Σαμόα',
 			'AT' => 'Αυστρία',
 			'AU' => 'Αυστραλία',
 			'AW' => 'Αρούμπα',
 			'AX' => 'Νήσοι Όλαντ',
 			'AZ' => 'Αζερμπαϊτζάν',
 			'BA' => 'Βοσνία - Ερζεγοβίνη',
 			'BB' => 'Μπαρμπέιντος',
 			'BD' => 'Μπανγκλαντές',
 			'BE' => 'Βέλγιο',
 			'BF' => 'Μπουρκίνα Φάσο',
 			'BG' => 'Βουλγαρία',
 			'BH' => 'Μπαχρέιν',
 			'BI' => 'Μπουρούντι',
 			'BJ' => 'Μπενίν',
 			'BL' => 'Άγιος Βαρθολομαίος',
 			'BM' => 'Βερμούδες',
 			'BN' => 'Μπρουνέι',
 			'BO' => 'Βολιβία',
 			'BQ' => 'Ολλανδία Καραϊβικής',
 			'BR' => 'Βραζιλία',
 			'BS' => 'Μπαχάμες',
 			'BT' => 'Μπουτάν',
 			'BV' => 'Νήσος Μπουβέ',
 			'BW' => 'Μποτσουάνα',
 			'BY' => 'Λευκορωσία',
 			'BZ' => 'Μπελίζ',
 			'CA' => 'Καναδάς',
 			'CC' => 'Νήσοι Κόκος (Κίλινγκ)',
 			'CD' => 'Κονγκό - Κινσάσα',
 			'CD@alt=variant' => 'Κονγκό (ΛΔΚ)',
 			'CF' => 'Κεντροαφρικανική Δημοκρατία',
 			'CG' => 'Κονγκό - Μπραζαβίλ',
 			'CG@alt=variant' => 'Κονγκό (Δημοκρατία)',
 			'CH' => 'Ελβετία',
 			'CI' => 'Ακτή Ελεφαντοστού',
 			'CK' => 'Νήσοι Κουκ',
 			'CL' => 'Χιλή',
 			'CM' => 'Καμερούν',
 			'CN' => 'Κίνα',
 			'CO' => 'Κολομβία',
 			'CP' => 'Νήσος Κλίπερτον',
 			'CR' => 'Κόστα Ρίκα',
 			'CU' => 'Κούβα',
 			'CV' => 'Πράσινο Ακρωτήριο',
 			'CW' => 'Κουρασάο',
 			'CX' => 'Νήσος των Χριστουγέννων',
 			'CY' => 'Κύπρος',
 			'CZ' => 'Τσεχία',
 			'CZ@alt=variant' => 'Τσεχική Δημοκρατία',
 			'DE' => 'Γερμανία',
 			'DG' => 'Ντιέγκο Γκαρσία',
 			'DJ' => 'Τζιμπουτί',
 			'DK' => 'Δανία',
 			'DM' => 'Ντομίνικα',
 			'DO' => 'Δομινικανή Δημοκρατία',
 			'DZ' => 'Αλγερία',
 			'EA' => 'Θέουτα και Μελίγια',
 			'EC' => 'Ισημερινός',
 			'EE' => 'Εσθονία',
 			'EG' => 'Αίγυπτος',
 			'EH' => 'Δυτική Σαχάρα',
 			'ER' => 'Ερυθραία',
 			'ES' => 'Ισπανία',
 			'ET' => 'Αιθιοπία',
 			'EU' => 'Ευρωπαϊκή Ένωση',
 			'EZ' => 'Ευρωζώνη',
 			'FI' => 'Φινλανδία',
 			'FJ' => 'Φίτζι',
 			'FK' => 'Νήσοι Φόκλαντ',
 			'FK@alt=variant' => 'Νήσοι Φόκλαντ (Νήσοι Μαλβίνας)',
 			'FM' => 'Μικρονησία',
 			'FO' => 'Νήσοι Φερόες',
 			'FR' => 'Γαλλία',
 			'GA' => 'Γκαμπόν',
 			'GB' => 'Ηνωμένο Βασίλειο',
 			'GB@alt=short' => 'ΗΒ',
 			'GD' => 'Γρενάδα',
 			'GE' => 'Γεωργία',
 			'GF' => 'Γαλλική Γουιάνα',
 			'GG' => 'Γκέρνζι',
 			'GH' => 'Γκάνα',
 			'GI' => 'Γιβραλτάρ',
 			'GL' => 'Γροιλανδία',
 			'GM' => 'Γκάμπια',
 			'GN' => 'Γουινέα',
 			'GP' => 'Γουαδελούπη',
 			'GQ' => 'Ισημερινή Γουινέα',
 			'GR' => 'Ελλάδα',
 			'GS' => 'Νήσοι Νότια Γεωργία και Νότιες Σάντουιτς',
 			'GT' => 'Γουατεμάλα',
 			'GU' => 'Γκουάμ',
 			'GW' => 'Γουινέα Μπισάου',
 			'GY' => 'Γουιάνα',
 			'HK' => 'Χονγκ Κονγκ ΕΔΠ Κίνας',
 			'HK@alt=short' => 'Χονγκ Κονγκ',
 			'HM' => 'Νήσοι Χερντ και Μακντόναλντ',
 			'HN' => 'Ονδούρα',
 			'HR' => 'Κροατία',
 			'HT' => 'Αϊτή',
 			'HU' => 'Ουγγαρία',
 			'IC' => 'Κανάριοι Νήσοι',
 			'ID' => 'Ινδονησία',
 			'IE' => 'Ιρλανδία',
 			'IL' => 'Ισραήλ',
 			'IM' => 'Νήσος του Μαν',
 			'IN' => 'Ινδία',
 			'IO' => 'Βρετανικά Εδάφη Ινδικού Ωκεανού',
 			'IQ' => 'Ιράκ',
 			'IR' => 'Ιράν',
 			'IS' => 'Ισλανδία',
 			'IT' => 'Ιταλία',
 			'JE' => 'Τζέρζι',
 			'JM' => 'Τζαμάικα',
 			'JO' => 'Ιορδανία',
 			'JP' => 'Ιαπωνία',
 			'KE' => 'Κένυα',
 			'KG' => 'Κιργιστάν',
 			'KH' => 'Καμπότζη',
 			'KI' => 'Κιριμπάτι',
 			'KM' => 'Κομόρες',
 			'KN' => 'Σεν Κιτς και Νέβις',
 			'KP' => 'Βόρεια Κορέα',
 			'KR' => 'Νότια Κορέα',
 			'KW' => 'Κουβέιτ',
 			'KY' => 'Νήσοι Κέιμαν',
 			'KZ' => 'Καζακστάν',
 			'LA' => 'Λάος',
 			'LB' => 'Λίβανος',
 			'LC' => 'Αγία Λουκία',
 			'LI' => 'Λιχτενστάιν',
 			'LK' => 'Σρι Λάνκα',
 			'LR' => 'Λιβερία',
 			'LS' => 'Λεσότο',
 			'LT' => 'Λιθουανία',
 			'LU' => 'Λουξεμβούργο',
 			'LV' => 'Λετονία',
 			'LY' => 'Λιβύη',
 			'MA' => 'Μαρόκο',
 			'MC' => 'Μονακό',
 			'MD' => 'Μολδαβία',
 			'ME' => 'Μαυροβούνιο',
 			'MF' => 'Άγιος Μαρτίνος (Γαλλικό τμήμα)',
 			'MG' => 'Μαδαγασκάρη',
 			'MH' => 'Νήσοι Μάρσαλ',
 			'MK' => 'Πρώην Γιουγκοσλαβική Δημοκρατία της Μακεδονίας',
 			'MK@alt=variant' => 'Πρώην Γιουγκοσλαβική Δημοκρατία της Μακεδονίας (ΠΓΔΜ)',
 			'ML' => 'Μάλι',
 			'MM' => 'Μιανμάρ (Βιρμανία)',
 			'MN' => 'Μογγολία',
 			'MO' => 'Μακάο ΕΔΠ Κίνας',
 			'MO@alt=short' => 'Μακάο',
 			'MP' => 'Νήσοι Βόρειες Μαριάνες',
 			'MQ' => 'Μαρτινίκα',
 			'MR' => 'Μαυριτανία',
 			'MS' => 'Μονσεράτ',
 			'MT' => 'Μάλτα',
 			'MU' => 'Μαυρίκιος',
 			'MV' => 'Μαλδίβες',
 			'MW' => 'Μαλάουι',
 			'MX' => 'Μεξικό',
 			'MY' => 'Μαλαισία',
 			'MZ' => 'Μοζαμβίκη',
 			'NA' => 'Ναμίμπια',
 			'NC' => 'Νέα Καληδονία',
 			'NE' => 'Νίγηρας',
 			'NF' => 'Νήσος Νόρφολκ',
 			'NG' => 'Νιγηρία',
 			'NI' => 'Νικαράγουα',
 			'NL' => 'Ολλανδία',
 			'NO' => 'Νορβηγία',
 			'NP' => 'Νεπάλ',
 			'NR' => 'Ναουρού',
 			'NU' => 'Νιούε',
 			'NZ' => 'Νέα Ζηλανδία',
 			'OM' => 'Ομάν',
 			'PA' => 'Παναμάς',
 			'PE' => 'Περού',
 			'PF' => 'Γαλλική Πολυνησία',
 			'PG' => 'Παπούα Νέα Γουινέα',
 			'PH' => 'Φιλιππίνες',
 			'PK' => 'Πακιστάν',
 			'PL' => 'Πολωνία',
 			'PM' => 'Σεν Πιερ και Μικελόν',
 			'PN' => 'Νήσοι Πίτκερν',
 			'PR' => 'Πουέρτο Ρίκο',
 			'PS' => 'Παλαιστινιακά Εδάφη',
 			'PS@alt=short' => 'Παλαιστίνη',
 			'PT' => 'Πορτογαλία',
 			'PW' => 'Παλάου',
 			'PY' => 'Παραγουάη',
 			'QA' => 'Κατάρ',
 			'QO' => 'Περιφερειακή Ωκεανία',
 			'RE' => 'Ρεϊνιόν',
 			'RO' => 'Ρουμανία',
 			'RS' => 'Σερβία',
 			'RU' => 'Ρωσία',
 			'RW' => 'Ρουάντα',
 			'SA' => 'Σαουδική Αραβία',
 			'SB' => 'Νήσοι Σολομώντος',
 			'SC' => 'Σεϋχέλλες',
 			'SD' => 'Σουδάν',
 			'SE' => 'Σουηδία',
 			'SG' => 'Σιγκαπούρη',
 			'SH' => 'Αγία Ελένη',
 			'SI' => 'Σλοβενία',
 			'SJ' => 'Σβάλμπαρντ και Γιαν Μαγιέν',
 			'SK' => 'Σλοβακία',
 			'SL' => 'Σιέρα Λεόνε',
 			'SM' => 'Άγιος Μαρίνος',
 			'SN' => 'Σενεγάλη',
 			'SO' => 'Σομαλία',
 			'SR' => 'Σουρινάμ',
 			'SS' => 'Νότιο Σουδάν',
 			'ST' => 'Σάο Τομέ και Πρίνσιπε',
 			'SV' => 'Ελ Σαλβαδόρ',
 			'SX' => 'Άγιος Μαρτίνος (Ολλανδικό τμήμα)',
 			'SY' => 'Συρία',
 			'SZ' => 'Σουαζιλάνδη',
 			'TA' => 'Τριστάν ντα Κούνια',
 			'TC' => 'Νήσοι Τερκς και Κάικος',
 			'TD' => 'Τσαντ',
 			'TF' => 'Γαλλικά Νότια Εδάφη',
 			'TG' => 'Τόγκο',
 			'TH' => 'Ταϊλάνδη',
 			'TJ' => 'Τατζικιστάν',
 			'TK' => 'Τοκελάου',
 			'TL' => 'Τιμόρ-Λέστε',
 			'TL@alt=variant' => 'Ανατολικό Τιμόρ',
 			'TM' => 'Τουρκμενιστάν',
 			'TN' => 'Τυνησία',
 			'TO' => 'Τόνγκα',
 			'TR' => 'Τουρκία',
 			'TT' => 'Τρινιντάντ και Τομπάγκο',
 			'TV' => 'Τουβαλού',
 			'TW' => 'Ταϊβάν',
 			'TZ' => 'Τανζανία',
 			'UA' => 'Ουκρανία',
 			'UG' => 'Ουγκάντα',
 			'UM' => 'Απομακρυσμένες Νησίδες ΗΠΑ',
 			'UN' => 'Ηνωμένα Έθνη',
 			'UN@alt=short' => 'ΟΗΕ',
 			'US' => 'Ηνωμένες Πολιτείες',
 			'US@alt=short' => 'ΗΠΑ',
 			'UY' => 'Ουρουγουάη',
 			'UZ' => 'Ουζμπεκιστάν',
 			'VA' => 'Βατικανό',
 			'VC' => 'Άγιος Βικέντιος και Γρεναδίνες',
 			'VE' => 'Βενεζουέλα',
 			'VG' => 'Βρετανικές Παρθένες Νήσοι',
 			'VI' => 'Αμερικανικές Παρθένες Νήσοι',
 			'VN' => 'Βιετνάμ',
 			'VU' => 'Βανουάτου',
 			'WF' => 'Γουάλις και Φουτούνα',
 			'WS' => 'Σαμόα',
 			'XK' => 'Κοσσυφοπέδιο',
 			'YE' => 'Υεμένη',
 			'YT' => 'Μαγιότ',
 			'ZA' => 'Νότια Αφρική',
 			'ZM' => 'Ζάμπια',
 			'ZW' => 'Ζιμπάμπουε',
 			'ZZ' => 'Άγνωστη περιοχή',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Παραδοσιακή γερμανική ορθογραφία',
 			'1994' => 'Τυποποιημένη ορθογραφία Ρεσιάν',
 			'1996' => 'Γερμανική ορθογραφία του 1996',
 			'1606NICT' => 'Νεότερα Μέσα Γαλλικά του 1606',
 			'1694ACAD' => 'Πρώιμα Σύγχρονα Γαλλικά',
 			'1959ACAD' => 'Ακαδημαϊκά',
 			'AREVELA' => 'Ανατολικά Αρμενικά',
 			'AREVMDA' => 'Δυτικά Αρμενικά',
 			'BAKU1926' => 'Ενοποιημένη τουρκική λατινική αλφάβητος',
 			'BISKE' => 'Διάλεκτος Σαν Τζιόρτζιο/Βίλα',
 			'BOONT' => 'Μπούντλινγκ',
 			'FONIPA' => 'Διεθνής φωνητική αλφάβητος',
 			'FONUPA' => 'Ουραλική φωνητική αλφάβητος',
 			'KKCOR' => 'Κοινή ορθογραφία',
 			'LIPAW' => 'Διάλεκτος Λιποβάζ της Ρεσιάν',
 			'MONOTON' => 'Μονοτονικό',
 			'NEDIS' => 'Διάλεκτος Νατισόνε',
 			'NJIVA' => 'Διάλεκτος Γκνιβά/Ντζιβά',
 			'OSOJS' => 'Διάλεκτος Οσεακό/Οσοτζάν',
 			'PINYIN' => 'Εκλατινισμένα Πινγίν',
 			'POLYTON' => 'Πολυτονικό',
 			'POSIX' => 'Υπολογιστής',
 			'REVISED' => 'Αναθεωρημένη ορθογραφία',
 			'ROZAJ' => 'Ρεσιάν',
 			'SAAHO' => 'Σάχο',
 			'SCOTLAND' => 'Σκοτσεζικά τυποποιημένα Αγγλικά',
 			'SCOUSE' => 'Σκουζ',
 			'SOLBA' => 'Διάλεκτος Στολβιτζά/Σολμπικά',
 			'TARASK' => 'Ταρασκιεβική ορθογραφία',
 			'UCCOR' => 'Ενωποιημένη ορθογραφία',
 			'UCRCOR' => 'Ενωποιημένη αναθεωρημένη ορθογραφία',
 			'VALENCIA' => 'Βαλενθιανά',
 			'WADEGILE' => 'Εκλατινισμένα Γουάντ-Γκιλς',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Ημερολόγιο',
 			'cf' => 'Μορφή νομίσματος',
 			'colalternate' => 'Ταξινόμηση με αγνόηση συμβόλων',
 			'colbackwards' => 'Ταξινόμηση με αντεστραμμένο τονισμό',
 			'colcasefirst' => 'Ταξινόμηση με κεφαλαίους/πεζούς χαρακτήρες',
 			'colcaselevel' => 'Ταξινόμηση με διάκριση χαρακτήρων',
 			'collation' => 'Σειρά ταξινόμησης',
 			'colnormalization' => 'Κανονικοποιημένη ταξινόμηση',
 			'colnumeric' => 'Αριθμητική ταξινόμηση',
 			'colstrength' => 'Ισχύς ταξινόμησης',
 			'currency' => 'Νόμισμα',
 			'hc' => 'Κύκλος ωρών (12 ή 24)',
 			'lb' => 'Στιλ αλλαγής γραμμών',
 			'ms' => 'Σύστημα μέτρησης',
 			'numbers' => 'Αριθμοί',
 			'timezone' => 'Ζώνη ώρας',
 			'va' => 'Παραλλαγή τοπικών ρυθμίσεων',
 			'x' => 'Προσωπική χρήση',

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
 				'buddhist' => q{Βουδιστικό ημερολόγιο},
 				'chinese' => q{Κινεζικό ημερολόγιο},
 				'coptic' => q{Κοπτικό ημερολόγιο},
 				'dangi' => q{Κορεατικό ημερολόγιο ντάνγκι},
 				'ethiopic' => q{Αιθιοπικό ημερολόγιο},
 				'ethiopic-amete-alem' => q{Αιθιοπικό ημερολόγιο Άμετ Άλεμ},
 				'gregorian' => q{Γρηγοριανό ημερολόγιο},
 				'hebrew' => q{Εβραϊκό ημερολόγιο},
 				'indian' => q{Ινδικό εθνικό ημερολόγιο},
 				'islamic' => q{Ισλαμικό ημερολόγιο},
 				'islamic-civil' => q{Ισλαμικό ημερολόγιο (σε μορφή πίνακα, αστικό εποχής)},
 				'islamic-rgsa' => q{Ισλαμικό ημερολόγιο (Σαουδική Αραβία, θέαση)},
 				'islamic-tbla' => q{Ισλαμικό ημερολόγιο (δομημένο, αστρονομική εποχή)},
 				'islamic-umalqura' => q{Ισλαμικό ημερολόγιο (Umm al-Qura)},
 				'iso8601' => q{Ημερολόγιο ISO-8601},
 				'japanese' => q{Ιαπωνικό ημερολόγιο},
 				'persian' => q{Περσικό ημερολόγιο},
 				'roc' => q{Ημερολόγιο της Δημοκρατίας της Κίνας},
 			},
 			'cf' => {
 				'account' => q{Λογιστική μορφή νομίσματος},
 				'standard' => q{Τυπική μορφή νομίσματος},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ταξινόμηση συμβόλων},
 				'shifted' => q{Ταξινόμηση με αγνόηση συμβόλων},
 			},
 			'colbackwards' => {
 				'no' => q{Κανονικά ταξινόμηση τόνων},
 				'yes' => q{Αντίστροφη ταξινόμηση τόνων},
 			},
 			'colcasefirst' => {
 				'lower' => q{Ταξινόμηση πεζών χαρακτήρων πρώτα},
 				'no' => q{Κανονική ταξινόμηση χαρακτήρων},
 				'upper' => q{Ταξινόμηση κεφαλαίων χαρακτήρων πρώτα},
 			},
 			'colcaselevel' => {
 				'no' => q{Ταξινόμηση με διάκριση χαρακτήρων},
 				'yes' => q{Ταξινόμηση χαρακτήρων διάκρισης},
 			},
 			'collation' => {
 				'big5han' => q{Σειρά ταξινόμησης Παραδοσιακών Κινεζικών - Big5},
 				'compat' => q{Προηγούμενη σειρά ταξινόμησης, για συμβατότητα},
 				'dictionary' => q{Σειρά ταξινόμησης ημερολογίου},
 				'ducet' => q{Προεπιλεγμένη σειρά ταξινόμησης Unicode},
 				'eor' => q{Ευρωπαϊκοί κανόνες ταξινόμησης},
 				'gb2312han' => q{Σειρά ταξινόμησης Απλουστευμένων Κινεζικών - GB2312},
 				'phonebook' => q{Σειρά ταξινόμησης τηλεφωνικού καταλόγου},
 				'phonetic' => q{Φωνητική σειρά ταξινόμησης},
 				'pinyin' => q{Σειρά ταξινόμησης Πινγίν},
 				'reformed' => q{Ανασχηματισμένη σειρά ταξινόμησης},
 				'search' => q{Αναζήτηση γενικού τύπου},
 				'searchjl' => q{Αναζήτηση κατά αρχικό σύμφωνο Χανγκούλ},
 				'standard' => q{Τυπική σειρά ταξινόμησης},
 				'stroke' => q{Σειρά ταξινόμησης κινήσεων},
 				'traditional' => q{Παραδοσιακή σειρά ταξινόμησης},
 				'unihan' => q{Σειρά ταξινόμησης ριζικής αρίθμησης},
 			},
 			'colnormalization' => {
 				'no' => q{Ταξινόμηση χωρίς κανονικοποίηση},
 				'yes' => q{Κανονικοποιημένη ταξινόμηση Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{Μεμονωμένη ταξινόμηση ψηφίων},
 				'yes' => q{Αριθμητική ταξινόμηση ψηφίων},
 			},
 			'colstrength' => {
 				'identical' => q{Ταξινόμηση όλων},
 				'primary' => q{Ταξινόμηση μόνο βασικών χαρακτήρων},
 				'quaternary' => q{Ταξινόμηση τόνων/χαρακτήρων διάκρισης/χαρακτήρων μεγάλου μεγέθους/χαρακτήρων Κάνα},
 				'secondary' => q{Ταξινόμηση τόνων},
 				'tertiary' => q{Ταξινόμηση τόνων/χαρακτήρων διάκρισης/χαρακτήρων μεγάλου μεγέθους},
 			},
 			'd0' => {
 				'fwidth' => q{Πλήρους πλάτους},
 				'hwidth' => q{Μισού πλάτους},
 				'npinyin' => q{Αριθμητικό},
 			},
 			'hc' => {
 				'h11' => q{12ωρο σύστημα (0–11)},
 				'h12' => q{12ωρο σύστημα (1–12)},
 				'h23' => q{24ωρο σύστημα (0–23)},
 				'h24' => q{24ωρο σύστημα (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Χαλαρό στιλ αλλαγής γραμμών},
 				'normal' => q{Κανονικό στιλ αλλαγής γραμμών},
 				'strict' => q{Στενό στιλ αλλαγής γραμμών},
 			},
 			'm0' => {
 				'bgn' => q{Μεταγραφή BGN ΗΠΑ},
 				'ungegn' => q{Μεταγραφή GEGN ΟΗΕ},
 			},
 			'ms' => {
 				'metric' => q{Μετρικό σύστημα},
 				'uksystem' => q{Αγγλοσαξονικό σύστημα μέτρησης},
 				'ussystem' => q{Αμερικανικό σύστημα μέτρησης},
 			},
 			'numbers' => {
 				'arab' => q{Αραβικο-ινδικά ψηφία},
 				'arabext' => q{Εκτεταμένα αραβικο-ινδικά ψηφία},
 				'armn' => q{Αρμενικά αριθμητικά},
 				'armnlow' => q{Πεζά αρμενικά αριθμητικά},
 				'beng' => q{Βεγγαλικά ψηφία},
 				'deva' => q{Ψηφία Ντεβαναγκάρι},
 				'ethi' => q{Αιθιοπικά αριθμητικά},
 				'finance' => q{Οικονομικά αριθμητικά},
 				'fullwide' => q{Ψηφία πλήρους πλάτους},
 				'geor' => q{Γεωργιανά αριθμητικά},
 				'grek' => q{Ελληνικά αριθμητικά},
 				'greklow' => q{Ελληνικά αριθμητικά πεζά},
 				'gujr' => q{Γκουτζαρατικά ψηφία},
 				'guru' => q{Ψηφία Γκουρμούκι},
 				'hanidec' => q{Κινεζικά δεκαδικά αριθμητικά},
 				'hans' => q{Απλοποιημένα κινεζικά αριθμητικά},
 				'hansfin' => q{Απλοποιημένα κινεζικά οικονομικά αριθμητικά},
 				'hant' => q{Παραδοσιακά κινεζικά αριθμητικά},
 				'hantfin' => q{Παραδοσιακά κινεζικά οικονομικά αριθμητικά},
 				'hebr' => q{Εβραϊκά αριθμητικά},
 				'jpan' => q{Ιαπωνικά αριθμητικά},
 				'jpanfin' => q{Ιαπωνικά οικονομικά αριθμητικά},
 				'khmr' => q{Ψηφία Χμερ},
 				'knda' => q{Ψηφία Κανάντα},
 				'laoo' => q{Λαοϊκά ψηφία},
 				'latn' => q{Ψηφία της Δύσης},
 				'mlym' => q{Μαλαγιαλαμικά ψηφία},
 				'mong' => q{Μογγολικά ψηφία},
 				'mymr' => q{Ψηφία Μιανμάρ},
 				'native' => q{Εγγενή ψηφία},
 				'orya' => q{Οριγικά ψηφία},
 				'roman' => q{Λατινικά αριθμητικά},
 				'romanlow' => q{Πεζά λατινικά αριθμητικά},
 				'taml' => q{Ταμιλικά αριθμητικά},
 				'tamldec' => q{Ταμιλικά ψηφία},
 				'telu' => q{Τελουγκουϊκά ψηφία},
 				'thai' => q{Ταϊλανδικά ψηφία},
 				'tibt' => q{Θιβετανικά ψηφία},
 				'traditional' => q{Παραδοσιακά αριθμητικά},
 				'vaii' => q{Ψηφία Βάι},
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
			'metric' => q{Μετρικό},
 			'UK' => q{Αγγλοσαξονικό},
 			'US' => q{Αμερικανικό},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Γλώσσα: {0}',
 			'script' => 'Γραφή: {0}',
 			'region' => 'Περιοχή: {0}',

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
			auxiliary => qr{[ἀ ἄ ἂ ἆ ἁ ἅ ἃ ἇ ὰ ᾶ ἐ ἔ ἒ ἑ ἕ ἓ ὲ ἠ ἤ ἢ ἦ ἡ ἥ ἣ ἧ ὴ ῆ ἰ ἴ ἲ ἶ ἱ ἵ ἳ ἷ ὶ ῖ ῒ ῗ ὄ ὂ ὃ ὸ ὐ ὔ ὒ ὖ ὑ ὕ ὓ ὗ ὺ ῦ ῢ ῧ ὤ ὢ ὦ ὥ ὣ ὧ ὼ ῶ]},
			index => ['Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ', 'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω'],
			main => qr{[α ά β γ δ ε έ ζ η ή θ ι ί ϊ ΐ κ λ μ ν ξ ο ό π ρ σ ς τ υ ύ ϋ ΰ φ χ ψ ω ώ]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! . … " « » ( ) \[ \] § @ * / \\ \&]},
		};
	},
EOT
: sub {
		return { index => ['Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ', 'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω'], };
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
	default		=> qq{;},
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
						'name' => q(σημεία ορίζοντα),
					},
					'acre' => {
						'name' => q(ακρ),
						'one' => q({0} ακρ),
						'other' => q({0} ακρ),
					},
					'acre-foot' => {
						'name' => q(ακρ-πόδια),
						'one' => q({0} ακρ-πόδι),
						'other' => q({0} ακρ-πόδια),
					},
					'ampere' => {
						'name' => q(αμπέρ),
						'one' => q({0} αμπέρ),
						'other' => q({0} αμπέρ),
					},
					'arc-minute' => {
						'name' => q(λεπτά του τόξου),
						'one' => q({0} λεπτό του τόξου),
						'other' => q({0} λεπτά του τόξου),
					},
					'arc-second' => {
						'name' => q(δευτερόλεπτα του τόξου),
						'one' => q({0} δευτερόλεπτο του τόξου),
						'other' => q({0} δευτερόλεπτα του τόξου),
					},
					'astronomical-unit' => {
						'name' => q(αστρονομικές μονάδες),
						'one' => q({0} αστρονομική μονάδα),
						'other' => q({0} αστρονομικές μονάδες),
					},
					'atmosphere' => {
						'name' => q(ατμόσφαιρες),
						'one' => q({0} ατμόσφαιρα),
						'other' => q({0} ατμόσφαιρες),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(θερμίδες),
						'one' => q({0} θερμίδα),
						'other' => q({0} θερμίδες),
					},
					'carat' => {
						'name' => q(καράτια),
						'one' => q({0} καράτι),
						'other' => q({0} καράτια),
					},
					'celsius' => {
						'name' => q(βαθμοί Κελσίου),
						'one' => q({0} βαθμός Κελσίου),
						'other' => q({0} βαθμοί Κελσίου),
					},
					'centiliter' => {
						'name' => q(εκατοστόλιτρα),
						'one' => q({0} εκατοστόλιτρο),
						'other' => q({0} εκατοστόλιτρα),
					},
					'centimeter' => {
						'name' => q(εκατοστά),
						'one' => q({0} εκατοστό),
						'other' => q({0} εκατοστά),
						'per' => q({0} ανά εκατοστό),
					},
					'century' => {
						'name' => q(αιώνες),
						'one' => q({0} αιώνας),
						'other' => q({0} αιώνες),
					},
					'coordinate' => {
						'east' => q({0} ανατολικά),
						'north' => q({0} βόρεια),
						'south' => q({0} νότια),
						'west' => q({0} δυτικά),
					},
					'cubic-centimeter' => {
						'name' => q(κυβικά εκατοστά),
						'one' => q({0} κυβικό εκατοστό),
						'other' => q({0} κυβικά εκατοστά),
						'per' => q({0} ανά κυβικό εκατοστό),
					},
					'cubic-foot' => {
						'name' => q(κυβικά πόδια),
						'one' => q({0} κυβικό πόδι),
						'other' => q({0} κυβικά πόδια),
					},
					'cubic-inch' => {
						'name' => q(κυβικές ίντσες),
						'one' => q({0} κυβική ίντσα),
						'other' => q({0} κυβικές ίντσες),
					},
					'cubic-kilometer' => {
						'name' => q(κυβικά χιλιόμετρα),
						'one' => q({0} κυβικό χιλιόμετρο),
						'other' => q({0} κυβικά χιλιόμετρα),
					},
					'cubic-meter' => {
						'name' => q(κυβικά μέτρα),
						'one' => q({0} κυβικό μέτρο),
						'other' => q({0} κυβικό μέτρο),
						'per' => q({0} ανά κυβικό μέτρο),
					},
					'cubic-mile' => {
						'name' => q(κυβικά μίλια),
						'one' => q({0} κυβικό μίλι),
						'other' => q({0} κυβικά μίλια),
					},
					'cubic-yard' => {
						'name' => q(κυβικές γιάρδες),
						'one' => q({0} κυβική γιάρδα),
						'other' => q({0} κυβικές γιάρδες),
					},
					'cup' => {
						'name' => q(κύπελλα),
						'one' => q({0} κύπελλο),
						'other' => q({0} κύπελλα),
					},
					'cup-metric' => {
						'name' => q(μετρικά κύπελλα),
						'one' => q({0} μετρικό κύπελλο),
						'other' => q({0} μετρικά κύπελλα),
					},
					'day' => {
						'name' => q(ημέρες),
						'one' => q({0} ημέρα),
						'other' => q({0} ημέρες),
						'per' => q({0} ανά ημέρα),
					},
					'deciliter' => {
						'name' => q(δεκατόλιτρα),
						'one' => q({0} δεκατόλιτρο),
						'other' => q({0} δεκατόλιτρα),
					},
					'decimeter' => {
						'name' => q(δεκατόμετρα),
						'one' => q({0} δεκατόμετρο),
						'other' => q({0} δεκατόμετρα),
					},
					'degree' => {
						'name' => q(μοίρες),
						'one' => q({0} μοίρα),
						'other' => q({0} μοίρες),
					},
					'fahrenheit' => {
						'name' => q(βαθμοί Φαρενάιτ),
						'one' => q({0} βαθμός Φαρενάιτ),
						'other' => q({0} βαθμοί Φαρενάιτ),
					},
					'fluid-ounce' => {
						'name' => q(ουγγιές όγκου),
						'one' => q({0} ουγγιά όγκου),
						'other' => q({0} ουγγιές όγκου),
					},
					'foodcalorie' => {
						'name' => q(Θερμίδες),
						'one' => q({0} θερμίδα),
						'other' => q({0} θερμίδες),
					},
					'foot' => {
						'name' => q(πόδια),
						'one' => q({0} πόδι),
						'other' => q({0} πόδια),
						'per' => q({0} ανά πόδι),
					},
					'g-force' => {
						'name' => q(δύναμη επιτάχυνσης),
						'one' => q({0} δύναμη επιτάχυνσης),
						'other' => q({0} δύναμη επιτάχυνσης),
					},
					'gallon' => {
						'name' => q(γαλόνια),
						'one' => q({0} γαλόνι),
						'other' => q({0} γαλόνια),
						'per' => q({0} ανά γαλόνι),
					},
					'gallon-imperial' => {
						'name' => q(αγγλοσαξονικά γαλόνια),
						'one' => q({0} αγγλοσαξονικό γαλόνι),
						'other' => q({0} αγγλοσαξονικά γαλόνια),
						'per' => q({0} ανά αγγλοσαξονικό γαλόνι),
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
						'name' => q(γιγαχέρτζ),
						'one' => q({0} γιγαχέρτζ),
						'other' => q({0} γιγαχέρτζ),
					},
					'gigawatt' => {
						'name' => q(γιγαβάτ),
						'one' => q({0} γιγαβάτ),
						'other' => q({0} γιγαβάτ),
					},
					'gram' => {
						'name' => q(γραμμάρια),
						'one' => q({0} γραμμάριο),
						'other' => q({0} γραμμάρια),
						'per' => q({0} ανά γραμμάριο),
					},
					'hectare' => {
						'name' => q(εκτάρια),
						'one' => q({0} εκτάριο),
						'other' => q({0} εκτάρια),
					},
					'hectoliter' => {
						'name' => q(εκτόλιτρα),
						'one' => q({0} εκτόλιτρο),
						'other' => q({0} εκτόλιτρα),
					},
					'hectopascal' => {
						'name' => q(εκτοπασκάλ),
						'one' => q({0} εκτοπασκάλ),
						'other' => q({0} εκτοπασκάλ),
					},
					'hertz' => {
						'name' => q(χερτζ),
						'one' => q({0} χερτζ),
						'other' => q({0} χερτζ),
					},
					'horsepower' => {
						'name' => q(ίπποι),
						'one' => q({0} ίππος),
						'other' => q({0} ίπποι),
					},
					'hour' => {
						'name' => q(ώρες),
						'one' => q({0} ώρα),
						'other' => q({0} ώρες),
						'per' => q({0} ανά ώρα),
					},
					'inch' => {
						'name' => q(ίντσες),
						'one' => q({0} ίντσα),
						'other' => q({0} ίντσες),
						'per' => q({0} ανά ίντσα),
					},
					'inch-hg' => {
						'name' => q(ίντσες στήλης υδραργύρου),
						'one' => q({0} ίντσα στήλης υδραργύρου),
						'other' => q({0} ίντσες στήλης υδραργύρου),
					},
					'joule' => {
						'name' => q(τζάουλ),
						'one' => q({0} τζάουλ),
						'other' => q({0} τζάουλ),
					},
					'karat' => {
						'name' => q(καράτια),
						'one' => q({0} καράτι),
						'other' => q({0} καράτια),
					},
					'kelvin' => {
						'name' => q(βαθμοί Κέλβιν),
						'one' => q({0} βαθμός Κέλβιν),
						'other' => q({0} βαθμοί Κέλβιν),
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
						'name' => q(χιλιοθερμίδες),
						'one' => q({0} χιλιοθερμίδα),
						'other' => q({0} χιλιοθερμίδες),
					},
					'kilogram' => {
						'name' => q(χιλιόγραμμα),
						'one' => q({0} χιλιόγραμμο),
						'other' => q({0} χιλιόγραμμα),
						'per' => q({0} ανά κιλό),
					},
					'kilohertz' => {
						'name' => q(κιλοχέρτζ),
						'one' => q({0} κιλοχέρτζ),
						'other' => q({0} κιλοχέρτζ),
					},
					'kilojoule' => {
						'name' => q(κιλοτζάουλ),
						'one' => q({0} κιλοτζάουλ),
						'other' => q({0} κιλοτζάουλ),
					},
					'kilometer' => {
						'name' => q(χιλιόμετρα),
						'one' => q({0} χιλιόμετρο),
						'other' => q({0} χιλιόμετρα),
						'per' => q({0} ανά χιλιόμετρο),
					},
					'kilometer-per-hour' => {
						'name' => q(χιλιόμετρα ανά ώρα),
						'one' => q({0} χιλιόμετρο ανά ώρα),
						'other' => q({0} χιλιόμετρα ανά ώρα),
					},
					'kilowatt' => {
						'name' => q(κιλοβάτ),
						'one' => q({0} κιλοβάτ),
						'other' => q({0} κιλοβάτ),
					},
					'kilowatt-hour' => {
						'name' => q(κιλοβατώρες),
						'one' => q({0} κιλοβατώρα),
						'other' => q({0} κιλοβατώρες),
					},
					'knot' => {
						'name' => q(κόμβος),
						'one' => q({0} κόμβος),
						'other' => q({0} κόμβοι),
					},
					'light-year' => {
						'name' => q(έτη φωτός),
						'one' => q({0} έτος φωτός),
						'other' => q({0} έτη φωτός),
					},
					'liter' => {
						'name' => q(λίτρα),
						'one' => q({0} λίτρο),
						'other' => q({0} λίτρα),
						'per' => q({0} ανά λίτρο),
					},
					'liter-per-100kilometers' => {
						'name' => q(λίτρα ανά 100 χιλιόμετρα),
						'one' => q({0} λίτρο ανά 100 χιλιόμετρα),
						'other' => q({0} λίτρα ανά 100 χιλιόμετρα),
					},
					'liter-per-kilometer' => {
						'name' => q(λίτρα ανά χιλιόμετρο),
						'one' => q({0} λίτρο ανά χιλιόμετρο),
						'other' => q({0} λίτρα ανά χιλιόμετρο),
					},
					'lux' => {
						'name' => q(λουξ),
						'one' => q({0} λουξ),
						'other' => q({0} λουξ),
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
						'name' => q(μεγαχέρτζ),
						'one' => q({0} μεγαχέρτζ),
						'other' => q({0} μεγαχέρτζ),
					},
					'megaliter' => {
						'name' => q(μεγαλίτρα),
						'one' => q({0} μεγαλίτρο),
						'other' => q({0} μεγαλίτρα),
					},
					'megawatt' => {
						'name' => q(μεγαβάτ),
						'one' => q({0} μεγαβάτ),
						'other' => q({0} μεγαβάτ),
					},
					'meter' => {
						'name' => q(μέτρα),
						'one' => q({0} μέτρο),
						'other' => q({0} μέτρα),
						'per' => q({0} ανά μέτρο),
					},
					'meter-per-second' => {
						'name' => q(μέτρα ανά δευτερόλεπτο),
						'one' => q({0} μέτρο ανά δευτερόλεπτο),
						'other' => q({0} μέτρα ανά δευτερόλεπτο),
					},
					'meter-per-second-squared' => {
						'name' => q(μέτρα ανά τετραγωνικό δευτερόλεπτο),
						'one' => q({0} μέτρο ανά τετραγωνικό δευτερόλεπτο),
						'other' => q({0} μέτρα ανά τετραγωνικό δευτερόλεπτο),
					},
					'metric-ton' => {
						'name' => q(μετρικοί τόνοι),
						'one' => q({0} μετρικός τόνος),
						'other' => q({0} μετρικοί τόνοι),
					},
					'microgram' => {
						'name' => q(μικρογραμμάρια),
						'one' => q({0} μικρογραμμάριο),
						'other' => q({0} μικρογραμμάρια),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} μικρόμετρο),
						'other' => q({0} μικρόμετρα),
					},
					'microsecond' => {
						'name' => q(μικροδευτερόλεπτα),
						'one' => q({0} μικροδευτερόλεπτο),
						'other' => q({0} μικροδευτερόλεπτα),
					},
					'mile' => {
						'name' => q(μίλια),
						'one' => q({0} μίλι),
						'other' => q({0} μίλια),
					},
					'mile-per-gallon' => {
						'name' => q(μίλια ανά γαλόνι),
						'one' => q({0} μίλι ανά γαλόνι),
						'other' => q({0} μίλια ανά γαλόνι),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(μίλια ανά αγγλοσαξονικό γαλόνι),
						'one' => q({0} μίλι ανά αγγλοσαξονικό γαλόνι),
						'other' => q({0} μίλια ανά αγγλοσαξονικό γαλόνι),
					},
					'mile-per-hour' => {
						'name' => q(μίλια ανά ώρα),
						'one' => q({0} μίλι ανά ώρα),
						'other' => q({0} μίλια ανά ώρα),
					},
					'mile-scandinavian' => {
						'name' => q(σκανδιναβικά μίλια),
						'one' => q({0} σκανδιναβικό μίλι),
						'other' => q({0} σκανδιναβικά μίλια),
					},
					'milliampere' => {
						'name' => q(μιλιαμπέρ),
						'one' => q({0} μιλιαμπέρ),
						'other' => q({0} μιλιαμπέρ),
					},
					'millibar' => {
						'name' => q(μιλιμπάρ),
						'one' => q({0} μιλιμπάρ),
						'other' => q({0} μιλιμπάρ),
					},
					'milligram' => {
						'name' => q(χιλιοστόγραμμα),
						'one' => q({0} χιλιοστόγραμμο),
						'other' => q({0} χιλιοστόγραμμα),
					},
					'milligram-per-deciliter' => {
						'name' => q(χιλιοστόγραμμα ανά δεκατόλιτρο),
						'one' => q({0} χιλιοστόγραμμο ανά δεκατόλιτρο),
						'other' => q({0} χιλιοστόγραμμα ανά δεκατόλιτρο),
					},
					'milliliter' => {
						'name' => q(χιλιοστόλιτρα),
						'one' => q({0} χιλιοστόλιτρο),
						'other' => q({0} χιλιοστόλιτρα),
					},
					'millimeter' => {
						'name' => q(χιλιοστόμετρα),
						'one' => q({0} χιλιοστόμετρο),
						'other' => q({0} χιλιοστόμετρα),
					},
					'millimeter-of-mercury' => {
						'name' => q(χιλιοστόμετρα στήλης υδραργύρου),
						'one' => q({0} χιλιοστόμετρα στήλης υδραργύρου),
						'other' => q({0} χιλιοστόμετρα στήλης υδραργύρου),
					},
					'millimole-per-liter' => {
						'name' => q(χιλιοστογραμμομόριο ανά λίτρο),
						'one' => q({0} χιλιοστογραμμομόριο ανά λίτρο),
						'other' => q({0} χιλιοστογραμμομόρια ανά λίτρο),
					},
					'millisecond' => {
						'name' => q(χιλιοστά του δευτερολέπτου),
						'one' => q({0} χιλιοστό του δευτερολέπτου),
						'other' => q({0} χιλιοστά του δευτερολέπτου),
					},
					'milliwatt' => {
						'name' => q(μιλιβάτ),
						'one' => q({0} μιλιβάτ),
						'other' => q({0} μιλιβάτ),
					},
					'minute' => {
						'name' => q(λεπτά),
						'one' => q({0} λεπτό),
						'other' => q({0} λεπτά),
						'per' => q({0} ανά λεπτό),
					},
					'month' => {
						'name' => q(μήνες),
						'one' => q({0} μήνας),
						'other' => q({0} μήνες),
						'per' => q({0} ανά μήνα),
					},
					'nanometer' => {
						'name' => q(νανόμετρα),
						'one' => q({0} νανόμετρο),
						'other' => q({0} νανόμετρα),
					},
					'nanosecond' => {
						'name' => q(νανοδευτερόλεπτα),
						'one' => q({0} νανοδευτερόλεπτο),
						'other' => q({0} νανοδευτερόλεπτα),
					},
					'nautical-mile' => {
						'name' => q(ναυτικά μίλια),
						'one' => q({0} ναυτικό μίλι),
						'other' => q({0} ναυτικά μίλια),
					},
					'ohm' => {
						'name' => q(ωμ),
						'one' => q({0} ωμ),
						'other' => q({0} ωμ),
					},
					'ounce' => {
						'name' => q(ουγγιές),
						'one' => q({0} ουγγιά),
						'other' => q({0} ουγγιές),
						'per' => q({0} ανά ουγγιά),
					},
					'ounce-troy' => {
						'name' => q(ευγενείς ουγγιές),
						'one' => q({0} ευγενής ουγγιά),
						'other' => q({0} ευγενείς ουγγιές),
					},
					'parsec' => {
						'name' => q(παρσέκ),
						'one' => q({0} παρσέκ),
						'other' => q({0} παρσέκ),
					},
					'part-per-million' => {
						'name' => q(μέρη ανά εκατομμύριο),
						'one' => q({0} μέρος ανά εκατομμύριο),
						'other' => q({0} μέρη ανά εκατομμύριο),
					},
					'per' => {
						'1' => q({0} ανά {1}),
					},
					'percent' => {
						'name' => q(τοις εκατό),
						'one' => q({0} τοις εκατό),
						'other' => q({0} τοις εκατό),
					},
					'permille' => {
						'name' => q(τοις χιλίοις),
						'one' => q({0} τοις χιλίοις),
						'other' => q({0} τοις χιλίοις),
					},
					'petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					'picometer' => {
						'name' => q(πικόμετρα),
						'one' => q({0} πικόμετρο),
						'other' => q({0} πικόμετρα),
					},
					'pint' => {
						'name' => q(πίντες),
						'one' => q({0} πίντα),
						'other' => q({0} πίντες),
					},
					'pint-metric' => {
						'name' => q(μετρικές πίντες),
						'one' => q({0} μετρική πίντα),
						'other' => q({0} μετρικές πίντες),
					},
					'point' => {
						'name' => q(στιγμή),
						'one' => q({0} στιγμή),
						'other' => q({0} στιγμές),
					},
					'pound' => {
						'name' => q(λίβρες),
						'one' => q({0} λίβρα),
						'other' => q({0} λίβρες),
						'per' => q({0} ανά λίβρα),
					},
					'pound-per-square-inch' => {
						'name' => q(λίβρα ανά τετραγωνική ίντσα),
						'one' => q({0} λίβρα ανά τετραγωνική ίντσα),
						'other' => q({0} λίβρες ανά τετραγωνική ίντσα),
					},
					'quart' => {
						'name' => q(τέταρτα του γαλονιού),
						'one' => q({0} τέταρτο του γαλονιού),
						'other' => q({0} τέταρτα του γαλονιού),
					},
					'radian' => {
						'name' => q(ακτίνια),
						'one' => q({0} ακτίνιο),
						'other' => q({0} ακτίνιο),
					},
					'revolution' => {
						'name' => q(στροφή),
						'one' => q({0} στροφή),
						'other' => q({0} στροφές),
					},
					'second' => {
						'name' => q(δευτερόλεπτα),
						'one' => q({0} δευτερόλεπτο),
						'other' => q({0} δευτερόλεπτα),
						'per' => q({0} ανά δευτερόλεπτο),
					},
					'square-centimeter' => {
						'name' => q(τετραγωνικά εκατοστά),
						'one' => q({0} τετραγωνικό εκατοστό),
						'other' => q({0} τετραγωνικά εκατοστά),
						'per' => q({0}/τετραγωνικό εκατοστό),
					},
					'square-foot' => {
						'name' => q(τετραγωνικά πόδια),
						'one' => q({0} τετραγωνικό πόδι),
						'other' => q({0} τετραγωνικά πόδια),
					},
					'square-inch' => {
						'name' => q(τετραγωνικές ίντσες),
						'one' => q({0} τετραγωνική ίντσα),
						'other' => q({0} τετραγωνικές ίντσες),
						'per' => q({0} ανά τετραγωνική ίντσα),
					},
					'square-kilometer' => {
						'name' => q(τετραγωνικά χιλιόμετρα),
						'one' => q({0} τετραγωνικό χιλιόμετρο),
						'other' => q({0} τετραγωνικά χιλιόμετρα),
						'per' => q({0}/τετραγωνικό χιλιόμετρο),
					},
					'square-meter' => {
						'name' => q(τετραγωνικά μέτρα),
						'one' => q({0} τετραγωνικό μέτρο),
						'other' => q({0} τετραγωνικά μέτρα),
						'per' => q({0}/τετραγωνικό μέτρο),
					},
					'square-mile' => {
						'name' => q(τετραγωνικά μίλια),
						'one' => q({0} τετραγωνικό μίλι),
						'other' => q({0} τετραγωνικά μίλια),
						'per' => q({0}/τετραγωνικό μίλι),
					},
					'square-yard' => {
						'name' => q(τετραγωνικές γιάρδες),
						'one' => q({0} τετραγωνική γιάρδα),
						'other' => q({0} τετραγωνικές γιάρδες),
					},
					'tablespoon' => {
						'name' => q(κουταλιές της σούπας),
						'one' => q({0} κουταλιά της σούπας),
						'other' => q({0} κουταλιές της σούπας),
					},
					'teaspoon' => {
						'name' => q(κουταλιές του γλυκού),
						'one' => q({0} κουταλιά του γλυκού),
						'other' => q({0} κουταλιές του γλυκού),
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
						'name' => q(τόνοι),
						'one' => q({0} τόνος),
						'other' => q({0} τόνοι),
					},
					'volt' => {
						'name' => q(βολτ),
						'one' => q({0} βολτ),
						'other' => q({0} βολτ),
					},
					'watt' => {
						'name' => q(βατ),
						'one' => q({0} βατ),
						'other' => q({0} βατ),
					},
					'week' => {
						'name' => q(εβδομάδες),
						'one' => q({0} εβδομάδα),
						'other' => q({0} εβδομάδες),
						'per' => q({0} ανά εβδομάδα),
					},
					'yard' => {
						'name' => q(γιάρδες),
						'one' => q({0} γιάρδα),
						'other' => q({0} γιάρδες),
					},
					'year' => {
						'name' => q(έτη),
						'one' => q({0} έτος),
						'other' => q({0} έτη),
						'per' => q({0} ανά έτος),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(σημεία),
					},
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(εκ.),
						'one' => q({0} εκ.),
						'other' => q({0} εκ.),
					},
					'coordinate' => {
						'east' => q({0} Α),
						'north' => q({0} Β),
						'south' => q({0} Ν),
						'west' => q({0} Δ),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(ημέρα),
						'one' => q({0} η),
						'other' => q({0} η),
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
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gram' => {
						'name' => q(γρ.),
						'one' => q({0} γρ.),
						'other' => q({0} γρ.),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(ώρα),
						'one' => q({0} ώ),
						'other' => q({0} ώ),
					},
					'inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(χλμ.),
						'one' => q({0} χλμ.),
						'other' => q({0} χλμ.),
					},
					'kilometer-per-hour' => {
						'name' => q(χλμ/ώ.),
						'one' => q({0} χλμ/ώ.),
						'other' => q({0} χλμ/ώ.),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'light-year' => {
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(λίτρο),
						'one' => q({0} λ.),
						'other' => q({0} λ.),
					},
					'liter-per-100kilometers' => {
						'name' => q(λ/100 χλμ),
						'one' => q({0} λ/100 χλμ),
						'other' => q({0} λ/100 χλμ),
					},
					'meter' => {
						'name' => q(μέτρο),
						'one' => q({0} μ.),
						'other' => q({0} μ.),
					},
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'millimeter' => {
						'name' => q(χλστ.),
						'one' => q({0} χλστ.),
						'other' => q({0} χλστ.),
					},
					'millisecond' => {
						'name' => q(χιλ. δευτ.),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(λεπ.),
						'one' => q({0} λ),
						'other' => q({0} λ),
					},
					'month' => {
						'name' => q(μήνας),
						'one' => q({0} μ),
						'other' => q({0} μ),
					},
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
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
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					'second' => {
						'name' => q(δευτ.),
						'one' => q({0} δ),
						'other' => q({0} δ),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(εβδ.),
						'one' => q({0} ε),
						'other' => q({0} ε),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(έτ.),
						'one' => q({0} έ),
						'other' => q({0} έ),
					},
				},
				'short' => {
					'' => {
						'name' => q(σημείο),
					},
					'acre' => {
						'name' => q(ακρ),
						'one' => q({0} ακρ),
						'other' => q({0} ακρ),
					},
					'acre-foot' => {
						'name' => q(ακρ πόδια),
						'one' => q({0} ακρ πδ),
						'other' => q({0} ακρ πδ),
					},
					'ampere' => {
						'name' => q(αμπέρ),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(λεπτά του τόξου),
						'one' => q({0} λεπ. τόξου),
						'other' => q({0} λεπ. τόξου),
					},
					'arc-second' => {
						'name' => q(arcsec),
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					'astronomical-unit' => {
						'name' => q(α.μ.),
						'one' => q({0} α.μ.),
						'other' => q({0} α.μ.),
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
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(θερμ.),
						'one' => q({0} θερμ.),
						'other' => q({0} θερμ.),
					},
					'carat' => {
						'name' => q(καράτια),
						'one' => q({0} κρτ),
						'other' => q({0} κρτ),
					},
					'celsius' => {
						'name' => q(βθμ C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(εκ.),
						'one' => q({0} εκ.),
						'other' => q({0} εκ.),
						'per' => q({0}/εκ.),
					},
					'century' => {
						'name' => q(αιών.),
						'one' => q({0} αιών.),
						'other' => q({0} αιών.),
					},
					'coordinate' => {
						'east' => q({0} Α),
						'north' => q({0} Β),
						'south' => q({0} Ν),
						'west' => q({0} Δ),
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
						'name' => q(κυβ. γιάρδες),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(κύπ.),
						'one' => q({0} κύπ.),
						'other' => q({0} κύπ.),
					},
					'cup-metric' => {
						'name' => q(μετρ. κύπελλο),
						'one' => q({0} μετρ. κύπελλο),
						'other' => q({0} μετρ. κύπελλα),
					},
					'day' => {
						'name' => q(ημέρες),
						'one' => q({0} ημέρα),
						'other' => q({0} ημέρες),
						'per' => q({0}/ημ.),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(δεκ.),
						'one' => q({0} δεκ.),
						'other' => q({0} δεκ.),
					},
					'degree' => {
						'name' => q(μοίρες),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(βθμ F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(θερμ.),
						'one' => q({0} θερμ.),
						'other' => q({0} θερμ.),
					},
					'foot' => {
						'name' => q(πόδια),
						'one' => q({0} πδ),
						'other' => q({0} πδ),
						'per' => q({0}/πδ),
					},
					'g-force' => {
						'name' => q(δύν. επιτάχ.),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(γαλ.),
						'one' => q({0} γαλ.),
						'other' => q({0} γαλ.),
						'per' => q({0}/γαλ.),
					},
					'gallon-imperial' => {
						'name' => q(αγγλοσαξ. γαλόνια),
						'one' => q({0} αγγλοσαξ. γαλόνι),
						'other' => q({0} αγγλοσαξ. γαλόνια),
						'per' => q({0}/αγγλοσαξ. γαλόνι),
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
						'name' => q(γιγαχέρτζ),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(γιγαβάτ),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(γραμμ.),
						'one' => q({0} γρ.),
						'other' => q({0} γρ.),
						'per' => q({0}/γρ.),
					},
					'hectare' => {
						'name' => q(εκτ.),
						'one' => q({0} εκτ.),
						'other' => q({0} εκτ.),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(χερτζ),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(ίπποι),
						'one' => q({0} ίπ.),
						'other' => q({0} ίπ.),
					},
					'hour' => {
						'name' => q(ώρες),
						'one' => q({0} ώρα),
						'other' => q({0} ώρ.),
						'per' => q({0}/ώ.),
					},
					'inch' => {
						'name' => q(ίντσες),
						'one' => q({0} ίν.),
						'other' => q({0} ίν.),
						'per' => q({0}/ίν.),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(τζάουλ),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(κρτ),
						'one' => q({0} κρτ),
						'other' => q({0} κρτ),
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
						'one' => q({0} κιλό),
						'other' => q({0} κιλά),
						'per' => q({0}/κιλό),
					},
					'kilohertz' => {
						'name' => q(κιλοχέρτζ),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(κιλοτζάουλ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(χλμ.),
						'one' => q({0} χλμ.),
						'other' => q({0} χλμ.),
						'per' => q({0}/χλμ.),
					},
					'kilometer-per-hour' => {
						'name' => q(χλμ./ώρα),
						'one' => q({0} χλμ./ώρα),
						'other' => q({0} χλμ./ώρα),
					},
					'kilowatt' => {
						'name' => q(κιλοβάτ),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(κιλοβάτ/ώρα),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(κμβ),
						'one' => q({0} κμβ),
						'other' => q({0} κμβ),
					},
					'light-year' => {
						'name' => q(έτη φωτός),
						'one' => q({0} έ.φ.),
						'other' => q({0} έ.φ.),
					},
					'liter' => {
						'name' => q(λίτρα),
						'one' => q({0} λίτ.),
						'other' => q({0} λίτ.),
						'per' => q({0}/λ.),
					},
					'liter-per-100kilometers' => {
						'name' => q(λ./100 χλμ.),
						'one' => q({0} λ./100 χλμ.),
						'other' => q({0} λ./100 χλμ.),
					},
					'liter-per-kilometer' => {
						'name' => q(λίτρα/χλμ.),
						'one' => q({0} λίτρο/χλμ),
						'other' => q({0} λίτρα/χλμ),
					},
					'lux' => {
						'name' => q(λουξ),
						'one' => q({0} λουξ),
						'other' => q({0} λουξ),
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
						'name' => q(μεγαχέρτζ),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(μεγαβάτ),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(μέτρα),
						'one' => q({0} μ.),
						'other' => q({0} μ.),
						'per' => q({0}/μ.),
					},
					'meter-per-second' => {
						'name' => q(μέτρα/δευτ.),
						'one' => q({0} μέτρο/δευτ.),
						'other' => q({0} μέτρα/δευτ.),
					},
					'meter-per-second-squared' => {
						'name' => q(μέτρα/τετρ. δευτ.),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(μ.τ.),
						'one' => q({0} μ.τ.),
						'other' => q({0} μ.τ.),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(μικρόμετρα),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μικροδεύτερα),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(μίλια),
						'one' => q({0} μίλ.),
						'other' => q({0} μίλ.),
					},
					'mile-per-gallon' => {
						'name' => q(μίλια/γαλόνι),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(μίλια/αγγλ. γαλόνι),
						'one' => q({0} μίλι/αγγλ. γαλόνι),
						'other' => q({0} μίλια/αγγλ. γαλόνι),
					},
					'mile-per-hour' => {
						'name' => q(μίλια/ώρα),
						'one' => q({0} μίλι/ώρα),
						'other' => q({0} μίλια/ώρα),
					},
					'mile-scandinavian' => {
						'name' => q(σκανδ. μίλια),
						'one' => q({0} σκανδ. μίλι),
						'other' => q({0} σκανδ. μίλια),
					},
					'milliampere' => {
						'name' => q(μιλιαμπέρ),
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
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(χιλιοστόμ.),
						'one' => q({0} χλστ.),
						'other' => q({0} χλστ.),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(χιλιοστά δευτ.),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(μιλιβάτ),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(λεπ.),
						'one' => q({0} λεπ.),
						'other' => q({0} λεπ.),
						'per' => q({0}/λ.),
					},
					'month' => {
						'name' => q(μήνες),
						'one' => q({0} μήν.),
						'other' => q({0} μήν.),
						'per' => q({0}/μ.),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(νανοδεύτερα),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(ν.μ.),
						'one' => q({0} ν.μ.),
						'other' => q({0} ν.μ.),
					},
					'ohm' => {
						'name' => q(ωμ),
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
						'name' => q(ευγενής ουγγιά),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(παρσέκ),
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
						'name' => q(τοις εκατό),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(τοις χιλίοις),
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
						'name' => q(πίντες),
						'one' => q({0} πντ),
						'other' => q({0} πντ),
					},
					'pint-metric' => {
						'name' => q(μετρικές πίντες),
						'one' => q({0} μετρ. πίντα),
						'other' => q({0} μετρ. πίντες),
					},
					'point' => {
						'name' => q(στιγμές),
						'one' => q({0} στ.),
						'other' => q({0} στ.),
					},
					'pound' => {
						'name' => q(λίβρες),
						'one' => q({0} λβ),
						'other' => q({0} λβ),
						'per' => q({0}/λβ),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(τέταρτα γαλονιού),
						'one' => q({0} τέτ. γαλ.),
						'other' => q({0} τέτ. γαλ.),
					},
					'radian' => {
						'name' => q(ακτν),
						'one' => q({0} ακτν),
						'other' => q({0} ακτν),
					},
					'revolution' => {
						'name' => q(στρφ),
						'one' => q({0} στρφ),
						'other' => q({0} στρφ),
					},
					'second' => {
						'name' => q(δευτ.),
						'one' => q({0} δευτ.),
						'other' => q({0} δευτ.),
						'per' => q({0}/δευτ.),
					},
					'square-centimeter' => {
						'name' => q(τ.εκ.),
						'one' => q({0} τ.εκ.),
						'other' => q({0} τ.εκ.),
						'per' => q({0}/τ.εκ.),
					},
					'square-foot' => {
						'name' => q(τετρ. πόδια),
						'one' => q({0} τ.πδ),
						'other' => q({0} τ.πδ),
					},
					'square-inch' => {
						'name' => q(τετρ. ίντσες),
						'one' => q({0} τ. ίντσα),
						'other' => q({0} τ. ίντσες),
						'per' => q({0}/τ. ίντσα),
					},
					'square-kilometer' => {
						'name' => q(τ.χλμ.),
						'one' => q({0} τ.χλμ.),
						'other' => q({0} τ.χλμ.),
						'per' => q({0}/τ.χλμ.),
					},
					'square-meter' => {
						'name' => q(τ. μέτρα),
						'one' => q({0} τ.μ.),
						'other' => q({0} τ.μ.),
						'per' => q({0}/τ.μ.),
					},
					'square-mile' => {
						'name' => q(τετρ. μίλια),
						'one' => q({0} τ.μίλι),
						'other' => q({0} τ.μίλια),
						'per' => q({0}/τ.μίλι),
					},
					'square-yard' => {
						'name' => q(τετρ. γιάρδες),
						'one' => q({0} τ.γρδ),
						'other' => q({0} τ.γρδ),
					},
					'tablespoon' => {
						'name' => q(κ.σ.),
						'one' => q({0} κ.σ.),
						'other' => q({0} κ.σ.),
					},
					'teaspoon' => {
						'name' => q(κ.γ.),
						'one' => q({0} κ.γ.),
						'other' => q({0} κ.γ.),
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
						'name' => q(τόνοι),
						'one' => q({0} τ.),
						'other' => q({0} τ.),
					},
					'volt' => {
						'name' => q(βολτ),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(βατ),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(εβδομάδες),
						'one' => q({0} εβδ.),
						'other' => q({0} εβδ.),
						'per' => q({0}/εβδ.),
					},
					'yard' => {
						'name' => q(γιάρδες),
						'one' => q({0} γρδ),
						'other' => q({0} γρδ),
					},
					'year' => {
						'name' => q(έτη),
						'one' => q({0} έτ.),
						'other' => q({0} έτ.),
						'per' => q({0}/έτ.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ναι|ν|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:όχι|ό|no|n)$' }
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

has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'grek',
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
			'exponential' => q(e),
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
					'one' => '0 χιλ'.'',
					'other' => '0 χιλ'.'',
				},
				'10000' => {
					'one' => '00 χιλ'.'',
					'other' => '00 χιλ'.'',
				},
				'100000' => {
					'one' => '000 χιλ'.'',
					'other' => '000 χιλ'.'',
				},
				'1000000' => {
					'one' => '0 εκ'.'',
					'other' => '0 εκ'.'',
				},
				'10000000' => {
					'one' => '00 εκ'.'',
					'other' => '00 εκ'.'',
				},
				'100000000' => {
					'one' => '000 εκ'.'',
					'other' => '000 εκ'.'',
				},
				'1000000000' => {
					'one' => '0 δισ'.'',
					'other' => '0 δισ'.'',
				},
				'10000000000' => {
					'one' => '00 δισ'.'',
					'other' => '00 δισ'.'',
				},
				'100000000000' => {
					'one' => '000 δισ'.'',
					'other' => '000 δισ'.'',
				},
				'1000000000000' => {
					'one' => '0 τρισ'.'',
					'other' => '0 τρισ'.'',
				},
				'10000000000000' => {
					'one' => '00 τρισ'.'',
					'other' => '00 τρισ'.'',
				},
				'100000000000000' => {
					'one' => '000 τρισ'.'',
					'other' => '000 τρισ'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 χιλιάδα',
					'other' => '0 χιλιάδες',
				},
				'10000' => {
					'one' => '00 χιλιάδες',
					'other' => '00 χιλιάδες',
				},
				'100000' => {
					'one' => '000 χιλιάδες',
					'other' => '000 χιλιάδες',
				},
				'1000000' => {
					'one' => '0 εκατομμύριο',
					'other' => '0 εκατομμύρια',
				},
				'10000000' => {
					'one' => '00 εκατομμύρια',
					'other' => '00 εκατομμύρια',
				},
				'100000000' => {
					'one' => '000 εκατομμύρια',
					'other' => '000 εκατομμύρια',
				},
				'1000000000' => {
					'one' => '0 δισεκατομμύριο',
					'other' => '0 δισεκατομμύρια',
				},
				'10000000000' => {
					'one' => '00 δισεκατομμύρια',
					'other' => '00 δισεκατομμύρια',
				},
				'100000000000' => {
					'one' => '000 δισεκατομμύρια',
					'other' => '000 δισεκατομμύρια',
				},
				'1000000000000' => {
					'one' => '0 τρισεκατομμύριο',
					'other' => '0 τρισεκατομμύρια',
				},
				'10000000000000' => {
					'one' => '00 τρισεκατομμύρια',
					'other' => '00 τρισεκατομμύρια',
				},
				'100000000000000' => {
					'one' => '000 τρισεκατομμύρια',
					'other' => '000 τρισεκατομμύρια',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 χιλ'.'',
					'other' => '0 χιλ'.'',
				},
				'10000' => {
					'one' => '00 χιλ'.'',
					'other' => '00 χιλ'.'',
				},
				'100000' => {
					'one' => '000 χιλ'.'',
					'other' => '000 χιλ'.'',
				},
				'1000000' => {
					'one' => '0 εκ'.'',
					'other' => '0 εκ'.'',
				},
				'10000000' => {
					'one' => '00 εκ'.'',
					'other' => '00 εκ'.'',
				},
				'100000000' => {
					'one' => '000 εκ'.'',
					'other' => '000 εκ'.'',
				},
				'1000000000' => {
					'one' => '0 δισ'.'',
					'other' => '0 δισ'.'',
				},
				'10000000000' => {
					'one' => '00 δισ'.'',
					'other' => '00 δισ'.'',
				},
				'100000000000' => {
					'one' => '000 δισ'.'',
					'other' => '000 δισ'.'',
				},
				'1000000000000' => {
					'one' => '0 τρισ'.'',
					'other' => '0 τρισ'.'',
				},
				'10000000000000' => {
					'one' => '00 τρισ'.'',
					'other' => '00 τρισ'.'',
				},
				'100000000000000' => {
					'one' => '000 τρισ'.'',
					'other' => '000 τρισ'.'',
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
				'currency' => q(Πεσέτα Ανδόρας),
				'one' => q(πεσέτα Ανδόρας),
				'other' => q(πεσέτες Ανδόρας),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Ντιράμ Ηνωμένων Αραβικών Εμιράτων),
				'one' => q(ντιράμ Ηνωμένων Αραβικών Εμιράτων),
				'other' => q(ντιράμ Ηνωμένων Αραβικών Εμιράτων),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Αφγανί Αφγανιστάν \(1927–2002\)),
				'one' => q(αφγάνι Αφγανιστάν \(AFA\)),
				'other' => q(αφγάνι Αφγανιστάν \(AFA\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Αφγάνι Αφγανιστάν),
				'one' => q(αφγάνι Αφγανιστάν),
				'other' => q(αφγάνια Αφγανιστάν),
			},
		},
		'ALK' => {
			display_name => {
				'one' => q(Παλαιό λεκ Αλβανίας),
				'other' => q(Παλαιά λεκ Αλβανίας),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Λεκ Αλβανίας),
				'one' => q(λεκ Αλβανίας),
				'other' => q(λεκ Αλβανίας),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Ντραμ Αρμενίας),
				'one' => q(ντραμ Αρμενίας),
				'other' => q(ντραμ Αρμενίας),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Γκίλντα Ολλανδικών Αντιλλών),
				'one' => q(γκίλντα Ολλανδικών Αντιλλών),
				'other' => q(γκίλντες Ολλανδικών Αντιλλών),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Κουάνζα Ανγκόλας),
				'one' => q(κουάνζα Ανγκόλας),
				'other' => q(κουάνζα Ανγκόλας),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Κουάνζα Ανγκόλας \(1977–1990\)),
				'one' => q(κουάνζα Ανγκόλας \(AOK\)),
				'other' => q(κουάνζα Ανγκόλας \(AOK\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Νέα Κουάνζα Ανγκόλας \(1990–2000\)),
				'one' => q(νέο κουάνζα Ανγκόλας \(1990–2000\)),
				'other' => q(νέα κουάνζα Ανγκόλας \(1990–2000\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Ωστράλ Αργετινής),
				'one' => q(αουστράλ Αργεντινής),
				'other' => q(αουστράλ Αργεντινής),
			},
		},
		'ARL' => {
			display_name => {
				'one' => q(Πέσο λέι Αργετινής),
				'other' => q(Πέσο λέι Αργετινής),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Πέσο Αργεντινής \(1983–1985\)),
				'one' => q(πέσο Αργεντινής \(ARP\)),
				'other' => q(πέσο Αργεντινής \(ARP\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Πέσο Αργεντινής),
				'one' => q(πέσο Αργεντινής),
				'other' => q(πέσο Αργεντινής),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Σελίνι Αυστρίας),
				'one' => q(σελίνι Αυστρίας),
				'other' => q(σελίνια Αυστρίας),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Δολάριο Αυστραλίας),
				'one' => q(δολάριο Αυστραλίας),
				'other' => q(δολάρια Αυστραλίας),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Φλορίνι Αρούμπας),
				'one' => q(φλορίνι Αρούμπας),
				'other' => q(φλορίνια Αρούμπας),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Μανάτ Αζερμπαϊτζάν \(1993–2006\)),
				'one' => q(μανάτ Αζερμπαϊτζάν \(1993–2006\)),
				'other' => q(μανάτ Αζερμπαϊτζάν \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Μανάτ Αζερμπαϊτζάν),
				'one' => q(μανάτ Αζερμπαϊτζάν),
				'other' => q(μανάτ Αζερμπαϊτζάν),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Δηνάριο Βοσνίας-Ερζεγοβίνης),
				'one' => q(δηνάριο Βοσνίας-Ερζεγοβίνης),
				'other' => q(δηνάρια Βοσνίας-Ερζεγοβίνης),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Μετατρέψιμο Μάρκο Βοσνίας-Ερζεγοβίνης),
				'one' => q(μετατρέψιμο μάρκο Βοσνίας-Ερζεγοβίνης),
				'other' => q(μετατρέψιμα μάρκα Βοσνίας-Ερζεγοβίνης),
			},
		},
		'BAN' => {
			display_name => {
				'one' => q(Νέο δινάριο Βοσνίας-Ερζεγοβίνης),
				'other' => q(Νέα δινάρια Βοσνίας-Ερζεγοβίνης),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Δολάριο Μπαρμπέιντος),
				'one' => q(δολάριο Μπαρμπέιντος),
				'other' => q(δολάρια Μπαρμπέιντος),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Τάκα Μπαγκλαντές),
				'one' => q(τάκα Μπαγκλαντές),
				'other' => q(τάκα Μπαγκλαντές),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Φράγκο Βελγίου \(μετατρέψιμο\)),
				'one' => q(φράγκο Βελγίου \(μετατρέψιμο\)),
				'other' => q(φράγκα Βελγίου \(μετατρέψιμα\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Φράγκο Βελγίου),
				'one' => q(φράγκο Βελγίου),
				'other' => q(φράγκα Βελγίου),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Φράγκο Βελγίου \(οικονομικό\)),
				'one' => q(φράγκο Βελγίου \(οικονομικό\)),
				'other' => q(φράγκα Βελγίου \(οικονομικό\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Μεταλλικό Λεβ Βουλγαρίας),
				'one' => q(μεταλλικό λεβ Βουλγαρίας),
				'other' => q(μεταλλικά λεβ Βουλγαρίας),
			},
		},
		'BGM' => {
			display_name => {
				'one' => q(Σοσιαλιστικό λεβ Βουλγαρίας),
				'other' => q(Σοσιαλιστικά λεβ Βουλγαρίας),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Λεβ Βουλγαρίας),
				'one' => q(λεβ Βουλγαρίας),
				'other' => q(λεβ Βουλγαρίας),
			},
		},
		'BGO' => {
			display_name => {
				'one' => q(Παλαιό λεβ Βουλγαρίας),
				'other' => q(Παλαιά λεβ Βουλγαρίας),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Δηνάριο Μπαχρέιν),
				'one' => q(δηνάριο Μπαχρέιν),
				'other' => q(δηνάρια Μπαχρέιν),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Φράγκο Μπουρούντι),
				'one' => q(φράγκο Μπουρούντι),
				'other' => q(φράγκα Μπουρούντι),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Δολάριο Βερμούδων),
				'one' => q(δολάριο Βερμούδων),
				'other' => q(δολάρια Βερμούδων),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Δολάριο Μπρουνέι),
				'one' => q(δολάριο Μπρουνέι),
				'other' => q(δολάρια Μπρουνέι),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Μπολιβιάνο Βολιβίας),
				'one' => q(μπολιβιάνο Βολιβίας),
				'other' => q(μπολιβιάνο Βολιβίας),
			},
		},
		'BOL' => {
			display_name => {
				'one' => q(Παλαιό βολιβιάνο Βολιβίας),
				'other' => q(Παλαιά βολιβιάνο Βολιβίας),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Πέσο Βολιβίας),
				'one' => q(πέσο Βολιβίας),
				'other' => q(πέσο Βολιβίας),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Μβδολ Βολιβίας),
				'one' => q(μβντολ Βολιβίας),
				'other' => q(μβντολ Βολιβίας),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Νέο Κρουζιέρο Βραζιλίας \(1967–1986\)),
				'one' => q(νέο κρουζέιρο Βραζιλίας \(BRB\)),
				'other' => q(νέα κρουζέιρο Βραζιλίας \(BRB\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Κρουζάντο Βραζιλίας),
				'one' => q(κρουζάντο Βραζιλίας),
				'other' => q(κρουζάντο Βραζιλίας),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Κρουζιέρο Βραζιλίας \(1990–1993\)),
				'one' => q(κρουζέιρο Βραζιλίας \(BRE\)),
				'other' => q(κρουζέιρο Βραζιλίας \(BRE\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Ρεάλ Βραζιλίας),
				'one' => q(ρεάλ Βραζιλίας),
				'other' => q(ρεάλ Βραζιλίας),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Νέο Κρουζάντο Βραζιλίας),
				'one' => q(νέο κρουζάντο Βραζιλίας),
				'other' => q(νέα κρουζάντο Βραζιλίας),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Κρουζιέρο Βραζιλίας),
				'one' => q(κρουζέιρο Βραζιλίας),
				'other' => q(κρουζέιρο Βραζιλίας),
			},
		},
		'BRZ' => {
			display_name => {
				'one' => q(Παλαιό κρουζέιρο Βραζιλίας),
				'other' => q(Παλαιά κρουζέιρο Βραζιλίας),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Δολάριο Μπαχαμών),
				'one' => q(δολάριο Μπαχαμών),
				'other' => q(δολάρια Μπαχαμών),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Νγκούλτρουμ Μπουτάν),
				'one' => q(νγκούλτρουμ Μπουτάν),
				'other' => q(νγκούλτρουμ Μπουτάν),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Κιατ Βιρμανίας),
				'one' => q(κιάτ Βιρμανίας),
				'other' => q(κιάτ Βιρμανίας),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Πούλα Μποτσουάνας),
				'one' => q(πούλα Μποτσουάνας),
				'other' => q(πούλα Μποτσουάνας),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Νέο Ρούβλι Λευκορωσίας \(1994–1999\)),
				'one' => q(νέο ρούβλι Λευκορωσίας \(1994–1999\)),
				'other' => q(νέα ρούβλια Λευκορωσίας \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Ρούβλι Λευκορωσίας),
				'one' => q(ρούβλι Λευκορωσίας),
				'other' => q(ρούβλια Λευκορωσίας),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Ρούβλι Λευκορωσίας \(2000–2016\)),
				'one' => q(ρούβλι Λευκορωσίας \(2000–2016\)),
				'other' => q(ρούβλια Λευκορωσίας \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Δολάριο Μπελίζ),
				'one' => q(δολάριο Μπελίζ),
				'other' => q(δολάρια Μπελίζ),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Δολάριο Καναδά),
				'one' => q(δολάριο Καναδά),
				'other' => q(δολάρια Καναδά),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Φράγκο Κονγκό),
				'one' => q(φράγκο Κονγκό),
				'other' => q(φράγκα Κονγκό),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Ευρώ WIR),
				'one' => q(ευρώ WIR),
				'other' => q(ευρώ WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Φράγκο Ελβετίας),
				'one' => q(φράγκο Ελβετίας),
				'other' => q(φράγκα Ελβετίας),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Φράγκο WIR),
				'one' => q(φράγκο WIR),
				'other' => q(φράγκα WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Εσκούδο Χιλής),
				'one' => q(Εσκούδο Χιλής),
				'other' => q(Εσκούδο Χιλής),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Ουνιδάδες ντε φομέντο Χιλής),
				'one' => q(ουνιδάδες ντε φομέντο Χιλής),
				'other' => q(ουνιδάδες ντε φομέντο Χιλής),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Πέσο Χιλής),
				'one' => q(πέσο Χιλής),
				'other' => q(πέσο Χιλής),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Γουάν Κίνας \(υπεράκτιο\)),
				'one' => q(γουάν Κίνας \(υπεράκτιο\)),
				'other' => q(γουάν Κίνας \(υπεράκτια\)),
			},
		},
		'CNX' => {
			display_name => {
				'one' => q(Δολάριο Λαϊκής Τράπεζας Κίνας),
				'other' => q(Δολάρια Λαϊκής Τράπεζας Κίνας),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Γουάν Κίνας),
				'one' => q(γουάν Κίνας),
				'other' => q(γουάν Κίνας),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Πέσο Κολομβίας),
				'one' => q(πέσο Κολομβίας),
				'other' => q(πέσο Κολομβίας),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Κολόν Κόστα Ρίκα),
				'one' => q(κολόν Κόστα Ρίκα),
				'other' => q(κολόν Κόστα Ρίκα),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Παλαιό Δηνάριο Σερβίας),
				'one' => q(παλιό δινάρη Σερβίας),
				'other' => q(παλιά δινάρια Σερβίας),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Σκληρή Κορόνα Τσεχοσλοβακίας),
				'one' => q(σκληρή κορόνα Τσεχοσλοβακίας),
				'other' => q(σκληρές κορόνες Τσεχοσλοβακίας),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Μετατρέψιμο πέσο Κούβας),
				'one' => q(μετατρέψιμο πέσο Κούβας),
				'other' => q(μετατρέψιμα πέσο Κούβας),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Πέσο Κούβας),
				'one' => q(πέσο Κούβας),
				'other' => q(πέσο Κούβας),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Εσκούδο Πράσινου Ακρωτηρίου),
				'one' => q(εσκούδο Πράσινου Ακρωτηρίου),
				'other' => q(εσκούδο Πράσινου Ακρωτηρίου),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Λίρα Κύπρου),
				'one' => q(λίρα Κύπρου),
				'other' => q(λίρες Κύπρου),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Κορόνα Τσεχίας),
				'one' => q(κορόνα Τσεχίας),
				'other' => q(κορόνες Τσεχίας),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Οστμάρκ Ανατολικής Γερμανίας),
				'one' => q(όστμαρκ Ανατολικής Γερμανίας),
				'other' => q(όστμαρκ Ανατολικής Γερμανίας),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Μάρκο Γερμανίας),
				'one' => q(μάρκο Γερμανίας),
				'other' => q(μάρκα Γερμανίας),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Φράγκο Τζιμπουτί),
				'one' => q(φράγκο Τζιμπουτί),
				'other' => q(φράγκα Τζιμπουτί),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Κορόνα Δανίας),
				'one' => q(κορόνα Δανίας),
				'other' => q(κορόνες Δανίας),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Πέσο Δομινικανής Δημοκρατίας),
				'one' => q(πέσο Δομινικανής Δημοκρατίας),
				'other' => q(πέσο Δομινικανής Δημοκρατίας),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Δηνάριο Αλγερίας),
				'one' => q(δηνάριο Αλγερίας),
				'other' => q(δηνάρια Αλγερίας),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Σούκρε Εκουαδόρ),
				'one' => q(σούκρε Εκουαδόρ),
				'other' => q(σούκρε Εκουαδόρ),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Κορόνα Εσθονίας),
				'one' => q(κορόνα Εσθονίας),
				'other' => q(κορόνες Εσθονίας),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Λίρα Αιγύπτου),
				'one' => q(λίρα Αιγύπτου),
				'other' => q(λίρες Αιγύπτου),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Νάκφα Ερυθραίας),
				'one' => q(νάκφα Ερυθραίας),
				'other' => q(νάκφα Ερυθραίας),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(πεσέτα Ισπανίας \(λογαριασμός Α\)),
				'one' => q(πεσέτα Ισπανίας \(λογαριασμός Α\)),
				'other' => q(πεσέτες Ισπανίας \(λογαριασμός Α\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(πεσέτα Ισπανίας \(μετατρέψιμος λογαριασμός\)),
				'one' => q(πεσέτα Ισπανίας \(μετατρέψιμος λογαριασμός\)),
				'other' => q(πεσέτες Ισπανίας \(μετατρέψιμες\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Πεσέτα Ισπανίας),
				'one' => q(πεσέτα Ισπανίας),
				'other' => q(πεσέτες Ισπανίας),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Μπιρ Αιθιοπίας),
				'one' => q(μπιρ Αιθιοπίας),
				'other' => q(μπιρ Αιθιοπίας),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Ευρώ),
				'one' => q(ευρώ),
				'other' => q(ευρώ),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Μάρκο Φινλανδίας),
				'one' => q(μάρκο Φινλανδίας),
				'other' => q(μάρκα Φινλανδίας),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Δολάριο Φίτζι),
				'one' => q(δολάριο Φίτζι),
				'other' => q(δολάρια Φίτζι),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Λίρα Νήσων Φόκλαντ),
				'one' => q(λίρα Νήσων Φόκλαντ),
				'other' => q(λίρες Νήσων Φόκλαντ),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Φράγκο Γαλλίας),
				'one' => q(φράγκο Γαλλίας),
				'other' => q(φράγκα Γαλλίας),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Λίρα Στερλίνα Βρετανίας),
				'one' => q(λίρα στερλίνα Βρετανίας),
				'other' => q(λίρες στερλίνες Βρετανίας),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Κούπον Λάρι Γεωργίας),
				'one' => q(κούπον λάρι Γεωργίας),
				'other' => q(κούπον λάρι Γεωργίας),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Λάρι Γεωργίας),
				'one' => q(λάρι Γεωργίας),
				'other' => q(λάρι Γεωργίας),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Σέντι Γκάνας \(1979–2007\)),
				'one' => q(σέντι Γκάνας \(GHC\)),
				'other' => q(σέντι Γκάνας \(GHC\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Σέντι Γκάνας),
				'one' => q(σέντι Γκάνας),
				'other' => q(σέντι Γκάνας),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Λίρα Γιβραλτάρ),
				'one' => q(λίρα Γιβραλτάρ),
				'other' => q(λίρες Γιβραλτάρ),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Νταλάσι Γκάμπιας),
				'one' => q(νταλάσι Γκάμπιας),
				'other' => q(νταλάσι Γκάμπιας),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Φράγκο Γουινέας),
				'one' => q(φράγκο Γουινέας),
				'other' => q(φράγκα Γουινέας),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Συλί Γουινέας),
				'one' => q(συλί Γουινέας),
				'other' => q(συλί Γουινέας),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Εκγουέλε Ισημερινής Γουινέας),
				'one' => q(εκουέλε Ισημερινής Γουινέας),
				'other' => q(εκουέλε Ισημερινής Γουινέας),
			},
		},
		'GRD' => {
			symbol => 'Δρχ',
			display_name => {
				'currency' => q(Δραχμή Ελλάδας),
				'one' => q(δραχμή Ελλάδας),
				'other' => q(δραχμές Ελλάδας),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Κουετσάλ Γουατεμάλας),
				'one' => q(κουετσάλ Γουατεμάλας),
				'other' => q(κουετσάλ Γουατεμάλας),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Γκινέα Εσκούδο Πορτογαλίας),
				'one' => q(γκινέα εσκούδο Πορτογαλίας),
				'other' => q(γκινέα εσκούδο Πορτογαλίας),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Πέσο Γουινέας-Μπισάου),
				'one' => q(πέσο Γουινέα-Μπισάου),
				'other' => q(πέσο Γουινέα-Μπισάου),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Δολάριο Γουιάνας),
				'one' => q(δολάριο Γουιάνας),
				'other' => q(δολάρια Γουιάνας),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Δολάριο Χονγκ Κονγκ),
				'one' => q(δολάριο Χονγκ Κονγκ),
				'other' => q(δολάρια Χονγκ Κονγκ),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Λεμπίρα Ονδούρας),
				'one' => q(λεμπίρα Ονδούρας),
				'other' => q(λεμπίρα Ονδούρας),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Δηνάριο Κροατίας),
				'one' => q(δηνάριο Κροατίας),
				'other' => q(δηνάρια Κροατίας),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Κούνα Κροατίας),
				'one' => q(κούνα Κροατίας),
				'other' => q(κούνα Κροατίας),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Γκουρντ Αϊτής),
				'one' => q(γκουρντ Αϊτής),
				'other' => q(γκουρντ Αϊτής),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Φιορίνι Ουγγαρίας),
				'one' => q(φιορίνι Ουγγαρίας),
				'other' => q(φιορίνια Ουγγαρίας),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Ρουπία Ινδονησίας),
				'one' => q(ρουπία Ινδονησίας),
				'other' => q(ρουπία Ινδονησίας),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Λίρα Ιρλανδίας),
				'one' => q(λίρα Ιρλανδίας),
				'other' => q(λίρες Ιρλανδίας),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Λίρα Ισραήλ),
				'one' => q(λίρα Ισραήλ),
				'other' => q(λίρες Ισραήλ),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(παλιό σεκέλ Ισραήλ),
				'one' => q(παλιό σεκέλ Ισραήλ),
				'other' => q(παλιά σεκέλ Ισραήλ),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Νέο Σέκελ Ισραήλ),
				'one' => q(νέο σέκελ Ισραήλ),
				'other' => q(νέα σέκελ Ισραήλ),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Ρουπία Ινδίας),
				'one' => q(ρουπία Ινδίας),
				'other' => q(ρουπίες Ινδίας),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Δηνάριο Ιράκ),
				'one' => q(δηνάριο Ιράκ),
				'other' => q(δηνάρια Ιράκ),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Ριάλ Ιράν),
				'one' => q(ριάλ Ιράν),
				'other' => q(ριάλ Ιράν),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Παλιά κορόνα Ισλανδίας),
				'one' => q(Παλιά κορόνα Ισλανδίας),
				'other' => q(παλιές κορόνες Ισλανδίας),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Κορόνα Ισλανδίας),
				'one' => q(κορόνα Ισλανδίας),
				'other' => q(κορόνες Ισλανδίας),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Λιρέτα Ιταλίας),
				'one' => q(λιρέτα Ιταλίας),
				'other' => q(λιρέτες Ιταλίας),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Δολάριο Τζαμάικας),
				'one' => q(δολάριο Τζαμάικας),
				'other' => q(δολάρια Τζαμάικας),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Δηνάριο Ιορδανίας),
				'one' => q(δηνάριο Ιορδανίας),
				'other' => q(δηνάρια Ιορδανίας),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Γιεν Ιαπωνίας),
				'one' => q(γιεν Ιαπωνίας),
				'other' => q(γιεν Ιαπωνίας),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Σελίνι Κένυας),
				'one' => q(σελίνι Κένυας),
				'other' => q(σελίνια Κένυας),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Σομ Κιργιζίας),
				'one' => q(σομ Κιργιζίας),
				'other' => q(σομ Κιργιζίας),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Ρίελ Καμπότζης),
				'one' => q(ρίελ Καμπότζης),
				'other' => q(ρίελ Καμπότζης),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Φράγκο Κομορών),
				'one' => q(φράγκο Κομορών),
				'other' => q(φράγκα Κομορών),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Γουόν Βόρειας Κορέας),
				'one' => q(γουόν Βόρειας Κορέας),
				'other' => q(γουόν Βόρειας Κορέας),
			},
		},
		'KRO' => {
			display_name => {
				'one' => q(Παλιό γον Νότιας Κορέας),
				'other' => q(Παλιά γον Νότιας Κορέας),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Γουόν Νότιας Κορέας),
				'one' => q(γουόν Νότιας Κορέας),
				'other' => q(γουόν Νότιας Κορέας),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Δηνάριο Κουβέιτ),
				'one' => q(δηνάριο Κουβέιτ),
				'other' => q(δηνάρια Κουβέιτ),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Δολάριο Νήσων Κέιμαν),
				'one' => q(δολάριο Νήσων Κέιμαν),
				'other' => q(δολάρια Νήσων Κέιμαν),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Τένγκε Καζακστάν),
				'one' => q(τένγκε Καζακστάν),
				'other' => q(τένγκε Καζακστάν),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Κιπ Λάος),
				'one' => q(κιπ Λάος),
				'other' => q(κιπ Λάος),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Λίρα Λιβάνου),
				'one' => q(λίρα Λιβάνου),
				'other' => q(λίρες Λιβάνου),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Ρουπία Σρι Λάνκα),
				'one' => q(ρουπία Σρι Λάνκα),
				'other' => q(ρουπίες Σρι Λάνκα),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Δολάριο Λιβερίας),
				'one' => q(δολάριο Λιβερίας),
				'other' => q(δολάρια Λιβερίας),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Λότι Λεσότο),
				'one' => q(λότι Λεσόθο),
				'other' => q(λότι Λεσόθο),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Λίτα Λιθουανίας),
				'one' => q(λίτα Λιθουανίας),
				'other' => q(λίτα Λιθουανίας),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Ταλόνας Λιθουανίας),
				'one' => q(ταλόνας Λιθουανίας),
				'other' => q(ταλόνας Λιθουανίας),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Μετατρέψιμο Φράγκο Λουξεμβούργου),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Φράγκο Λουξεμβούργου),
				'one' => q(φράγκο Λουξεμβούργου),
				'other' => q(φράγκα Λουξεμβούργου),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Οικονομικό Φράγκο Λουξεμβούργου),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Λατς Λετονίας),
				'one' => q(λατς Λετονίας),
				'other' => q(λατς Λετονίας),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Ρούβλι Λετονίας),
				'one' => q(ρούβλι Λετονίας),
				'other' => q(ρούβλια Λετονίας),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Δηνάριο Λιβύης),
				'one' => q(δηνάριο Λιβύης),
				'other' => q(δηνάρια Λιβύης),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Ντιράμ Μαρόκου),
				'one' => q(ντιράμ Μαρόκου),
				'other' => q(ντιράμ Μαρόκου),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Φράγκο Μαρόκου),
				'one' => q(φράγκο Μαρόκου),
				'other' => q(φράγκα Μαρόκου),
			},
		},
		'MCF' => {
			display_name => {
				'one' => q(Φράγκο Μονακό),
				'other' => q(Φράγκα Μονακό),
			},
		},
		'MDC' => {
			display_name => {
				'one' => q(Κούπον Μολδαβίας),
				'other' => q(Κούπον Μολδαβίας),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Λέου Μολδαβίας),
				'one' => q(λέου Μολδαβίας),
				'other' => q(λέου Μολδαβίας),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Αριάρι Μαδαγασκάρης),
				'one' => q(αριάρι Μαδαγασκάρης),
				'other' => q(αριάρι Μαδαγασκάρης),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Φράγκο Μαδαγασκάρης),
				'one' => q(φράγκο Μαδαγασκάρης),
				'other' => q(φράγκα Μαδαγασκάρης),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Δηνάριο ΠΓΔΜ),
				'one' => q(δηνάριο ΠΓΔΜ),
				'other' => q(δηνάρια ΠΓΔΜ),
			},
		},
		'MKN' => {
			display_name => {
				'one' => q(Παλιό δηνάριο ΠΓΔΜ),
				'other' => q(Παλιά δηνάρια ΠΓΔΜ),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Φράγκο Μαλί),
				'one' => q(φράγκο Μαλί),
				'other' => q(φράγκα Μαλί),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Κιάτ Μιανμάρ),
				'one' => q(κιάτ Μιανμάρ),
				'other' => q(κιάτ Μιανμάρ),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Τουγκρίκ Μογγολίας),
				'one' => q(τουγκρίκ Μογγολίας),
				'other' => q(τουγκρίκ Μογγολίας),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Πατάκα Μακάο),
				'one' => q(πατάκα Μακάο),
				'other' => q(πατάκα Μακάο),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ουγκίγια Μαυριτανίας \(1973–2017\)),
				'one' => q(ουγκίγια Μαυριτανίας \(1973–2017\)),
				'other' => q(ουγκίγια Μαυριτανίας \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Ουγκίγια Μαυριτανίας),
				'one' => q(ουγκίγια Μαυριτανίας),
				'other' => q(ουγκίγια Μαυριτανίας),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Λιρέτα Μάλτας),
				'one' => q(λιρέτα Μάλτας),
				'other' => q(λιρέτες Μάλτας),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Λίρα Μάλτας),
				'one' => q(λίρα Μάλτας),
				'other' => q(λίρες Μάλτας),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Ρουπία Μαυρικίου),
				'one' => q(ρουπία Μαυρικίου),
				'other' => q(ρουπίες Μαυρικίου),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Ρουφίγια Μαλδίβων),
				'one' => q(ρουφίγια Μαλδίβων),
				'other' => q(ρουφίγιες Μαλδίβων),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Κουάτσα Μαλάουι),
				'one' => q(κουάτσα Μαλάουι),
				'other' => q(κουάτσα Μαλάουι),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Πέσο Μεξικού),
				'one' => q(πέσο Μεξικού),
				'other' => q(πέσο Μεξικού),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Ασημένιο Πέσο Μεξικού \(1861–1992\)),
				'one' => q(ασημένιο πέσο Μεξικού \(MXP\)),
				'other' => q(ασημένια πέσο Μεξικού \(MXP\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ρινγκίτ Μαλαισίας),
				'one' => q(ρινγκίτ Μαλαισίας),
				'other' => q(ρινγκίτ Μαλαισίας),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Εσκούδο Μοζαμβίκης),
				'one' => q(εσκούδο Μοζαμβίκης),
				'other' => q(εσκούδο Μοζαμβίκης),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Παλαιό Μετικάλ Μοζαμβίκης),
				'one' => q(παλιό μετικάλ Μοζαμβίκης),
				'other' => q(παλιά μετικάλ Μοζαμβίκης),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Μετικάλ Μοζαμβίκης),
				'one' => q(μετικάλ Μοζαμβίκης),
				'other' => q(μετικάλ Μοζαμβίκης),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Δολάριο Ναμίμπιας),
				'one' => q(δολάριο Ναμίμπιας),
				'other' => q(δολάρια Ναμίμπιας),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Νάιρα Νιγηρίας),
				'one' => q(νάιρα Νιγηρίας),
				'other' => q(νάιρα Νιγηρίας),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Κόρδοβα Νικαράγουας),
				'one' => q(κόρδοβα Νικαράγουας),
				'other' => q(κόρδοβα Νικαράγουας),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Χρυσή Κόρδοβα Νικαράγουας),
				'one' => q(χρυσή κόρδοβα Νικαράγουας),
				'other' => q(χρυσές κόρδοβα Νικαράγουας),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Γκίλντα Ολλανδίας),
				'one' => q(γκίλντα Ολλανδίας),
				'other' => q(γκίλντα Ολλανδίας),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Κορόνα Νορβηγίας),
				'one' => q(κορόνα Νορβηγίας),
				'other' => q(κορόνες Νορβηγίας),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Ρουπία Νεπάλ),
				'one' => q(ρουπία Νεπάλ),
				'other' => q(ρουπίες Νεπάλ),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Δολάριο Νέας Ζηλανδίας),
				'one' => q(δολάριο Νέας Ζηλανδίας),
				'other' => q(δολάρια Νέας Ζηλανδίας),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Ριάλ Ομάν),
				'one' => q(ριάλ Ομάν),
				'other' => q(ριάλ Ομάν),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Μπαλμπόα Παναμά),
				'one' => q(μπαλμπόα Παναμά),
				'other' => q(μπαλμπόα Παναμά),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Ίντι Περού),
				'one' => q(ίντι Περού),
				'other' => q(ίντι Περού),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Σολ Περού),
				'one' => q(σολ Περού),
				'other' => q(σολ Περού),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Σολ Περού \(1863–1965\)),
				'one' => q(σολ Περού \(1863–1965\)),
				'other' => q(σολ Περού \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Κίνα Παπούας Νέας Γουινέας),
				'one' => q(κίνα Παπούας Νέας Γουινέας),
				'other' => q(κίνα Παπούας Νέας Γουινέας),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Πέσο Φιλιππίνων),
				'one' => q(πέσο Φιλιππίνων),
				'other' => q(πέσο Φιλιππίνων),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Ρουπία Πακιστάν),
				'one' => q(ρουπία Πακιστάν),
				'other' => q(ρουπίες Πακιστάν),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Ζλότι Πολωνίας),
				'one' => q(ζλότι Πολωνίας),
				'other' => q(ζλότι Πολωνίας),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Ζλότυ Πολωνίας \(1950–1995\)),
				'one' => q(ζλότυ Πολωνίας \(PLZ\)),
				'other' => q(ζλότυ Πολωνίας \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Εσκούδο Πορτογαλίας),
				'one' => q(εσκούδο Πορτογαλίας),
				'other' => q(εσκούδο Πορτογαλίας),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Γκουαρανί Παραγουάης),
				'one' => q(γκουαρανί Παραγουάης),
				'other' => q(γκουαρανί Παραγουάης),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Ριάλ Κατάρ),
				'one' => q(ριάλ Κατάρ),
				'other' => q(ριάλ Κατάρ),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Δολάριο Ροδεσίας),
				'one' => q(δολάριο Ροδεσίας),
				'other' => q(δολάρια Ροδεσίας),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Λέι Ρουμανίας),
				'one' => q(παλιό λέι Ρουμανίας),
				'other' => q(παλιά λέι Ρουμανίας),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Λέου Ρουμανίας),
				'one' => q(λέου Ρουμανίας),
				'other' => q(λέου Ρουμανίας),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Δηνάριο Σερβίας),
				'one' => q(δηνάριο Σερβίας),
				'other' => q(δηνάρια Σερβίας),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Ρούβλι Ρωσίας),
				'one' => q(ρούβλι Ρωσίας),
				'other' => q(ρούβλια Ρωσίας),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Ρούβλι Ρωσίας \(1991–1998\)),
				'one' => q(ρούβλι Ρωσίας \(RUR\)),
				'other' => q(ρούβλια Ρωσίας \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Φράγκο Ρουάντας),
				'one' => q(φράγκο Ρουάντας),
				'other' => q(φράγκα Ρουάντας),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Ριάλ Σαουδικής Αραβίας),
				'one' => q(ριάλ Σαουδικής Αραβίας),
				'other' => q(ριάλ Σαουδικής Αραβίας),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Δολάριο Νήσων Σολομώντος),
				'one' => q(δολάριο Νήσων Σολομώντος),
				'other' => q(δολάρια Νήσων Σολομώντος),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Ρουπία Σεϋχελλών),
				'one' => q(ρουπία Σεϋχελλών),
				'other' => q(ρουπίες Σεϋχελλών),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Δηνάριο Σουδάν),
				'one' => q(δηνάριο Σουδάν),
				'other' => q(δηνάρια Σουδάν),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Λίρα Σουδάν),
				'one' => q(λίρα Σουδάν),
				'other' => q(λίρες Σουδάν),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Παλαιά Λίρα Σουδάν),
				'one' => q(παλιά λίρα Σουδάν),
				'other' => q(παλαιές λίρες Σουδάν),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Κορόνα Σουηδίας),
				'one' => q(κορόνα Σουηδίας),
				'other' => q(κορόνες Σουηδίας),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Δολάριο Σιγκαπούρης),
				'one' => q(δολάριο Σιγκαπούρης),
				'other' => q(δολάρια Σιγκαπούρης),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Λίρα Αγίας Ελένης),
				'one' => q(λίρα Αγίας Ελένης),
				'other' => q(λίρες Αγίας Ελένης),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Τόλαρ Σλοβενίας),
				'one' => q(τόλαρ Σλοβενίας),
				'other' => q(τόλαρ Σλοβ),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Κορόνα Σλοβενίας),
				'one' => q(κορόνα Σλοβενίας),
				'other' => q(κορόνες Σλοβενίας),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Λεόνε Σιέρα Λεόνε),
				'one' => q(λεόνε Σιέρα Λεόνε),
				'other' => q(λεόνε Σιέρα Λεόνε),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Σελίνι Σομαλίας),
				'one' => q(σελίνι Σομαλίας),
				'other' => q(σελίνια Σομαλίας),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Δολάριο Σουρινάμ),
				'one' => q(δολάριο Σουρινάμ),
				'other' => q(δολάρια Σουρινάμ),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Γκίλντα Σουρινάμ),
				'one' => q(γκίλντα Σουρινάμ),
				'other' => q(γκίλντα Σουρινάμ),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Λίρα Νότιου Σουδάν),
				'one' => q(λίρα Νότιου Σουδάν),
				'other' => q(λίρες Νότιου Σουδάν),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Ντόμπρα Σάο Τομέ και Πρίνσιπε \(1977–2017\)),
				'one' => q(ντόμπρα Σάο Τομέ και Πρίνσιπε \(1977–2017\)),
				'other' => q(ντόμπρα Σάο Τομέ και Πρίνσιπε \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Ντόμπρα Σάο Τομέ και Πρίνσιπε),
				'one' => q(ντόμπρα Σάο Τομέ και Πρίνσιπε),
				'other' => q(ντόμπρα Σάο Τομέ και Πρίνσιπε),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Σοβιετικό Ρούβλι),
				'one' => q(σοβιετικό ρούβλι),
				'other' => q(σοβιετικά ρούβλια),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Κολόν Ελ Σαλβαδόρ),
				'one' => q(κολόν Ελ Σαλβαδόρ),
				'other' => q(κολόν Ελ Σαλβαδόρ),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Λίρα Συρίας),
				'one' => q(λίρα Συρίας),
				'other' => q(λίρες Συρίας),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Λιλανγκένι Σουαζιλάνδης),
				'one' => q(λιλανγκένι Σουαζιλάνδης),
				'other' => q(λιλανγκένι Σουαζιλάνδης),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Μπατ Ταϊλάνδης),
				'one' => q(μπατ Ταϊλάνδης),
				'other' => q(μπατ Ταϊλάνδης),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Ρούβλι Τατζικιστάν),
				'one' => q(ρούβλι Τατζικιστάν),
				'other' => q(ρούβλια Τατζικιστάν),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Σομόνι Τατζικιστάν),
				'one' => q(σομόνι Τατζικιστάν),
				'other' => q(σομόνι Τατζικιστάν),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Μανάτ Τουρκμενιστάν),
				'one' => q(μανάτ Τουρκμενιστάν),
				'other' => q(μανάτ Τουρκμενιστάν),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Μάνατ Τουρκμενιστάν),
				'one' => q(μάνατ Τουρκμενιστάν),
				'other' => q(μάνατ Τουρκμενιστάν),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Δηνάριο Τυνησίας),
				'one' => q(δηνάριο Τυνησίας),
				'other' => q(δηνάρια Τυνησίας),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Παάγκα Τόνγκα),
				'one' => q(παάγκα Τόνγκα),
				'other' => q(παάγκα Τόνγκα),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(Εσκούδο Τιμόρ),
				'one' => q(εσκούδο Τιμόρ),
				'other' => q(εσκούδο Τιμόρ),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Παλιά Λίρα Τουρκίας),
				'one' => q(παλιά λίρα Τουρκίας),
				'other' => q(παλιές λίρες Τουρκίας),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Λίρα Τουρκίας),
				'one' => q(λίρα Τουρκίας),
				'other' => q(λίρες Τουρκίας),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Δολάριο Τρινιντάντ και Τομπάγκο),
				'one' => q(δολάριο Τρινιντάντ και Τομπάγκο),
				'other' => q(δολάρια Τρινιντάντ και Τομπάγκο),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Νέο δολάριο Ταϊβάν),
				'one' => q(νέο δολάριο Ταϊβάν),
				'other' => q(νέα δολάρια Ταϊβάν),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Σελίνι Τανζανίας),
				'one' => q(σελίνι Τανζανίας),
				'other' => q(σελίνια Τανζανίας),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Γρίβνα Ουκρανίας),
				'one' => q(γρίβνα Ουκρανίας),
				'other' => q(γρίβνα Ουκρανίας),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Καρμποβανέτς Ουκρανίας),
				'one' => q(καρμποβανέτς Ουκρανίας),
				'other' => q(καρμποβανέτς Ουκρανίας),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Σελίνι Ουγκάντας \(1966–1987\)),
				'one' => q(σελίνι Ουγκάντας \(UGS\)),
				'other' => q(σελίνια Ουγκάντας \(UGS\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Σελίνι Ουγκάντας),
				'one' => q(σελίνι Ουγκάντας),
				'other' => q(σελίνια Ουγκάντας),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Δολάριο ΗΠΑ),
				'one' => q(δολάριο ΗΠΑ),
				'other' => q(δολάρια ΗΠΑ),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Δολάριο ΗΠΑ \(επόμενη ημέρα\)),
				'one' => q(δολάριο Η.Π.Α. \(επόμενη ημέρα\)),
				'other' => q(δολάρια Η.Π.Α. \(επόμενη ημέρα\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Δολάριο ΗΠΑ \(ίδια ημέρα\)),
				'one' => q(δολάριο Η.Π.Α. \(ίδια ημέρα\)),
				'other' => q(δολάρια Η.Π.Α. \(ίδια ημέρα\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Πέσο Ουρουγουάης \(1975–1993\)),
				'one' => q(πέσο Ουρουγουάης \(UYP\)),
				'other' => q(πέσο Ουρουγουάης \(UYP\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Πέσο Ουρουγουάης),
				'one' => q(πέσο Ουρουγουάης),
				'other' => q(πέσο Ουρουγουάης),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Σομ Ουζμπεκιστάν),
				'one' => q(σομ Ουζμπεκιστάν),
				'other' => q(σομ Ουζμπεκιστάν),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Μπολιβάρ Βενεζουέλας \(1871–2008\)),
				'one' => q(μπολιβάρ Βενεζουέλας \(1871–2008\)),
				'other' => q(μπολιβάρ Βενεζουέλας \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Μπολιβάρ Βενεζουέλας \(2008–2018\)),
				'one' => q(μπολιβάρ Βενεζουέλας \(2008–2018\)),
				'other' => q(μπολιβάρ Βενεζουέλας \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Μπολιβάρ Βενεζουέλας),
				'one' => q(μπολιβάρ Βενεζουέλας),
				'other' => q(μπολιβάρ Βενεζουέλας),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Ντονγκ Βιετνάμ),
				'one' => q(ντονγκ Βιετνάμ),
				'other' => q(ντονγκ Βιετνάμ),
			},
		},
		'VNN' => {
			display_name => {
				'one' => q(Παλαιό ντονγκ Βιετνάμ),
				'other' => q(Παλαιά ντονγκ Βιετνάμ),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Βατού Βανουάτου),
				'one' => q(βατού Βανουάτου),
				'other' => q(βατού Βανουάτου),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Τάλα Σαμόα),
				'one' => q(τάλα Σαμόα),
				'other' => q(τάλα Σαμόα),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Φράγκο CFA Κεντρικής Αφρικής),
				'one' => q(φράγκο CFA Κεντρικής Αφρικής),
				'other' => q(φράγκα CFA Κεντρικής Αφρικής),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Ευρωπαϊκή Σύνθετη Μονάδα),
				'one' => q(ευρωπαϊκή σύνθετη μονάδα),
				'other' => q(ευρωπαϊκές σύνθετες μονάδες),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Ευρωπαϊκή Νομισματική Μονάδα),
				'one' => q(ευρωπαϊκή νομισματική μονάδα),
				'other' => q(ευρωπαϊκές νομισματικές μονάδες),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Ευρωπαϊκή μονάδα λογαριασμού \(XBC\)),
				'one' => q(ευρωπαϊκή μονάδα λογαριασμού \(XBC\)),
				'other' => q(ευρωπαϊκές μονάδες λογαριασμού \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Ευρωπαϊκή μονάδα λογαριασμού \(XBD\)),
				'one' => q(ευρωπαϊκή μονάδα λογαριασμού \(XBD\)),
				'other' => q(ευρωπαϊκές μονάδες λογαριασμού \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Δολάριο Ανατολικής Καραϊβικής),
				'one' => q(δολάριο Ανατολικής Καραϊβικής),
				'other' => q(δολάρια Ανατολικής Καραϊβικής),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Ειδικά Δικαιώματα Ανάληψης),
				'one' => q(ειδικό δικαίωμα ανάληψης),
				'other' => q(ειδικά δικαιώματα ανάληψης),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Ευρωπαϊκή Συναλλαγματική Μονάδα),
				'one' => q(ευρωπαϊκή συναλλαγματική μονάδα),
				'other' => q(ευρωπαϊκές συναλλαγματικές μονάδες),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Χρυσό Φράγκο Γαλλίας),
				'one' => q(χρυσό φράγκο Γαλλίας),
				'other' => q(χρυσά φράγκα Γαλλίας),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(UIC-Φράγκο Γαλλίας),
				'one' => q(UIC-φράγκο Γαλλίας),
				'other' => q(UIC-φράγκα Γαλλίας),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Φράγκο CFA Δυτικής Αφρικής),
				'one' => q(φράγκο CFA Δυτικής Αφρικής),
				'other' => q(φράγκα CFA Δυτικής Αφρικής),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Φράγκο CFP),
				'one' => q(φράγκο CFP),
				'other' => q(φράγκα CFP),
			},
		},
		'XRE' => {
			display_name => {
				'one' => q(Ταμείο RINET),
				'other' => q(Ταμείο RINET),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Άγνωστο νόμισμα),
				'one' => q(\(άγνωστο νόμισμα\)),
				'other' => q(\(άγνωστο νόμισμα\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Δηνάριο Υεμένης),
				'one' => q(δηνάριο Υεμένης),
				'other' => q(δηνάρια Υεμένης),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Ριάλ Υεμένης),
				'one' => q(ριάλ Υεμένης),
				'other' => q(ριάλ Υεμένης),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Μεταλλικό Δηνάριο Γιουγκοσλαβίας),
				'one' => q(μεταλλικό δηνάριο Γιουγκοσλαβίας),
				'other' => q(μεταλλικά δηνάρια Γιουγκοσλαβίας),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Νέο Δηνάριο Γιουγκοσλαβίας),
				'one' => q(νέο δηνάριο Γιουγκοσλαβίας),
				'other' => q(νέο δηνάριο Γιουγκοσλαβίας),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Μετατρέψιμο Δηνάριο Γιουγκοσλαβίας),
				'one' => q(μετατρέψιμο δινάριο Γιουγκοσλαβίας),
				'other' => q(μετατρέψιμο δηνάριο Γιουγκοσλαβίας),
			},
		},
		'YUR' => {
			display_name => {
				'one' => q(Αναμορφωμένο δηνάριο Γιουγκοσλαβίας),
				'other' => q(Αναμορφωμένα δηνάρια Γιουγκοσλαβίας),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Ραντ Νότιας Αφρικής \(οικονομικό\)),
				'one' => q(ραντ Νότιας Αφρικής \(οικονομικό\)),
				'other' => q(ραντ Νότιας Αφρικής \(οικονομικό\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Ραντ Νότιας Αφρικής),
				'one' => q(ραντ Νότιας Αφρικής),
				'other' => q(ραντ Νότιας Αφρικής),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Κουάνζα Ζαΐρ \(1968–2012\)),
				'one' => q(κουάτσα Ζάμπιας \(1968–2012\)),
				'other' => q(κουάτσα Ζάμπιας \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Κουάτσα Ζάμπιας),
				'one' => q(κουάτσα Ζάμπιας),
				'other' => q(κουάτσα Ζάμπιας),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Νέο Ζαΐρ Ζαΐρ),
				'one' => q(νέο ζαΐρ Ζαΐρ),
				'other' => q(νέα ζαΐρ Ζαΐρ),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Ζαΐρ Ζαΐρ),
				'one' => q(ζαΐρ Ζαΐρ),
				'other' => q(ζαΐρ Ζαΐρ),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Δολάριο Ζιμπάμπουε),
				'one' => q(δολάριο Ζιμπάμπουε),
				'other' => q(δολάρια Ζιμπάμπουε),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Δολάριο Ζιμπάμπουε \(2009\)),
				'one' => q(Δολάριο Ζιμπάμπουε \(2009\)),
				'other' => q(Δολάριο Ζιμπάμπουε \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'one' => q(Δολάριο Ζιμπάμπουε \(2008\)),
				'other' => q(Δολάρια Ζιμπάμπουε \(2008\)),
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
					abbreviated => {
						nonleap => [
							'Τουτ',
							'Μπάπα',
							'Χατούρ',
							'Κεγιάχκ',
							'Τούμπα',
							'Αμσίρ',
							'Μπαραμχάτ',
							'Μπαρμούντα',
							'Μπασάνς',
							'Μπαούνα',
							'Αμπίπ',
							'Μέσρα',
							'Νεσγ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Τουτ',
							'Μπάπα',
							'Χατούρ',
							'Κεγιάχκ',
							'Τούμπα',
							'Αμσίρ',
							'Μπαραμχάτ',
							'Μπαρμούντα',
							'Μπασάνς',
							'Μπαούνα',
							'Αμπίπ',
							'Μέσρα',
							'Νεσγ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Τουτ',
							'Μπάπα',
							'Χατούρ',
							'Κεγιάχκ',
							'Τούμπα',
							'Αμσίρ',
							'Μπαραμχάτ',
							'Μπαρμούντα',
							'Μπασάνς',
							'Μπαούνα',
							'Αμπίπ',
							'Μέσρα',
							'Νεσγ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Τουτ',
							'Μπάπα',
							'Χατούρ',
							'Κεγιάχκ',
							'Τούμπα',
							'Αμσίρ',
							'Μπαραμχάτ',
							'Μπαρμούντα',
							'Μπασάνς',
							'Μπαούνα',
							'Αμπίπ',
							'Μέσρα',
							'Νεσγ'
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
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
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
							'Ιαν',
							'Φεβ',
							'Μαρ',
							'Απρ',
							'Μαΐ',
							'Ιουν',
							'Ιουλ',
							'Αυγ',
							'Σεπ',
							'Οκτ',
							'Νοε',
							'Δεκ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ι',
							'Φ',
							'Μ',
							'Α',
							'Μ',
							'Ι',
							'Ι',
							'Α',
							'Σ',
							'Ο',
							'Ν',
							'Δ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ιανουαρίου',
							'Φεβρουαρίου',
							'Μαρτίου',
							'Απριλίου',
							'Μαΐου',
							'Ιουνίου',
							'Ιουλίου',
							'Αυγούστου',
							'Σεπτεμβρίου',
							'Οκτωβρίου',
							'Νοεμβρίου',
							'Δεκεμβρίου'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ιαν',
							'Φεβ',
							'Μάρ',
							'Απρ',
							'Μάι',
							'Ιούν',
							'Ιούλ',
							'Αύγ',
							'Σεπ',
							'Οκτ',
							'Νοέ',
							'Δεκ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ι',
							'Φ',
							'Μ',
							'Α',
							'Μ',
							'Ι',
							'Ι',
							'Α',
							'Σ',
							'Ο',
							'Ν',
							'Δ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ιανουάριος',
							'Φεβρουάριος',
							'Μάρτιος',
							'Απρίλιος',
							'Μάιος',
							'Ιούνιος',
							'Ιούλιος',
							'Αύγουστος',
							'Σεπτέμβριος',
							'Οκτώβριος',
							'Νοέμβριος',
							'Δεκέμβριος'
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
							'Τισρί',
							'Χεσβάν',
							'Κισλέφ',
							'Τέβετ',
							'Σεβάτ',
							'Αντάρ I',
							'Αντάρ',
							'Νισάν',
							'Ιγιάρ',
							'Σιβάν',
							'Ταμούζ',
							'Αβ',
							'Έλουλ'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Αντάρ II'
						],
					},
					wide => {
						nonleap => [
							'Τισρί',
							'Χεσβάν',
							'Κισλέφ',
							'Τέβετ',
							'Σεβάτ',
							'Αντάρ I',
							'Αντάρ',
							'Νισάν',
							'Ιγιάρ',
							'Σιβάν',
							'Ταμούζ',
							'Αβ',
							'Έλουλ'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Αντάρ II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Τισρί',
							'Χεσβάν',
							'Κισλέφ',
							'Τέβετ',
							'Σεβάτ',
							'Αντάρ I',
							'Αντάρ',
							'Νισάν',
							'Ιγιάρ',
							'Σιβάν',
							'Ταμούζ',
							'Αβ',
							'Έλουλ'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Αντάρ II'
						],
					},
					wide => {
						nonleap => [
							'Τισρί',
							'Χεσβάν',
							'Κισλέφ',
							'Τέβετ',
							'Σεβάτ',
							'Αντάρ I',
							'Αντάρ',
							'Νισάν',
							'Ιγιάρ',
							'Σιβάν',
							'Ταμούζ',
							'Αβ',
							'Έλουλ'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Αντάρ II'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
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
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
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
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
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
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
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
						mon => 'Δευ',
						tue => 'Τρί',
						wed => 'Τετ',
						thu => 'Πέμ',
						fri => 'Παρ',
						sat => 'Σάβ',
						sun => 'Κυρ'
					},
					narrow => {
						mon => 'Δ',
						tue => 'Τ',
						wed => 'Τ',
						thu => 'Π',
						fri => 'Π',
						sat => 'Σ',
						sun => 'Κ'
					},
					short => {
						mon => 'Δε',
						tue => 'Τρ',
						wed => 'Τε',
						thu => 'Πέ',
						fri => 'Πα',
						sat => 'Σά',
						sun => 'Κυ'
					},
					wide => {
						mon => 'Δευτέρα',
						tue => 'Τρίτη',
						wed => 'Τετάρτη',
						thu => 'Πέμπτη',
						fri => 'Παρασκευή',
						sat => 'Σάββατο',
						sun => 'Κυριακή'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Δευ',
						tue => 'Τρί',
						wed => 'Τετ',
						thu => 'Πέμ',
						fri => 'Παρ',
						sat => 'Σάβ',
						sun => 'Κυρ'
					},
					narrow => {
						mon => 'Δ',
						tue => 'Τ',
						wed => 'Τ',
						thu => 'Π',
						fri => 'Π',
						sat => 'Σ',
						sun => 'Κ'
					},
					short => {
						mon => 'Δε',
						tue => 'Τρ',
						wed => 'Τε',
						thu => 'Πέ',
						fri => 'Πα',
						sat => 'Σά',
						sun => 'Κυ'
					},
					wide => {
						mon => 'Δευτέρα',
						tue => 'Τρίτη',
						wed => 'Τετάρτη',
						thu => 'Πέμπτη',
						fri => 'Παρασκευή',
						sat => 'Σάββατο',
						sun => 'Κυριακή'
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
					abbreviated => {0 => 'Τ1',
						1 => 'Τ2',
						2 => 'Τ3',
						3 => 'Τ4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1ο τρίμηνο',
						1 => '2ο τρίμηνο',
						2 => '3ο τρίμηνο',
						3 => '4ο τρίμηνο'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Τ1',
						1 => 'Τ2',
						2 => 'Τ3',
						3 => 'Τ4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1ο τρίμηνο',
						1 => '2ο τρίμηνο',
						2 => '3ο τρίμηνο',
						3 => '4ο τρίμηνο'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
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
					'afternoon1' => q{μεσημ.},
					'am' => q{π.μ.},
					'evening1' => q{απόγ.},
					'morning1' => q{πρωί},
					'night1' => q{βράδυ},
					'pm' => q{μ.μ.},
				},
				'narrow' => {
					'afternoon1' => q{μεσημ.},
					'am' => q{πμ},
					'evening1' => q{απόγ.},
					'morning1' => q{πρωί},
					'night1' => q{βράδυ},
					'pm' => q{μμ},
				},
				'wide' => {
					'afternoon1' => q{μεσημέρι},
					'am' => q{π.μ.},
					'evening1' => q{απόγευμα},
					'morning1' => q{πρωί},
					'night1' => q{βράδυ},
					'pm' => q{μ.μ.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{μεσημ.},
					'am' => q{π.μ.},
					'evening1' => q{απόγ.},
					'morning1' => q{πρωί},
					'night1' => q{βράδυ},
					'pm' => q{μ.μ.},
				},
				'narrow' => {
					'afternoon1' => q{μεσημ.},
					'am' => q{πμ},
					'evening1' => q{απόγ.},
					'morning1' => q{πρωί},
					'night1' => q{βράδυ},
					'pm' => q{μμ},
				},
				'wide' => {
					'afternoon1' => q{μεσημέρι},
					'am' => q{π.μ.},
					'evening1' => q{απόγευμα},
					'morning1' => q{πρωί},
					'night1' => q{βράδυ},
					'pm' => q{μ.μ.},
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
				'0' => 'Β.Ε.'
			},
		},
		'coptic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'π.Χ.',
				'1' => 'μ.Χ.'
			},
			wide => {
				'0' => 'προ Χριστού',
				'1' => 'μετά Χριστόν'
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
				'0' => 'AM'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Σάκα'
			},
			narrow => {
				'0' => 'Σάκα'
			},
			wide => {
				'0' => 'Σάκα'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'Ε.Ε.'
			},
			narrow => {
				'0' => 'Ε.Ε.'
			},
			wide => {
				'0' => 'Ε.Ε.'
			},
		},
		'japanese' => {
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			narrow => {
				'0' => 'AP'
			},
			wide => {
				'0' => 'AP'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'προ R.O.C.',
				'1' => 'R.O.C.'
			},
			narrow => {
				'0' => 'προ R.O.C.',
				'1' => 'R.O.C.'
			},
			wide => {
				'0' => 'προ R.O.C.',
				'1' => 'R.O.C.'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, d MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/yy},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'full' => q{{1} - {0}},
			'long' => q{{1} - {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} - {0}},
			'long' => q{{1} - {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} - {0}},
			'long' => q{{1} - {0}},
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
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
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
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{MMM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{εβδομάδα W του MMM},
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
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{εβδομάδα w του Y},
		},
		'japanese' => {
			Ed => q{E d},
			Gy => q{y G},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{y G},
			yM => q{MM/y GGGGG},
			yMEd => q{E, dd/MM/y GGGGG},
			yMMM => q{LLL y GGGGG},
			yMMMEd => q{E, d MMM, y G},
			yMMMd => q{d MMM, y G},
			yMd => q{dd/MM/y GGGGG},
			yQQQ => q{y GGGGG QQQ},
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
		'buddhist' => {
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
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
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
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, dd MMM – E, dd MMM y G},
				d => q{E, dd – E, dd MMM y G},
				y => q{E, dd MMM y – E, dd MMM y G},
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
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
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
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
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
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, dd MMM – E, dd MMM y G},
				d => q{E, dd – E, dd MMM y G},
				y => q{E, dd MMM y – E, dd MMM y G},
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
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
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
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
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
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, dd MMM – E, dd MMM y},
				d => q{E, dd MMM – E, dd MMM y},
				y => q{E, dd MMM y – E, dd MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
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
		regionFormat => q(Ώρα ({0})),
		regionFormat => q(Θερινή ώρα ({0})),
		regionFormat => q(Χειμερινή ώρα ({0})),
		fallbackFormat => q([{1} ({0})]),
		'Afghanistan' => {
			long => {
				'standard' => q#Ώρα Αφγανιστάν#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Αμπιτζάν#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Άκρα#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Αντίς Αμπέμπα#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Αλγέρι#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Ασμάρα#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Μπαμάκο#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Μπανγκί#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Μπανζούλ#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Μπισάου#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Μπλαντάιρ#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Μπραζαβίλ#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Μπουζουμπούρα#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Κάιρο#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Καζαμπλάνκα#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Θέουτα#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Κόνακρι#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Ντακάρ#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Νταρ Ες Σαλάμ#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Τζιμπουτί#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Ντουάλα#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Ελ Αγιούν#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Φρίταουν#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Γκαμπορόνε#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Χαράρε#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Γιοχάνεσμπουργκ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Τζούμπα#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Καμπάλα#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Χαρτούμ#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Κιγκάλι#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Κινσάσα#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Λάγκος#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Λιμπρεβίλ#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Λομέ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Λουάντα#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Λουμπουμπάσι#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Λουζάκα#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Μαλάμπο#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Μαπούτο#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Μασέρου#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Μπαμπάνε#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Μογκαντίσου#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Μονρόβια#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Ναϊρόμπι#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ντζαμένα#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Νιαμέι#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Νουακσότ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ουαγκαντούγκου#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Πόρτο-Νόβο#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Σάο Τομέ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Τρίπολη#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Τύνιδα#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Βίντχουκ#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ώρα Κεντρικής Αφρικής#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ώρα Ανατολικής Αφρικής#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Χειμερινή ώρα Νότιας Αφρικής#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Θερινή ώρα Δυτικής Αφρικής#,
				'generic' => q#Ώρα Δυτικής Αφρικής#,
				'standard' => q#Χειμερινή ώρα Δυτικής Αφρικής#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Θερινή ώρα Αλάσκας#,
				'generic' => q#Ώρα Αλάσκας#,
				'standard' => q#Χειμερινή ώρα Αλάσκας#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Θερινή ώρα Αμαζονίου#,
				'generic' => q#Ώρα Αμαζονίου#,
				'standard' => q#Χειμερινή ώρα Αμαζονίου#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Άντακ#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Άνκορατζ#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Ανγκουίλα#,
		},
		'America/Antigua' => {
			exemplarCity => q#Αντίγκουα#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Αραγκουάινα#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Λα Ριόχα#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Ρίο Γκαγιέγκος#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Σάλτα#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Σαν Χουάν#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Σαν Λούις#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Τουκουμάν#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ουσουάια#,
		},
		'America/Aruba' => {
			exemplarCity => q#Αρούμπα#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Ασουνσιόν#,
		},
		'America/Bahia' => {
			exemplarCity => q#Μπαΐα#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Μπαΐα ντε Μπαντέρας#,
		},
		'America/Barbados' => {
			exemplarCity => q#Μπαρμπέιντος#,
		},
		'America/Belem' => {
			exemplarCity => q#Μπελέμ#,
		},
		'America/Belize' => {
			exemplarCity => q#Μπελίζ#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Μπλαν Σαμπλόν#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Μπόα Βίστα#,
		},
		'America/Bogota' => {
			exemplarCity => q#Μπογκοτά#,
		},
		'America/Boise' => {
			exemplarCity => q#Μπόιζι#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Μπουένος Άιρες#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Κέμπριτζ Μπέι#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Κάμπο Γκράντε#,
		},
		'America/Cancun' => {
			exemplarCity => q#Κανκούν#,
		},
		'America/Caracas' => {
			exemplarCity => q#Καράκας#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Καταμάρκα#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Καγιέν#,
		},
		'America/Cayman' => {
			exemplarCity => q#Κέιμαν#,
		},
		'America/Chicago' => {
			exemplarCity => q#Σικάγο#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Τσιουάουα#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Ατικόκαν#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Κόρδοβα#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Κόστα Ρίκα#,
		},
		'America/Creston' => {
			exemplarCity => q#Κρέστον#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Κουιαμπά#,
		},
		'America/Curacao' => {
			exemplarCity => q#Κουρασάο#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Ντανμαρκσάβν#,
		},
		'America/Dawson' => {
			exemplarCity => q#Ντόσον#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Ντόσον Κρικ#,
		},
		'America/Denver' => {
			exemplarCity => q#Ντένβερ#,
		},
		'America/Detroit' => {
			exemplarCity => q#Ντιτρόιτ#,
		},
		'America/Dominica' => {
			exemplarCity => q#Ντομίνικα#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Έντμοντον#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Εϊρουνεπέ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Ελ Σαλβαδόρ#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Φορτ Νέλσον#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Φορταλέζα#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Γκλέις Μπέι#,
		},
		'America/Godthab' => {
			exemplarCity => q#Νουούκ#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Γκους Μπέι#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Γκραντ Τουρκ#,
		},
		'America/Grenada' => {
			exemplarCity => q#Γρενάδα#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Γουαδελούπη#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Γουατεμάλα#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Γκουαγιακίλ#,
		},
		'America/Guyana' => {
			exemplarCity => q#Γουιάνα#,
		},
		'America/Halifax' => {
			exemplarCity => q#Χάλιφαξ#,
		},
		'America/Havana' => {
			exemplarCity => q#Αβάνα#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Ερμοσίγιο#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Νοξ, Ιντιάνα#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Μαρένγκο, Ιντιάνα#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Πίτερσμπεργκ, Ιντιάνα#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Τελ Σίτι, Ιντιάνα#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Βιβέι, Ιντιάνα#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Βανσέν, Ιντιάνα#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Γουίναμακ, Ιντιάνα#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Ιντιανάπολις#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Ινούβικ#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ικαλούιτ#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Τζαμάικα#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Χουχούι#,
		},
		'America/Juneau' => {
			exemplarCity => q#Τζούνο#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Μοντιτσέλο, Κεντάκι#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Κράλεντικ#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Λα Παζ#,
		},
		'America/Lima' => {
			exemplarCity => q#Λίμα#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Λος Άντζελες#,
		},
		'America/Louisville' => {
			exemplarCity => q#Λούιβιλ#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Μασεϊό#,
		},
		'America/Managua' => {
			exemplarCity => q#Μανάγκουα#,
		},
		'America/Manaus' => {
			exemplarCity => q#Μανάους#,
		},
		'America/Marigot' => {
			exemplarCity => q#Μαριγκό#,
		},
		'America/Martinique' => {
			exemplarCity => q#Μαρτινίκα#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Ματαμόρος#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Μαζατλάν#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Μεντόζα#,
		},
		'America/Menominee' => {
			exemplarCity => q#Μενομίνε#,
		},
		'America/Merida' => {
			exemplarCity => q#Μέριδα#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Μετλακάτλα#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Πόλη του Μεξικού#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Μικελόν#,
		},
		'America/Moncton' => {
			exemplarCity => q#Μόνκτον#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Μοντερέι#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Μοντεβιδέο#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Μονσεράτ#,
		},
		'America/Nassau' => {
			exemplarCity => q#Νασάου#,
		},
		'America/New_York' => {
			exemplarCity => q#Νέα Υόρκη#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Νιπιγκόν#,
		},
		'America/Nome' => {
			exemplarCity => q#Νόμε#,
		},
		'America/Noronha' => {
			exemplarCity => q#Νορόνια#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Μπέουλα, Βόρεια Ντακότα#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Σέντερ, Βόρεια Ντακότα#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Νιου Σέιλεμ, Βόρεια Ντακότα#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Οχινάγκα#,
		},
		'America/Panama' => {
			exemplarCity => q#Παναμάς#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Πανγκνίρτουνγκ#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Παραμαρίμπο#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Φοίνιξ#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Πορτ-ο-Πρενς#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Πορτ οφ Σπέιν#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Πόρτο Βέλιο#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Πουέρτο Ρίκο#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Πούντα Αρένας#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Ρέινι Ρίβερ#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Ράνκιν Ίνλετ#,
		},
		'America/Recife' => {
			exemplarCity => q#Ρεσίφε#,
		},
		'America/Regina' => {
			exemplarCity => q#Ρετζίνα#,
		},
		'America/Resolute' => {
			exemplarCity => q#Ρέζολουτ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Ρίο Μπράνκο#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Σάντα Ιζαμπέλ#,
		},
		'America/Santarem' => {
			exemplarCity => q#Σανταρέμ#,
		},
		'America/Santiago' => {
			exemplarCity => q#Σαντιάγκο#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Άγιος Δομίνικος#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Σάο Πάολο#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Σκορεσμπίσουντ#,
		},
		'America/Sitka' => {
			exemplarCity => q#Σίτκα#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Άγιος Βαρθολομαίος#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Σεν Τζονς#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Σεν Κιτς#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Αγία Λουκία#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Άγιος Θωμάς#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Άγιος Βικέντιος#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Σουίφτ Κάρεντ#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Τεγκουσιγκάλπα#,
		},
		'America/Thule' => {
			exemplarCity => q#Θούλη#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Θάντερ Μπέι#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Τιχουάνα#,
		},
		'America/Toronto' => {
			exemplarCity => q#Τορόντο#,
		},
		'America/Tortola' => {
			exemplarCity => q#Τορτόλα#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Βανκούβερ#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Γουάιτχορς#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Γουίνιπεγκ#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Γιακούτατ#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Γέλοουναϊφ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Κεντρική θερινή ώρα Βόρειας Αμερικής#,
				'generic' => q#Κεντρική ώρα Βόρειας Αμερικής#,
				'standard' => q#Κεντρική χειμερινή ώρα Βόρειας Αμερικής#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ανατολική θερινή ώρα Βόρειας Αμερικής#,
				'generic' => q#Ανατολική ώρα Βόρειας Αμερικής#,
				'standard' => q#Ανατολική χειμερινή ώρα Βόρειας Αμερικής#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ορεινή θερινή ώρα Βόρειας Αμερικής#,
				'generic' => q#Ορεινή ώρα Βόρειας Αμερικής#,
				'standard' => q#Ορεινή χειμερινή ώρα Βόρειας Αμερικής#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Θερινή ώρα Ειρηνικού#,
				'generic' => q#Ώρα Ειρηνικού#,
				'standard' => q#Χειμερινή ώρα Ειρηνικού#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Θερινή ώρα Αναντίρ#,
				'generic' => q#Ώρα Αναντίρ#,
				'standard' => q#Χειμερινή ώρα Αναντίρ#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Κάσεϊ#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Ντέιβις#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Ντιμόν ντ’ Ουρβίλ#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Μακουάρι#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Μόσον#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Μακμέρντο#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Πάλμερ#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Ρόθερα#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Σίοβα#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Τρολ#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Βόστοκ#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Θερινή ώρα Απία#,
				'generic' => q#Ώρα Απία#,
				'standard' => q#Χειμερινή ώρα Απία#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Αραβική θερινή ώρα#,
				'generic' => q#Αραβική ώρα#,
				'standard' => q#Αραβική χειμερινή ώρα#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Λόνγκιεαρμπιεν#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Θερινή ώρα Αργεντινής#,
				'generic' => q#Ώρα Αργεντινής#,
				'standard' => q#Χειμερινή ώρα Αργεντινής#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Θερινή ώρα Δυτικής Αργεντινής#,
				'generic' => q#Ώρα Δυτικής Αργεντινής#,
				'standard' => q#Χειμερινή ώρα Δυτικής Αργεντινής#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Θερινή ώρα Αρμενίας#,
				'generic' => q#Ώρα Αρμενίας#,
				'standard' => q#Χειμερινή ώρα Αρμενίας#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Άντεν#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Αλμάτι#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Αμμάν#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Αναντίρ#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Ακτάου#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Ακτόμπε#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ασχαμπάτ#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Aτιράου#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Βαγδάτη#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Μπαχρέιν#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Μπακού#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Μπανγκόκ#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Μπαρναούλ#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Βυρητός#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Μπισκέκ#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Μπρουνέι#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Καλκούτα#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Τσιτά#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Τσοϊμπαλσάν#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Κολόμπο#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Δαμασκός#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Ντάκα#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Ντίλι#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Ντουμπάι#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Ντουσάνμπε#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Αμμόχωστος#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Γάζα#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Χεβρώνα#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Χονγκ Κονγκ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Χοβντ#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Ιρκούτσκ#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Τζακάρτα#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Τζαγιαπούρα#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ιερουσαλήμ#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Καμπούλ#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Καμτσάτκα#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Καράτσι#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Κατμαντού#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Χαντίγκα#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Κρασνογιάρσκ#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Κουάλα Λουμπούρ#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Κουτσίνγκ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Κουβέιτ#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Μακάο#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Μαγκαντάν#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Μακασάρ#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Μανίλα#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Μασκάτ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Λευκωσία#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Νοβοκουζνέτσκ#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Νοβοσιμπίρσκ#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Ομσκ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Οράλ#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Πνομ Πενχ#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Πόντιανακ#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Πιονγκγιάνγκ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Κατάρ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Κιζιλορντά#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ρανγκούν#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Ριάντ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Πόλη Χο Τσι Μινχ#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Σαχαλίνη#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Σαμαρκάνδη#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Σεούλ#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Σανγκάη#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Σιγκαπούρη#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Σρεντνεκολίμσκ#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Ταϊπέι#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Τασκένδη#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Τιφλίδα#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Τεχεράνη#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Θίμφου#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Τόκιο#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Τομσκ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ουλάν Μπατόρ#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ουρούμτσι#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ουστ-Νερά#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Βιεντιάν#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Βλαδιβοστόκ#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Γιακούτσκ#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Αικατερινούπολη#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ερεβάν#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Θερινή ώρα Ατλαντικού#,
				'generic' => q#Ώρα Ατλαντικού#,
				'standard' => q#Χειμερινή ώρα Ατλαντικού#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Αζόρες#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Βερμούδες#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Κανάρια#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Πράσινο Ακρωτήριο#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Φερόες#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Μαδέρα#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Ρέυκιαβικ#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Νότια Γεωργία#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Αγ. Ελένη#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Στάνλεϊ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Αδελαΐδα#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Μπρισμπέιν#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Μπρόκεν Χιλ#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Κάρι#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Ντάργουιν#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Γιούκλα#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Χόμπαρτ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Λίντεμαν#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Λορντ Χάου#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Μελβούρνη#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Περθ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Σίδνεϊ#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Θερινή ώρα Κεντρικής Αυστραλίας#,
				'generic' => q#Ώρα Κεντρικής Αυστραλίας#,
				'standard' => q#Χειμερινή ώρα Κεντρικής Αυστραλίας#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Θερινή ώρα Κεντροδυτικής Αυστραλίας#,
				'generic' => q#Ώρα Κεντροδυτικής Αυστραλίας#,
				'standard' => q#Χειμερινή ώρα Κεντροδυτικής Αυστραλίας#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Θερινή ώρα Ανατολικής Αυστραλίας#,
				'generic' => q#Ώρα Ανατολικής Αυστραλίας#,
				'standard' => q#Χειμερινή ώρα Ανατολικής Αυστραλίας#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Θερινή ώρα Δυτικής Αυστραλίας#,
				'generic' => q#Ώρα Δυτικής Αυστραλίας#,
				'standard' => q#Χειμερινή ώρα Δυτικής Αυστραλίας#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Θερινή ώρα Αζερμπαϊτζάν#,
				'generic' => q#Ώρα Αζερμπαϊτζάν#,
				'standard' => q#Χειμερινή ώρα Αζερμπαϊτζάν#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Θερινή ώρα Αζορών#,
				'generic' => q#Ώρα Αζορών#,
				'standard' => q#Χειμερινή ώρα Αζορών#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Θερινή ώρα Μπανγκλαντές#,
				'generic' => q#Ώρα Μπανγκλαντές#,
				'standard' => q#Χειμερινή ώρα Μπανγκλαντές#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ώρα Μπουτάν#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ώρα Βολιβίας#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Θερινή ώρα Μπραζίλιας#,
				'generic' => q#Ώρα Μπραζίλιας#,
				'standard' => q#Χειμερινή ώρα Μπραζίλιας#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ώρα Μπρουνέι Νταρουσαλάμ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Θερινή ώρα Πράσινου Ακρωτηρίου#,
				'generic' => q#Ώρα Πράσινου Ακρωτηρίου#,
				'standard' => q#Χειμερινή ώρα Πράσινου Ακρωτηρίου#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ώρα Τσαμόρο#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Θερινή ώρα Τσάταμ#,
				'generic' => q#Ώρα Τσάταμ#,
				'standard' => q#Χειμερινή ώρα Τσάταμ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Θερινή ώρα Χιλής#,
				'generic' => q#Ώρα Χιλής#,
				'standard' => q#Χειμερινή ώρα Χιλής#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Θερινή ώρα Κίνας#,
				'generic' => q#Ώρα Κίνας#,
				'standard' => q#Χειμερινή ώρα Κίνας#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Θερινή ώρα Τσοϊμπαλσάν#,
				'generic' => q#Ώρα Τσοϊμπαλσάν#,
				'standard' => q#Χειμερινή ώρα Τσοϊμπαλσάν#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ώρα Νήσου Χριστουγέννων#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ώρα Νήσων Κόκος#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Θερινή ώρα Κολομβίας#,
				'generic' => q#Ώρα Κολομβίας#,
				'standard' => q#Χειμερινή ώρα Κολομβίας#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Θερινή ώρα Νήσων Κουκ#,
				'generic' => q#Ώρα Νήσων Κουκ#,
				'standard' => q#Χειμερινή ώρα Νήσων Κουκ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Θερινή ώρα Κούβας#,
				'generic' => q#Ώρα Κούβας#,
				'standard' => q#Χειμερινή ώρα Κούβας#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ώρα Ντέιβις#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ώρα Ντιμόν ντ’ Ουρβίλ#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ώρα Ανατολικού Τιμόρ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Θερινή ώρα Νήσου Πάσχα#,
				'generic' => q#Ώρα Νήσου Πάσχα#,
				'standard' => q#Χειμερινή ώρα Νήσου Πάσχα#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ώρα Ισημερινού#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Συντονισμένη Παγκόσμια Ώρα#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Άγνωστη πόλη#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Άμστερνταμ#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Ανδόρα#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Αστραχάν#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Αθήνα#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Βελιγράδι#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Βερολίνο#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Μπρατισλάβα#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Βρυξέλλες#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Βουκουρέστι#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Βουδαπέστη#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Μπίσινγκεν#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Κισινάου#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Κοπεγχάγη#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Δουβλίνο#,
			long => {
				'daylight' => q#Χειμερινή ώρα Ιρλανδίας#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Γιβραλτάρ#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Γκέρνζι#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Ελσίνκι#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Νήσος του Μαν#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Κωνσταντινούπολη#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Τζέρσεϊ#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Καλίνινγκραντ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Κίεβο#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Κίροφ#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Λισαβόνα#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Λιουμπλιάνα#,
		},
		'Europe/London' => {
			exemplarCity => q#Λονδίνο#,
			long => {
				'daylight' => q#Θερινή ώρα Βρετανίας#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Λουξεμβούργο#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Μαδρίτη#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Μάλτα#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Μάριεχαμν#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Μινσκ#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Μονακό#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Μόσχα#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Όσλο#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Παρίσι#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Ποντγκόριτσα#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Πράγα#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Ρίγα#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Ρώμη#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Σαμάρα#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Άγιος Μαρίνος#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Σαράγεβο#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Σαράτοφ#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Συμφερόπολη#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Σκόπια#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Σόφια#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Στοκχόλμη#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Ταλίν#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Τίρανα#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ουλιάνοφσκ#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ούζχοροντ#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Βαντούζ#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Βατικανό#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Βιέννη#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Βίλνιους#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Βόλγκοκραντ#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Βαρσοβία#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Ζάγκρεμπ#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Ζαπορόζιε#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Ζυρίχη#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Θερινή ώρα Κεντρικής Ευρώπης#,
				'generic' => q#Ώρα Κεντρικής Ευρώπης#,
				'standard' => q#Χειμερινή ώρα Κεντρικής Ευρώπης#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Θερινή ώρα Ανατολικής Ευρώπης#,
				'generic' => q#Ώρα Ανατολικής Ευρώπης#,
				'standard' => q#Χειμερινή ώρα Ανατολικής Ευρώπης#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ώρα περαιτέρω Ανατολικής Ευρώπης#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Θερινή ώρα Δυτικής Ευρώπης#,
				'generic' => q#Ώρα Δυτικής Ευρώπης#,
				'standard' => q#Χειμερινή ώρα Δυτικής Ευρώπης#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Θερινή ώρα Νήσων Φόκλαντ#,
				'generic' => q#Ώρα Νήσων Φόκλαντ#,
				'standard' => q#Χειμερινή ώρα Νήσων Φόκλαντ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Θερινή ώρα Φίτζι#,
				'generic' => q#Ώρα Φίτζι#,
				'standard' => q#Χειμερινή ώρα Φίτζι#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ώρα Γαλλικής Γουιάνας#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ώρα Γαλλικού Νότου και Ανταρκτικής#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Μέση ώρα Γκρίνουιτς#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ώρα Γκαλάπαγκος#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ώρα Γκάμπιερ#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Θερινή ώρα Γεωργίας#,
				'generic' => q#Ώρα Γεωργίας#,
				'standard' => q#Χειμερινή ώρα Γεωργίας#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ώρα Νήσων Γκίλμπερτ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Θερινή ώρα Ανατολικής Γροιλανδίας#,
				'generic' => q#Ώρα Ανατολικής Γροιλανδίας#,
				'standard' => q#Χειμερινή ώρα Ανατολικής Γροιλανδίας#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Θερινή ώρα Δυτικής Γροιλανδίας#,
				'generic' => q#Ώρα Δυτικής Γροιλανδίας#,
				'standard' => q#Χειμερινή ώρα Δυτικής Γροιλανδίας#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Ώρα Γκουάμ#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ώρα Κόλπου#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ώρα Γουιάνας#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Θερινή ώρα Χαβάης-Αλεούτιων Νήσων#,
				'generic' => q#Ώρα Χαβάης-Αλεούτιων Νήσων#,
				'standard' => q#Χειμερινή ώρα Χαβάης-Αλεούτιων Νήσων#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Θερινή ώρα Χονγκ Κονγκ#,
				'generic' => q#Ώρα Χονγκ Κονγκ#,
				'standard' => q#Χειμερινή ώρα Χονγκ Κονγκ#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Θερινή ώρα Χοβντ#,
				'generic' => q#Ώρα Χοβντ#,
				'standard' => q#Χειμερινή ώρα Χοβντ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ώρα Ινδίας#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Ανταναναρίβο#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Τσάγκος#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Νήσος Χριστουγέννων#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Κόκος#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Κομόρο#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Κεργκελέν#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Μάχε#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Μαλδίβες#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Μαυρίκιος#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Μαγιότ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Ρεϊνιόν#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ώρα Ινδικού Ωκεανού#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ώρα Ινδοκίνας#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ώρα Κεντρικής Ινδονησίας#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ώρα Ανατολικής Ινδονησίας#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ώρα Δυτικής Ινδονησίας#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Θερινή ώρα Ιράν#,
				'generic' => q#Ώρα Ιράν#,
				'standard' => q#Χειμερινή ώρα Ιράν#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Θερινή ώρα Ιρκούτσκ#,
				'generic' => q#Ώρα Ιρκούτσκ#,
				'standard' => q#Χειμερινή ώρα Ιρκούτσκ#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Θερινή ώρα Ισραήλ#,
				'generic' => q#Ώρα Ισραήλ#,
				'standard' => q#Χειμερινή ώρα Ισραήλ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Θερινή ώρα Ιαπωνίας#,
				'generic' => q#Ώρα Ιαπωνίας#,
				'standard' => q#Χειμερινή ώρα Ιαπωνίας#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Θερινή ώρα Πετροπαβλόβσκ-Καμτσάτσκι#,
				'generic' => q#Ώρα Καμτσάτκα#,
				'standard' => q#Χειμερινή ώρα Πετροπαβλόβσκ-Καμτσάτσκι#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ώρα Ανατολικού Καζακστάν#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ώρα Δυτικού Καζακστάν#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Θερινή ώρα Κορέας#,
				'generic' => q#Ώρα Κορέας#,
				'standard' => q#Χειμερινή ώρα Κορέας#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ώρα Κόσραϊ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Θερινή ώρα Κρασνογιάρσκ#,
				'generic' => q#Ώρα Κρασνογιάρσκ#,
				'standard' => q#Χειμερινή ώρα Κρασνογιάρσκ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ώρα Κιργιστάν#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ώρα Νήσων Λάιν#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Θερινή ώρα Λορντ Χάου#,
				'generic' => q#Ώρα Λορντ Χάου#,
				'standard' => q#Χειμερινή ώρα Λορντ Χάου#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Θερινή ώρα Μακάο#,
				'generic' => q#Ώρα Μακάο#,
				'standard' => q#Χειμερινή ώρα Μακάο#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Ώρα Νησιού Μακουάρι#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Θερινή ώρα Μαγκαντάν#,
				'generic' => q#Ώρα Μαγκαντάν#,
				'standard' => q#Χειμερινή ώρα Μαγκαντάν#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ώρα Μαλαισίας#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ώρα Μαλδίβων#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ώρα Μαρκέζας#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ώρα Νήσων Μάρσαλ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Θερινή ώρα Μαυρίκιου#,
				'generic' => q#Ώρα Μαυρίκιου#,
				'standard' => q#Χειμερινή ώρα Μαυρίκιου#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ώρα Μόσον#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Θερινή ώρα Βορειοδυτικού Μεξικού#,
				'generic' => q#Ώρα Βορειοδυτικού Μεξικού#,
				'standard' => q#Χειμερινή ώρα Βορειοδυτικού Μεξικού#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Θερινή ώρα Ειρηνικού Μεξικού#,
				'generic' => q#Ώρα Ειρηνικού Μεξικού#,
				'standard' => q#Χειμερινή ώρα Ειρηνικού Μεξικού#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Θερινή ώρα Ουλάν Μπατόρ#,
				'generic' => q#Ώρα Ουλάν Μπατόρ#,
				'standard' => q#Χειμερινή ώρα Ουλάν Μπατόρ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Θερινή ώρα Μόσχας#,
				'generic' => q#Ώρα Μόσχας#,
				'standard' => q#Χειμερινή ώρα Μόσχας#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ώρα Μιανμάρ#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ώρα Ναούρου#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ώρα Νεπάλ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Θερινή ώρα Νέας Καληδονίας#,
				'generic' => q#Ώρα Νέας Καληδονίας#,
				'standard' => q#Χειμερινή ώρα Νέας Καληδονίας#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Θερινή ώρα Νέας Ζηλανδίας#,
				'generic' => q#Ώρα Νέας Ζηλανδίας#,
				'standard' => q#Χειμερινή ώρα Νέας Ζηλανδίας#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Θερινή ώρα Νέας Γης#,
				'generic' => q#Ώρα Νέας Γης#,
				'standard' => q#Χειμερινή ώρα Νέας Γης#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ώρα Νιούε#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Ώρα Νήσου Νόρφολκ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Θερινή ώρα Φερνάρντο ντε Νορόνια#,
				'generic' => q#Ώρα Φερνάρντο ντε Νορόνια#,
				'standard' => q#Χειμερινή ώρα Φερνάρντο ντε Νορόνια#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Ώρα Νησιών Βόρειες Μαριάνες#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Θερινή ώρα Νοβοσιμπίρσκ#,
				'generic' => q#Ώρα Νοβοσιμπίρσκ#,
				'standard' => q#Χειμερινή ώρα Νοβοσιμπίρσκ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Θερινή ώρα Ομσκ#,
				'generic' => q#Ώρα Ομσκ#,
				'standard' => q#Χειμερινή ώρα Ομσκ#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Απία#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Όκλαντ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Μπουγκενβίλ#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Τσάταμ#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Νήσος Πάσχα#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Εφάτε#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Έντερμπερι#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Φακαόφο#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Φίτζι#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Φουναφούτι#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Γκαλάπαγκος#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Γκάμπιερ#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Γκουανταλκανάλ#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Γκουάμ#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Χονολουλού#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Τζόνστον#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Κιριτιμάτι#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Κόσραϊ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Κουατζαλέιν#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Ματζούρο#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Μαρκέζας#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Μίντγουεϊ#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Ναούρου#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Νιούε#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Νόρφολκ#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Νουμέα#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Πάγκο Πάγκο#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Παλάου#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Πίτκερν#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Πονάπε#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Πορτ Μόρεσμπι#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Ραροτόνγκα#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Σαϊπάν#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Ταϊτή#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Ταράουα#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Τονγκατάπου#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Τσουκ#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Γουέικ#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Γουάλις#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Θερινή ώρα Πακιστάν#,
				'generic' => q#Ώρα Πακιστάν#,
				'standard' => q#Χειμερινή ώρα Πακιστάν#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ώρα Παλάου#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ώρα Παπούας Νέας Γουινέας#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Θερινή ώρα Παραγουάης#,
				'generic' => q#Ώρα Παραγουάης#,
				'standard' => q#Χειμερινή ώρα Παραγουάης#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Θερινή ώρα Περού#,
				'generic' => q#Ώρα Περού#,
				'standard' => q#Χειμερινή ώρα Περού#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Θερινή ώρα Φιλιππινών#,
				'generic' => q#Ώρα Φιλιππινών#,
				'standard' => q#Χειμερινή ώρα Φιλιππινών#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ώρα Νήσων Φoίνιξ#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Θερινή ώρα Σεν Πιερ και Μικελόν#,
				'generic' => q#Ώρα Σεν Πιερ και Μικελόν#,
				'standard' => q#Χειμερινή ώρα Σεν Πιερ και Μικελόν#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ώρα Πίτκερν#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ώρα Πονάπε#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ώρα Πιονγιάνγκ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ώρα Ρεϊνιόν#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ώρα Ρόθερα#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Θερινή ώρα Σαχαλίνης#,
				'generic' => q#Ώρα Σαχαλίνης#,
				'standard' => q#Χειμερινή ώρα Σαχαλίνης#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Θερινή ώρα Σαμάρας#,
				'generic' => q#Ώρα Σάμαρας#,
				'standard' => q#Χειμερινή ώρα Σάμαρας#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Θερινή ώρα Σαμόα#,
				'generic' => q#Ώρα Σαμόα#,
				'standard' => q#Χειμερινή ώρα Σαμόα#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ώρα Σεϋχελλών#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ώρα Σιγκαπούρης#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ώρα Νήσων Σολομώντος#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ώρα Νότιας Γεωργίας#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ώρα Σουρινάμ#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ώρα Σίοβα#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ώρα Ταϊτής#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Θερινή ώρα Ταϊπέι#,
				'generic' => q#Ώρα Ταϊπέι#,
				'standard' => q#Χειμερινή ώρα Ταϊπέι#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ώρα Τατζικιστάν#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ώρα Τοκελάου#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Θερινή ώρα Τόνγκα#,
				'generic' => q#Ώρα Τόνγκα#,
				'standard' => q#Χειμερινή ώρα Τόνγκα#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ώρα Τσουκ#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Θερινή ώρα Τουρκμενιστάν#,
				'generic' => q#Ώρα Τουρκμενιστάν#,
				'standard' => q#Χειμερινή ώρα Τουρκμενιστάν#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ώρα Τουβαλού#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Θερινή ώρα Ουρουγουάης#,
				'generic' => q#Ώρα Ουρουγουάης#,
				'standard' => q#Χειμερινή ώρα Ουρουγουάης#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Θερινή ώρα Ουζμπεκιστάν#,
				'generic' => q#Ώρα Ουζμπεκιστάν#,
				'standard' => q#Χειμερινή ώρα Ουζμπεκιστάν#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Θερινή ώρα Βανουάτου#,
				'generic' => q#Ώρα Βανουάτου#,
				'standard' => q#Χειμερινή ώρα Βανουάτου#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ώρα Βενεζουέλας#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Θερινή ώρα Βλαδιβοστόκ#,
				'generic' => q#Ώρα Βλαδιβοστόκ#,
				'standard' => q#Χειμερινή ώρα Βλαδιβοστόκ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Θερινή ώρα Βόλγκογκραντ#,
				'generic' => q#Ώρα Βόλγκογκραντ#,
				'standard' => q#Χειμερινή ώρα Βόλγκογκραντ#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ώρα Βόστοκ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ώρα Νήσου Γουέικ#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ώρα Ουάλις και Φουτούνα#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Θερινή ώρα Γιακούτσκ#,
				'generic' => q#Ώρα Γιακούτσκ#,
				'standard' => q#Χειμερινή ώρα Γιακούτσκ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Θερινή ώρα Αικατερίνμπουργκ#,
				'generic' => q#Ώρα Αικατερίνμπουργκ#,
				'standard' => q#Χειμερινή ώρα Αικατερίνμπουργκ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
