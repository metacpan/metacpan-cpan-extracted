=encoding utf8

=head1

Locale::CLDR::Locales::Hr - Package for language Croatian

=cut

package Locale::CLDR::Locales::Hr;
# This file auto generated from Data\common\main\hr.xml
#	on Sun  7 Oct 10:36:27 am GMT

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-neuter','spellout-ordinal-feminine' ]},
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
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← zarez →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dvije),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ i →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ i →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ i →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ i →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ i →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ i →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ i →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ i →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvjesto[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tristo[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četiristo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petsto[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šeststo[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedamsto[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osamsto[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(devetsto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tisuću[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuće[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuća[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijun[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuna[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuna[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijarde[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijun[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuna[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuna[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijarde[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijardi[ →→]),
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
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← zarez →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedan),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dva),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četiri),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pet),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(šest),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sedam),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osam),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(devet),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deset),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(jedanaest),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dvanaest),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trinaest),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(četrnaest),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(petnaest),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(šesnaest),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sedamnaest),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(osamnaest),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(devetnaest),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ i →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ i →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ i →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ i →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ i →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ i →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ i →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ i →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvjesto[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tristo[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četiristo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petsto[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šeststo[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedamsto[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osamsto[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(devetsto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tisuću[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuće[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuća[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijun[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuna[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuna[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijarde[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijun[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuna[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuna[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijarde[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijardi[ →→]),
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
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← zarez →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dva),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ i →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ i →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ i →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ i →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ i →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ i →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ i →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ i →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvjesto[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tristo[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četiristo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petsto[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šeststo[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedamsto[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osamsto[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(devetsto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tisuću[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuće[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuća[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijun[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuna[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuna[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijarde[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milijardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijun[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuna[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuna[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijarde[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← bilijardi[ →→]),
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
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
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
		'spellout-ordinal-base' => {
			'private' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(prv),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(drug),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(treć),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četvrt),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pet),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(šest),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sedm),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osm),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(devet),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deset),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(st[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvest[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trist[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četrist[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petst[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šest[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedamst[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osamst[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(devetst[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tisuću[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuće[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisuću[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijun[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijuny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milijun[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijun[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijuny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijun[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
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
		'spellout-ordinal-feminine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=a),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=a),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=i),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=i),
				},
			},
		},
		'spellout-ordinal-neuter' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=o),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=e),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=o),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-base=o),
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
				'aa' => 'afarski',
 				'ab' => 'abhaski',
 				'ace' => 'ačinski',
 				'ach' => 'ačoli',
 				'ada' => 'adangme',
 				'ady' => 'adigejski',
 				'ae' => 'avestički',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainuski',
 				'ak' => 'akanski',
 				'akk' => 'akadski',
 				'ale' => 'aleutski',
 				'alt' => 'južni altai',
 				'am' => 'amharski',
 				'an' => 'aragonski',
 				'ang' => 'staroengleski',
 				'anp' => 'angika',
 				'ar' => 'arapski',
 				'ar_001' => 'moderni standardni arapski',
 				'arc' => 'aramejski',
 				'arn' => 'mapuche',
 				'arp' => 'arapaho',
 				'ars' => 'najdi arapski',
 				'arw' => 'aravački',
 				'as' => 'asamski',
 				'asa' => 'asu',
 				'ast' => 'asturijski',
 				'av' => 'avarski',
 				'awa' => 'awadhi',
 				'ay' => 'ajmarski',
 				'az' => 'azerbajdžanski',
 				'az@alt=short' => 'azerski',
 				'az_Arab' => 'južnoazerbajdžanski',
 				'ba' => 'baškirski',
 				'bal' => 'belučki',
 				'ban' => 'balijski',
 				'bas' => 'basa',
 				'bax' => 'bamunski',
 				'bbj' => 'ghomala',
 				'be' => 'bjeloruski',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'bugarski',
 				'bgn' => 'zapadnobaludžijski',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikolski',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bangla',
 				'bo' => 'tibetski',
 				'br' => 'bretonski',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosanski',
 				'bss' => 'akoose',
 				'bua' => 'burjatski',
 				'bug' => 'buginski',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'katalonski',
 				'cad' => 'caddo',
 				'car' => 'karipski',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ce' => 'čečenski',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'čibča',
 				'chg' => 'čagatajski',
 				'chk' => 'chuukese',
 				'chm' => 'marijski',
 				'chn' => 'chinook žargon',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'čerokijski',
 				'chy' => 'čejenski',
 				'ckb' => 'soranski kurdski',
 				'co' => 'korzički',
 				'cop' => 'koptski',
 				'cr' => 'cree',
 				'crh' => 'krimski turski',
 				'crs' => 'sejšelski kreolski',
 				'cs' => 'češki',
 				'csb' => 'kašupski',
 				'cu' => 'crkvenoslavenski',
 				'cv' => 'čuvaški',
 				'cy' => 'velški',
 				'da' => 'danski',
 				'dak' => 'dakota jezik',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'njemački',
 				'de_AT' => 'austrijski njemački',
 				'de_CH' => 'gornjonjemački (švicarski)',
 				'del' => 'delavarski',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'donjolužički',
 				'dua' => 'duala',
 				'dum' => 'srednjonizozemski',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'staroegipatski',
 				'eka' => 'ekajuk',
 				'el' => 'grčki',
 				'elx' => 'elamitski',
 				'en' => 'engleski',
 				'en_AU' => 'australski engleski',
 				'en_CA' => 'kanadski engleski',
 				'en_GB' => 'britanski engleski',
 				'en_GB@alt=short' => 'engleski (UK)',
 				'en_US' => 'američki engleski',
 				'en_US@alt=short' => 'engleski (SAD)',
 				'enm' => 'srednjoengleski',
 				'eo' => 'esperanto',
 				'es' => 'španjolski',
 				'es_419' => 'latinoamerički španjolski',
 				'es_ES' => 'europski španjolski',
 				'es_MX' => 'meksički španjolski',
 				'et' => 'estonski',
 				'eu' => 'baskijski',
 				'ewo' => 'ewondo',
 				'fa' => 'perzijski',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'finski',
 				'fil' => 'filipinski',
 				'fj' => 'fidžijski',
 				'fo' => 'ferojski',
 				'fon' => 'fon',
 				'fr' => 'francuski',
 				'fr_CA' => 'kanadski francuski',
 				'fr_CH' => 'švicarski francuski',
 				'frc' => 'kajunski francuski',
 				'frm' => 'srednjofrancuski',
 				'fro' => 'starofrancuski',
 				'frr' => 'sjevernofrizijski',
 				'frs' => 'istočnofrizijski',
 				'fur' => 'furlanski',
 				'fy' => 'zapadnofrizijski',
 				'ga' => 'irski',
 				'gaa' => 'ga',
 				'gag' => 'gagauski',
 				'gan' => 'gan kineski',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'škotski gaelski',
 				'gez' => 'geez',
 				'gil' => 'gilbertski',
 				'gl' => 'galicijski',
 				'gmh' => 'srednjogornjonjemački',
 				'gn' => 'gvaranski',
 				'goh' => 'starovisokonjemački',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotski',
 				'grb' => 'grebo',
 				'grc' => 'starogrčki',
 				'gsw' => 'švicarski njemački',
 				'gu' => 'gudžaratski',
 				'guz' => 'gusii',
 				'gv' => 'manski',
 				'gwi' => 'gwich’in',
 				'ha' => 'hausa',
 				'hai' => 'haidi',
 				'hak' => 'hakka kineski',
 				'haw' => 'havajski',
 				'he' => 'hebrejski',
 				'hi' => 'hindski',
 				'hil' => 'hiligaynonski',
 				'hit' => 'hetitski',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'hrvatski',
 				'hsb' => 'gornjolužički',
 				'hsn' => 'xiang kineski',
 				'ht' => 'haićanski kreolski',
 				'hu' => 'mađarski',
 				'hup' => 'hupa',
 				'hy' => 'armenski',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonezijski',
 				'ie' => 'interligua',
 				'ig' => 'igbo',
 				'ii' => 'sichuan ji',
 				'ik' => 'inupiaq',
 				'ilo' => 'iloko',
 				'inh' => 'ingušetski',
 				'io' => 'ido',
 				'is' => 'islandski',
 				'it' => 'talijanski',
 				'iu' => 'inuktitut',
 				'ja' => 'japanski',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'judejsko-perzijski',
 				'jrb' => 'judejsko-arapski',
 				'jv' => 'javanski',
 				'ka' => 'gruzijski',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'kabilski',
 				'kac' => 'kačinski',
 				'kaj' => 'kaje',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardinski',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'zelenortski',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'khasi',
 				'kho' => 'khotanese',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazaški',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalenjin',
 				'km' => 'kmerski',
 				'kmb' => 'kimbundu',
 				'kn' => 'karnatački',
 				'ko' => 'korejski',
 				'koi' => 'komi-permski',
 				'kok' => 'konkani',
 				'kos' => 'naurski',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'krl' => 'karelijski',
 				'kru' => 'kuruški',
 				'ks' => 'kašmirski',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kelnski',
 				'ku' => 'kurdski',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'kornski',
 				'ky' => 'kirgiski',
 				'la' => 'latinski',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luksemburški',
 				'lez' => 'lezgiški',
 				'lg' => 'ganda',
 				'li' => 'limburški',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laoski',
 				'lol' => 'mongo',
 				'lou' => 'lujzijanski kreolski',
 				'loz' => 'lozi',
 				'lrc' => 'sjevernolurski',
 				'lt' => 'litavski',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'luyia',
 				'lv' => 'latvijski',
 				'mad' => 'madurski',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masajski',
 				'mde' => 'maba',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauricijski kreolski',
 				'mg' => 'malgaški',
 				'mga' => 'srednjoirski',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'maršalski',
 				'mi' => 'maorski',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedonski',
 				'ml' => 'malajalamski',
 				'mn' => 'mongolski',
 				'mnc' => 'mandžurski',
 				'mni' => 'manipurski',
 				'moh' => 'mohok',
 				'mos' => 'mossi',
 				'mr' => 'marathski',
 				'ms' => 'malajski',
 				'mt' => 'malteški',
 				'mua' => 'mundang',
 				'mul' => 'više jezika',
 				'mus' => 'creek',
 				'mwl' => 'mirandski',
 				'mwr' => 'marwari',
 				'my' => 'burmanski',
 				'mye' => 'myene',
 				'myv' => 'mordvinski',
 				'mzn' => 'mazanderanski',
 				'na' => 'nauru',
 				'nan' => 'min nan kineski',
 				'nap' => 'napolitanski',
 				'naq' => 'nama',
 				'nb' => 'norveški bokmål',
 				'nd' => 'sjeverni ndebele',
 				'nds' => 'donjonjemački',
 				'nds_NL' => 'donjosaksonski',
 				'ne' => 'nepalski',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niujski',
 				'nl' => 'nizozemski',
 				'nl_BE' => 'flamanski',
 				'nmg' => 'kwasio',
 				'nn' => 'norveški nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norveški',
 				'nog' => 'nogajski',
 				'non' => 'staronorveški',
 				'nqo' => 'n’ko',
 				'nr' => 'južni ndebele',
 				'nso' => 'sjeverni sotski',
 				'nus' => 'nuerski',
 				'nv' => 'navajo',
 				'nwc' => 'klasični newari',
 				'ny' => 'njandža',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'okcitanski',
 				'oj' => 'ojibwa',
 				'om' => 'oromski',
 				'or' => 'orijski',
 				'os' => 'osetski',
 				'osa' => 'osage',
 				'ota' => 'turski - otomanski',
 				'pa' => 'pandžapski',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauanski',
 				'pcm' => 'nigerijski pidžin',
 				'peo' => 'staroperzijski',
 				'phn' => 'fenički',
 				'pi' => 'pali',
 				'pl' => 'poljski',
 				'pon' => 'pohnpeian',
 				'prg' => 'pruski',
 				'pro' => 'staroprovansalski',
 				'ps' => 'paštunski',
 				'ps@alt=variant' => 'puštu',
 				'pt' => 'portugalski',
 				'pt_BR' => 'brazilski portugalski',
 				'pt_PT' => 'europski portugalski',
 				'qu' => 'kečuanski',
 				'quc' => 'kiče',
 				'raj' => 'rajasthani',
 				'rap' => 'rapa nui',
 				'rar' => 'rarotonški',
 				'rm' => 'retoromanski',
 				'rn' => 'rundi',
 				'ro' => 'rumunjski',
 				'ro_MD' => 'moldavski',
 				'rof' => 'rombo',
 				'rom' => 'romski',
 				'root' => 'korijenski',
 				'ru' => 'ruski',
 				'rup' => 'aromunski',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrtski',
 				'sad' => 'sandawe',
 				'sah' => 'jakutski',
 				'sam' => 'samarijanski aramejski',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santalski',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardski',
 				'scn' => 'sicilijski',
 				'sco' => 'škotski',
 				'sd' => 'sindski',
 				'sdh' => 'južnokurdski',
 				'se' => 'sjeverni sami',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sel' => 'selkupski',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'staroirski',
 				'sh' => 'srpsko-hrvatski',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'čadski arapski',
 				'si' => 'sinhaleški',
 				'sid' => 'sidamo',
 				'sk' => 'slovački',
 				'sl' => 'slovenski',
 				'sm' => 'samoanski',
 				'sma' => 'južni sami',
 				'smj' => 'lule sami',
 				'smn' => 'inari sami',
 				'sms' => 'skolt sami',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somalski',
 				'sog' => 'sogdien',
 				'sq' => 'albanski',
 				'sr' => 'srpski',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'svati',
 				'ssy' => 'saho',
 				'st' => 'sesotski',
 				'su' => 'sundanski',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerski',
 				'sv' => 'švedski',
 				'sw' => 'svahili',
 				'sw_CD' => 'kongoanski svahili',
 				'swb' => 'komorski',
 				'syc' => 'klasični sirski',
 				'syr' => 'sirijski',
 				'ta' => 'tamilski',
 				'te' => 'teluški',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadžički',
 				'th' => 'tajlandski',
 				'ti' => 'tigrinja',
 				'tig' => 'tigriški',
 				'tiv' => 'tiv',
 				'tk' => 'turkmenski',
 				'tkl' => 'tokelaunski',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonski',
 				'tli' => 'tlingit',
 				'tmh' => 'tamašečki',
 				'tn' => 'cvana',
 				'to' => 'tonganski',
 				'tog' => 'nyasa tonga',
 				'tpi' => 'tok pisin',
 				'tr' => 'turski',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatarski',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluanski',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahićanski',
 				'tyv' => 'tuvinski',
 				'tzm' => 'tamašek (Srednji Atlas)',
 				'udm' => 'udmurtski',
 				'ug' => 'ujgurski',
 				'uga' => 'ugaritski',
 				'uk' => 'ukrajinski',
 				'umb' => 'umbundu',
 				'und' => 'nepoznati jezik',
 				'ur' => 'urdski',
 				'uz' => 'uzbečki',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vijetnamski',
 				'vo' => 'volapük',
 				'vot' => 'votski',
 				'vun' => 'vunjo',
 				'wa' => 'valonski',
 				'wae' => 'walserski',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'volof',
 				'wuu' => 'wu kineski',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'japski',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jidiš',
 				'yo' => 'jorupski',
 				'yue' => 'kantonski',
 				'za' => 'zhuang',
 				'zap' => 'zapotečki',
 				'zbl' => 'Blissovi simboli',
 				'zen' => 'zenaga',
 				'zgh' => 'standardni marokanski tamašek',
 				'zh' => 'kineski',
 				'zh_Hans' => 'kineski (pojednostavljeni)',
 				'zh_Hant' => 'kineski (tradicionalni)',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'bez jezičnog sadržaja',
 				'zza' => 'zazaki',

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
			'Afak' => 'afaka pismo',
 			'Arab' => 'arapsko pismo',
 			'Arab@alt=variant' => 'perzijsko-arapsko pismo',
 			'Armi' => 'aramejsko pismo',
 			'Armn' => 'armensko pismo',
 			'Avst' => 'avestansko pismo',
 			'Bali' => 'balijsko pismo',
 			'Bamu' => 'bamum pismo',
 			'Bass' => 'bassa vah pismo',
 			'Batk' => 'batak pismo',
 			'Beng' => 'bengalsko pismo',
 			'Blis' => 'blissymbols',
 			'Bopo' => 'bopomofo pismo',
 			'Brah' => 'brahmi pismo',
 			'Brai' => 'brajica',
 			'Bugi' => 'buginsko pismo',
 			'Buhd' => 'buhid pismo',
 			'Cakm' => 'chakma pismo',
 			'Cans' => 'unificirani kanadski aboriđinski slogovi',
 			'Cari' => 'karijsko pismo',
 			'Cham' => 'čamsko pismo',
 			'Cher' => 'čeroki pismo',
 			'Cirt' => 'cirth pismo',
 			'Copt' => 'koptsko pismo',
 			'Cprt' => 'cypriot pismo',
 			'Cyrl' => 'ćirilica',
 			'Cyrs' => 'staroslavenska crkvena čirilica',
 			'Deva' => 'devangari pismo',
 			'Dsrt' => 'deseret pismo',
 			'Egyd' => 'egipatsko narodno pismo',
 			'Egyh' => 'egipatsko hijeratsko pismo',
 			'Egyp' => 'egipatski hijeroglifi',
 			'Ethi' => 'etiopsko pismo',
 			'Geok' => 'gruzijsko khutsuri pismo',
 			'Geor' => 'gruzijsko pismo',
 			'Glag' => 'glagoljica',
 			'Goth' => 'gotičko pismo',
 			'Gran' => 'grantha pismo',
 			'Grek' => 'grčko pismo',
 			'Gujr' => 'gudžaratsko pismo',
 			'Guru' => 'gurmukhi pismo',
 			'Hanb' => 'hanb pismo',
 			'Hang' => 'hangul pismo',
 			'Hani' => 'hansko pismo',
 			'Hano' => 'hanunoo pismo',
 			'Hans' => 'pojednostavljeno pismo',
 			'Hans@alt=stand-alone' => 'pojednostavljeno hansko pismo',
 			'Hant' => 'tradicionalno pismo',
 			'Hant@alt=stand-alone' => 'tradicionalno hansko pismo',
 			'Hebr' => 'hebrejsko pismo',
 			'Hira' => 'hiragana pismo',
 			'Hluw' => 'anatolijski hijeroglifi',
 			'Hmng' => 'pahawh hmong pismo',
 			'Hrkt' => 'japansko slogovno pismo',
 			'Hung' => 'staro mađarsko pismo',
 			'Inds' => 'indijsko pismo',
 			'Ital' => 'staro talijansko pismo',
 			'Jamo' => 'jamo pismo',
 			'Java' => 'javansko pismo',
 			'Jpan' => 'japansko pismo',
 			'Jurc' => 'jurchen pismo',
 			'Kali' => 'kayah li pismo',
 			'Kana' => 'katakana pismo',
 			'Khar' => 'kharoshthi pismo',
 			'Khmr' => 'kmersko pismo',
 			'Khoj' => 'khojki pismo',
 			'Knda' => 'kannada pismo',
 			'Kore' => 'korejsko pismo',
 			'Kpel' => 'kpelle pismo',
 			'Kthi' => 'kaithi pismo',
 			'Lana' => 'lanna pismo',
 			'Laoo' => 'laosko pismo',
 			'Latf' => 'fraktur latinica',
 			'Latg' => 'keltska latinica',
 			'Latn' => 'latinica',
 			'Lepc' => 'lepcha pismo',
 			'Limb' => 'limbu pismo',
 			'Lina' => 'linear A pismo',
 			'Linb' => 'linear B pismo',
 			'Lisu' => 'fraser pismo',
 			'Loma' => 'loma pismo',
 			'Lyci' => 'likijsko pismo',
 			'Lydi' => 'lidijsko pismo',
 			'Mand' => 'mandai pismo',
 			'Mani' => 'manihejsko pismo',
 			'Maya' => 'majanski hijeroglifi',
 			'Mend' => 'mende pismo',
 			'Merc' => 'meroitski kurziv',
 			'Mero' => 'meroitic pismo',
 			'Mlym' => 'malajalamsko pismo',
 			'Mong' => 'mongolsko pismo',
 			'Moon' => 'moon pismo',
 			'Mroo' => 'mro pismo',
 			'Mtei' => 'meitei mayek pismo',
 			'Mymr' => 'mjanmarsko pismo',
 			'Narb' => 'staro sjevernoarapsko pismo',
 			'Nbat' => 'nabatejsko pismo',
 			'Nkgb' => 'naxi geba pismo',
 			'Nkoo' => 'n’ko pismo',
 			'Nshu' => 'nushu pismo',
 			'Ogam' => 'ogham pismo',
 			'Olck' => 'ol chiki pismo',
 			'Orkh' => 'orkhon pismo',
 			'Orya' => 'orijsko pismo',
 			'Osma' => 'osmanya pismo',
 			'Palm' => 'palmyrene pismo',
 			'Perm' => 'staro permic pismo',
 			'Phag' => 'phags-pa pismo',
 			'Phli' => 'pisani pahlavi',
 			'Phlp' => 'psalter pahlavi',
 			'Phlv' => 'pahlavi pismo',
 			'Phnx' => 'feničko pismo',
 			'Plrd' => 'pollard fonetsko pismo',
 			'Prti' => 'pisani parthian',
 			'Rjng' => 'rejang pismo',
 			'Roro' => 'rongorongo pismo',
 			'Runr' => 'runsko pismo',
 			'Samr' => 'samaritansko pismo',
 			'Sara' => 'sarati pismo',
 			'Sarb' => 'staro južnoarapsko pismo',
 			'Saur' => 'saurashtra pismo',
 			'Sgnw' => 'znakovno pismo',
 			'Shaw' => 'shavian pismo',
 			'Shrd' => 'sharada pismo',
 			'Sind' => 'khudawadi pismo',
 			'Sinh' => 'sinhaleško pismo',
 			'Sora' => 'sora sompeng pismo',
 			'Sund' => 'sundansko pismo',
 			'Sylo' => 'syloti nagri pismo',
 			'Syrc' => 'sirijsko pismo',
 			'Syre' => 'sirijsko estrangelo pismo',
 			'Syrj' => 'pismo zapadne Sirije',
 			'Syrn' => 'pismo istočne Sirije',
 			'Tagb' => 'tagbanwa pismo',
 			'Takr' => 'takri pismo',
 			'Tale' => 'tai le pismo',
 			'Talu' => 'novo tai lue pismo',
 			'Taml' => 'tamilsko pismo',
 			'Tang' => 'tangut pismo',
 			'Tavt' => 'tai viet pismo',
 			'Telu' => 'teluško pismo',
 			'Teng' => 'tengwar pismo',
 			'Tfng' => 'tifinar',
 			'Tglg' => 'tagalog pismo',
 			'Thaa' => 'thaana pismo',
 			'Thai' => 'tajsko pismo',
 			'Tibt' => 'tibetansko pismo',
 			'Tirh' => 'tirhuta pismo',
 			'Ugar' => 'ugaritsko pismo',
 			'Vaii' => 'vai pismo',
 			'Visp' => 'Visible Speech',
 			'Wara' => 'varang kshiti pismo',
 			'Wole' => 'woleai pismo',
 			'Xpeo' => 'staro perzijsko pismo',
 			'Xsux' => 'sumersko-akadsko cuneiform pismo',
 			'Yiii' => 'Yi pismo',
 			'Zinh' => 'nasljedno pismo',
 			'Zmth' => 'matematičko znakovlje',
 			'Zsye' => 'emotikoni',
 			'Zsym' => 'simboli',
 			'Zxxx' => 'jezik bez pismenosti',
 			'Zyyy' => 'zajedničko pismo',
 			'Zzzz' => 'nepoznato pismo',

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
			'001' => 'Svijet',
 			'002' => 'Afrika',
 			'003' => 'Sjevernoamerički kontinent',
 			'005' => 'Južna Amerika',
 			'009' => 'Oceanija',
 			'011' => 'Zapadna Afrika',
 			'013' => 'Centralna Amerika',
 			'014' => 'Istočna Afrika',
 			'015' => 'Sjeverna Afrika',
 			'017' => 'Središnja Afrika',
 			'018' => 'Južna Afrika',
 			'019' => 'Amerike',
 			'021' => 'Sjeverna Amerika',
 			'029' => 'Karibi',
 			'030' => 'Istočna Azija',
 			'034' => 'Južna Azija',
 			'035' => 'Jugoistočna Azija',
 			'039' => 'Južna Europa',
 			'053' => 'Australazija',
 			'054' => 'Melanezija',
 			'057' => 'Mikronezijsko područje',
 			'061' => 'Polinezija',
 			'142' => 'Azija',
 			'143' => 'Srednja Azija',
 			'145' => 'Zapadna Azija',
 			'150' => 'Europa',
 			'151' => 'Istočna Europa',
 			'154' => 'Sjeverna Europa',
 			'155' => 'Zapadna Europa',
 			'202' => 'Subsaharska Afrika',
 			'419' => 'Latinska Amerika',
 			'AC' => 'Otok Ascension',
 			'AD' => 'Andora',
 			'AE' => 'Ujedinjeni Arapski Emirati',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigva i Barbuda',
 			'AI' => 'Angvila',
 			'AL' => 'Albanija',
 			'AM' => 'Armenija',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentina',
 			'AS' => 'Američka Samoa',
 			'AT' => 'Austrija',
 			'AU' => 'Australija',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandski otoci',
 			'AZ' => 'Azerbajdžan',
 			'BA' => 'Bosna i Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgija',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bugarska',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermudi',
 			'BN' => 'Brunej',
 			'BO' => 'Bolivija',
 			'BQ' => 'Karipski otoci Nizozemske',
 			'BR' => 'Brazil',
 			'BS' => 'Bahami',
 			'BT' => 'Butan',
 			'BV' => 'Otok Bouvet',
 			'BW' => 'Bocvana',
 			'BY' => 'Bjelorusija',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosovi (Keelingovi) otoci',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Kongo (DRK)',
 			'CF' => 'Srednjoafrička Republika',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (RK)',
 			'CH' => 'Švicarska',
 			'CI' => 'Obala Bjelokosti',
 			'CI@alt=variant' => 'Bjelokosna Obala',
 			'CK' => 'Cookovi Otoci',
 			'CL' => 'Čile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Kolumbija',
 			'CP' => 'Otok Clipperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Zelenortska Republika',
 			'CW' => 'Curaçao',
 			'CX' => 'Božićni otok',
 			'CY' => 'Cipar',
 			'CZ' => 'Češka',
 			'CZ@alt=variant' => 'Češka Republika',
 			'DE' => 'Njemačka',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Džibuti',
 			'DK' => 'Danska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikanska Republika',
 			'DZ' => 'Alžir',
 			'EA' => 'Ceuta i Melilla',
 			'EC' => 'Ekvador',
 			'EE' => 'Estonija',
 			'EG' => 'Egipat',
 			'EH' => 'Zapadna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Španjolska',
 			'ET' => 'Etiopija',
 			'EU' => 'Europska unija',
 			'EZ' => 'eurozona',
 			'FI' => 'Finska',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandski otoci',
 			'FK@alt=variant' => 'Falklandski otoci (Malvini)',
 			'FM' => 'Mikronezija',
 			'FO' => 'Farski otoci',
 			'FR' => 'Francuska',
 			'GA' => 'Gabon',
 			'GB' => 'Ujedinjeno Kraljevstvo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzija',
 			'GF' => 'Francuska Gijana',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grenland',
 			'GM' => 'Gambija',
 			'GN' => 'Gvineja',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Ekvatorska Gvineja',
 			'GR' => 'Grčka',
 			'GS' => 'Južna Georgija i Južni Sendvički Otoci',
 			'GT' => 'Gvatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gvineja Bisau',
 			'GY' => 'Gvajana',
 			'HK' => 'PUP Hong Kong Kina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Otoci Heard i McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Hrvatska',
 			'HT' => 'Haiti',
 			'HU' => 'Mađarska',
 			'IC' => 'Kanarski otoci',
 			'ID' => 'Indonezija',
 			'IE' => 'Irska',
 			'IL' => 'Izrael',
 			'IM' => 'Otok Man',
 			'IN' => 'Indija',
 			'IO' => 'Britanski Indijskooceanski teritorij',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italija',
 			'JE' => 'Jersey',
 			'JM' => 'Jamajka',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenija',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komori',
 			'KN' => 'Sveti Kristofor i Nevis',
 			'KP' => 'Sjeverna Koreja',
 			'KR' => 'Južna Koreja',
 			'KW' => 'Kuvajt',
 			'KY' => 'Kajmanski otoci',
 			'KZ' => 'Kazahstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Sveta Lucija',
 			'LI' => 'Lihtenštajn',
 			'LK' => 'Šri Lanka',
 			'LR' => 'Liberija',
 			'LS' => 'Lesoto',
 			'LT' => 'Litva',
 			'LU' => 'Luksemburg',
 			'LV' => 'Latvija',
 			'LY' => 'Libija',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavija',
 			'ME' => 'Crna Gora',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Maršalovi Otoci',
 			'MK' => 'Makedonija',
 			'MK@alt=variant' => 'Makedonija (BJRM)',
 			'ML' => 'Mali',
 			'MM' => 'Mjanmar (Burma)',
 			'MN' => 'Mongolija',
 			'MO' => 'PUP Makao Kina',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Sjevernomarijanski otoci',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanija',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricijus',
 			'MV' => 'Maldivi',
 			'MW' => 'Malavi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malezija',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibija',
 			'NC' => 'Nova Kaledonija',
 			'NE' => 'Niger',
 			'NF' => 'Otok Norfolk',
 			'NG' => 'Nigerija',
 			'NI' => 'Nikaragva',
 			'NL' => 'Nizozemska',
 			'NO' => 'Norveška',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Novi Zeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francuska Polinezija',
 			'PG' => 'Papua Nova Gvineja',
 			'PH' => 'Filipini',
 			'PK' => 'Pakistan',
 			'PL' => 'Poljska',
 			'PM' => 'Sveti Petar i Mikelon',
 			'PN' => 'Otoci Pitcairn',
 			'PR' => 'Portoriko',
 			'PS' => 'Palestinsko područje',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paragvaj',
 			'QA' => 'Katar',
 			'QO' => 'Vanjska područja Oceanije',
 			'RE' => 'Réunion',
 			'RO' => 'Rumunjska',
 			'RS' => 'Srbija',
 			'RU' => 'Rusija',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudijska Arabija',
 			'SB' => 'Salomonski Otoci',
 			'SC' => 'Sejšeli',
 			'SD' => 'Sudan',
 			'SE' => 'Švedska',
 			'SG' => 'Singapur',
 			'SH' => 'Sveta Helena',
 			'SI' => 'Slovenija',
 			'SJ' => 'Svalbard i Jan Mayen',
 			'SK' => 'Slovačka',
 			'SL' => 'Sijera Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinam',
 			'SS' => 'Južni Sudan',
 			'ST' => 'Sveti Toma i Princip',
 			'SV' => 'Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sirija',
 			'SZ' => 'Svazi',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Otoci Turks i Caicos',
 			'TD' => 'Čad',
 			'TF' => 'Francuski južni i antarktički teritoriji',
 			'TG' => 'Togo',
 			'TH' => 'Tajland',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Istočni Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunis',
 			'TO' => 'Tonga',
 			'TR' => 'Turska',
 			'TT' => 'Trinidad i Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tajvan',
 			'TZ' => 'Tanzanija',
 			'UA' => 'Ukrajina',
 			'UG' => 'Uganda',
 			'UM' => 'Mali udaljeni otoci SAD-a',
 			'UN' => 'Ujedinjeni narodi',
 			'UN@alt=short' => 'UN',
 			'US' => 'Sjedinjene Američke Države',
 			'US@alt=short' => 'SAD',
 			'UY' => 'Urugvaj',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikanski Grad',
 			'VC' => 'Sveti Vincent i Grenadini',
 			'VE' => 'Venezuela',
 			'VG' => 'Britanski Djevičanski otoci',
 			'VI' => 'Američki Djevičanski otoci',
 			'VN' => 'Vijetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis i Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Južnoafrička Republika',
 			'ZM' => 'Zambija',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'nepoznato područje',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'tradicionalan njemački pravopis',
 			'1994' => 'standardizirani resian pravopis',
 			'1996' => 'njemačka ortografija iz 1996.',
 			'1606NICT' => 'kasni srednjofrancuski do 1606.',
 			'1694ACAD' => 'rani moderni francuski',
 			'1959ACAD' => 'akademski',
 			'ALUKU' => 'aluku dijalekt',
 			'AREVELA' => 'istočno-armenijski',
 			'AREVMDA' => 'zapadno-armenijski',
 			'BAKU1926' => 'unificirana turska abeceda',
 			'BISKE' => 'san giorgio/bila dijalekt',
 			'BOONT' => 'boontling',
 			'EMODENG' => 'rani moderni engleski',
 			'FONIPA' => 'IPA fonetika',
 			'FONUPA' => 'UPA fonetika',
 			'KKCOR' => 'Uobičajeni pravopis',
 			'KSCOR' => 'standardna ortografija',
 			'LIPAW' => 'lipovački dijalekt resian jezika',
 			'METELKO' => 'metelčica',
 			'MONOTON' => 'monotono',
 			'NEDIS' => 'natisone dijalekt',
 			'NJIVA' => 'Gniva/Njiva dijalekt',
 			'NULIK' => 'moderni volapuk',
 			'OSOJS' => 'oseacco/osojane dijalekt',
 			'PAMAKA' => 'pamaka dijalekt',
 			'PINYIN' => 'Pinyin romanizacija',
 			'POLYTON' => 'politono',
 			'POSIX' => 'Računalo',
 			'REVISED' => 'izmijenjen pravopis',
 			'ROZAJ' => 'resian',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'škotski standardni engleski',
 			'SCOUSE' => 'scouse',
 			'SOLBA' => 'stolvizza/solbica dijalekt',
 			'TARASK' => 'taraskievica pravopis',
 			'UCCOR' => 'ujednačena ortografija',
 			'UCRCOR' => 'ujednačena revidirana ortografija',
 			'VALENCIA' => 'valencijski',
 			'WADEGILE' => 'Wade-Giles romanizacija',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'kalendar',
 			'cf' => 'Format valute',
 			'colalternate' => 'Zanemarivanje poredavanja simbola',
 			'colbackwards' => 'Obrnuto poredavanje po naglasku',
 			'colcasefirst' => 'Poredavanje po velikim/malim slovima',
 			'colcaselevel' => 'Poredavanje u skladu s veličinom slova',
 			'collation' => 'Redoslijed razvrstavanja',
 			'colnormalization' => 'Normalizirano poredavanje',
 			'colnumeric' => 'Numeričko poredavanje',
 			'colstrength' => 'Jačina poredavanja',
 			'currency' => 'valuta',
 			'hc' => 'format vremena (12 ili 24)',
 			'lb' => 'stil prijeloma retka',
 			'ms' => 'sustav mjernih jedinica',
 			'numbers' => 'brojevi',
 			'timezone' => 'Vremenska zona',
 			'va' => 'Varijanta zemlje/jezika',
 			'x' => 'Privatna upotreba',

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
 				'buddhist' => q{budistički kalendar},
 				'chinese' => q{kineski kalendar},
 				'coptic' => q{Koptski kalendar},
 				'dangi' => q{dangi kalendar},
 				'ethiopic' => q{etiopski kalendar},
 				'ethiopic-amete-alem' => q{Etiopski kalendar "Amete Alem"},
 				'gregorian' => q{gregorijanski kalendar},
 				'hebrew' => q{hebrejski kalendar},
 				'indian' => q{indijski nacionalni kalendar},
 				'islamic' => q{islamski kalendar},
 				'islamic-civil' => q{islamski civilni kalendar},
 				'islamic-umalqura' => q{islamski kalendar (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 kalendar},
 				'japanese' => q{japanski kalendar},
 				'persian' => q{perzijski kalendar},
 				'roc' => q{kalendar Republike Kine},
 			},
 			'cf' => {
 				'account' => q{Računovodstveni format valute},
 				'standard' => q{Standardni format valute},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Poredaj simbole},
 				'shifted' => q{Poredaj zanemarujući simbole},
 			},
 			'colbackwards' => {
 				'no' => q{Poredaj naglaske normalno},
 				'yes' => q{Poredaj naglaske obrnuto},
 			},
 			'colcasefirst' => {
 				'lower' => q{Prvo poredaj mala slova},
 				'no' => q{Poredaj po normalnom poretku veličine slova},
 				'upper' => q{Poredaj prvo velika slova},
 			},
 			'colcaselevel' => {
 				'no' => q{Poredaj zanemarujući veličinu},
 				'yes' => q{Poredaj u skladu s veličinom slova},
 			},
 			'collation' => {
 				'big5han' => q{razvrstavanje prema tradicionalnom kineskom - Big5},
 				'compat' => q{Prethodni redoslijed razvrstavanja, radi kompatibilnosti},
 				'dictionary' => q{rječničko razvrstavanje},
 				'ducet' => q{Standardno Unicode razvrstavanje},
 				'eor' => q{Europska pravila razvrstavanja},
 				'gb2312han' => q{razvrstavanje prema pojednostavljenom kineskom - GB2312},
 				'phonebook' => q{razvrstavanje po abecedi},
 				'phonetic' => q{Fonetski poredak},
 				'pinyin' => q{Pinyin razvrstavanje},
 				'reformed' => q{reformirano razvrstavanje},
 				'search' => q{Općenito pretraživanje},
 				'searchjl' => q{Pretraživanje po početnom suglasniku hangula},
 				'standard' => q{Standardno razvrstavanje},
 				'stroke' => q{razvrstavanje po redoslijedu poteza za kineski},
 				'traditional' => q{tradicionalno razvrstavanje},
 				'unihan' => q{razvrstavanje prema korijenu i potezu},
 				'zhuyin' => q{zhuyin razvrstavanje},
 			},
 			'colnormalization' => {
 				'no' => q{Poredaj bez normalizacije},
 				'yes' => q{Poredaj unikod normalizirano},
 			},
 			'colnumeric' => {
 				'no' => q{Poredaj znamenke pojedinačno},
 				'yes' => q{Poredaj znamenke numerički},
 			},
 			'colstrength' => {
 				'identical' => q{Poredaj sve},
 				'primary' => q{Poredaj samo po osnovnim slovima},
 				'quaternary' => q{Poredaj po naglascima/veličini/širini/pismu kana},
 				'secondary' => q{Poredaj po naglasku},
 				'tertiary' => q{Poredaj po naglascima/veličini/širini},
 			},
 			'd0' => {
 				'fwidth' => q{Široki},
 				'hwidth' => q{Uski},
 				'npinyin' => q{Numerički},
 			},
 			'hc' => {
 				'h11' => q{12-satni format (0-11)},
 				'h12' => q{12-satni format (1-12)},
 				'h23' => q{24-satni format (0-23)},
 				'h24' => q{24-satni format (1-24)},
 			},
 			'lb' => {
 				'loose' => q{slobodni stil prijeloma retka},
 				'normal' => q{normalni stil prijeloma retka},
 				'strict' => q{strogi stil prijeloma retka},
 			},
 			'm0' => {
 				'bgn' => q{transliteracija prema BGN-u},
 				'ungegn' => q{transliteracija prema UNGEGN-u},
 			},
 			'ms' => {
 				'metric' => q{metrički sustav},
 				'uksystem' => q{imperijalni sustav mjera},
 				'ussystem' => q{američki sustav mjera},
 			},
 			'numbers' => {
 				'arab' => q{arapsko-indijske znamenke},
 				'arabext' => q{proširene arapsko-indijske znamenke},
 				'armn' => q{armenski brojevi},
 				'armnlow' => q{mali armenski brojevi},
 				'beng' => q{znamenke bengalskog pisma},
 				'deva' => q{znamenke pisma devanagari},
 				'ethi' => q{etiopski brojevi},
 				'finance' => q{Financijski brojevi},
 				'fullwide' => q{široke znamenke},
 				'geor' => q{gruzijski brojevi},
 				'grek' => q{grčki brojevi},
 				'greklow' => q{mali grčki brojevi},
 				'gujr' => q{gudžaratske znamenke},
 				'guru' => q{znamenke pisma gurmukhi},
 				'hanidec' => q{kineski decimalni brojevi},
 				'hans' => q{pojednostavljeni kineski brojevi},
 				'hansfin' => q{pojednostavljeni kineski financijski brojevi},
 				'hant' => q{tradicionalni kineski brojevi},
 				'hantfin' => q{tradicionalni kineski financijski brojevi},
 				'hebr' => q{hebrejski brojevi},
 				'jpan' => q{japanski brojevi},
 				'jpanfin' => q{japanski financijski brojevi},
 				'khmr' => q{khmerske znamenke},
 				'knda' => q{znamenke pisma kannada},
 				'laoo' => q{laoske znamenke},
 				'latn' => q{arapski brojevi},
 				'mlym' => q{malajalamske znamenke},
 				'mong' => q{Mongolske znamenke},
 				'mymr' => q{mijanmarske znamenke},
 				'native' => q{Izvorne znamenke},
 				'orya' => q{orijske znamenke},
 				'roman' => q{rimski brojevi},
 				'romanlow' => q{mali rimski brojevi},
 				'taml' => q{tamilski brojevi},
 				'tamldec' => q{tamilske znamenke},
 				'telu' => q{znamenke teluškog pisma},
 				'thai' => q{tajske znamenke},
 				'tibt' => q{tibetske znamenke},
 				'traditional' => q{Tradicionalni brojevi},
 				'vaii' => q{Vai znamenke},
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
			'metric' => q{metrički sustav},
 			'UK' => q{imperijalni sustav},
 			'US' => q{američki sustav},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Jezik: {0}',
 			'script' => 'Pismo: {0}',
 			'region' => 'Regija: {0}',

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
			auxiliary => qr{[q w x y]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŽ}', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', '{LJ}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a b c č ć d {dž} đ e f g h i j k l {lj} m n {nj} o p r s š t u v z ž]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[‐ – — , ; \: ! ? . … ' ‘ ’ ‚ " “ ” „ ( ) \[ \] @ * / ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŽ}', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', '{LJ}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
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
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‚},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
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
					'acre' => {
						'few' => q({0} katastarska jutra),
						'name' => q(katastarska jutra),
						'one' => q({0} katastarsko jutro),
						'other' => q({0} katastarskih jutara),
					},
					'acre-foot' => {
						'few' => q({0} aker-stope),
						'name' => q(aker-stope),
						'one' => q({0} aker-stopa),
						'other' => q({0} aker-stopi),
					},
					'ampere' => {
						'few' => q({0} ampera),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} ampera),
					},
					'arc-minute' => {
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minuta),
						'other' => q({0} minuta),
					},
					'arc-second' => {
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomske jedinice),
						'name' => q(astronomske jedinice),
						'one' => q({0} astronomska jedinica),
						'other' => q({0} astronomskih jedinica),
					},
					'bit' => {
						'few' => q({0} bita),
						'name' => q(bitovi),
						'one' => q({0} bit),
						'other' => q({0} bitova),
					},
					'bushel' => {
						'few' => q({0} bušela),
						'name' => q(bušeli),
						'one' => q({0} bušel),
						'other' => q({0} bušela),
					},
					'byte' => {
						'few' => q({0} bajta),
						'name' => q(bajtovi),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					'calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					'carat' => {
						'few' => q({0} karata),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					'celsius' => {
						'few' => q({0} Celzijeva stupnja),
						'name' => q(Celzijevi stupnjevi),
						'one' => q({0} Celzijev stupanj),
						'other' => q({0} Celzijevih stupnjeva),
					},
					'centiliter' => {
						'few' => q({0} centilitra),
						'name' => q(centilitri),
						'one' => q({0} centilitar),
						'other' => q({0} centilitara),
					},
					'centimeter' => {
						'few' => q({0} centimetra),
						'name' => q(centimetri),
						'one' => q({0} centimetar),
						'other' => q({0} centimetara),
						'per' => q({0}/cm),
					},
					'century' => {
						'few' => q({0} stoljeća),
						'name' => q(stoljeća),
						'one' => q({0} stoljeće),
						'other' => q({0} stoljeća),
					},
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					'cubic-centimeter' => {
						'few' => q({0} kubna centimetra),
						'name' => q(kubni centimetri),
						'one' => q({0} kubni centimetar),
						'other' => q({0} kubnih centimetara),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'few' => q({0} kubne stope),
						'name' => q(kubne stope),
						'one' => q({0} kubna stopa),
						'other' => q({0} kubnih stopa),
					},
					'cubic-inch' => {
						'few' => q({0} kubna inča),
						'name' => q(kubni inči),
						'one' => q({0} kubni inč),
						'other' => q({0} kubnih inča),
					},
					'cubic-kilometer' => {
						'few' => q({0} kubna kilometra),
						'name' => q(kubni kilometri),
						'one' => q({0} kubni kilometar),
						'other' => q({0} kubnih kilometara),
					},
					'cubic-meter' => {
						'few' => q({0} kubna metra),
						'name' => q(kubni metri),
						'one' => q({0} kubni metar),
						'other' => q({0} kubnih metara),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'few' => q({0} kubne milje),
						'name' => q(kubne milje),
						'one' => q({0} kubna milja),
						'other' => q({0} kubnih milja),
					},
					'cubic-yard' => {
						'few' => q({0} kubna jarda),
						'name' => q(kubni jardi),
						'one' => q({0} kubni jard),
						'other' => q({0} kubnih jardi),
					},
					'cup' => {
						'few' => q({0} šalice),
						'name' => q(šalice),
						'one' => q({0} šalica),
						'other' => q({0} šalica),
					},
					'cup-metric' => {
						'few' => q({0} metričke šalice),
						'name' => q(metričke šalice),
						'one' => q({0} metrička šalica),
						'other' => q({0} metričkih šalica),
					},
					'day' => {
						'few' => q({0} dana),
						'name' => q(dani),
						'one' => q({0} dan),
						'other' => q({0} dana),
						'per' => q({0} dnevno),
					},
					'deciliter' => {
						'few' => q({0} decilitra),
						'name' => q(decilitri),
						'one' => q({0} decilitar),
						'other' => q({0} decilitara),
					},
					'decimeter' => {
						'few' => q({0} decimetra),
						'name' => q(decimetri),
						'one' => q({0} decimetar),
						'other' => q({0} decimetara),
					},
					'degree' => {
						'few' => q({0} stupnja),
						'name' => q(stupnjevi),
						'one' => q({0} stupanj),
						'other' => q({0} stupnjeva),
					},
					'fahrenheit' => {
						'few' => q({0} Fahrenheitova stupnja),
						'name' => q(Fahrenheitovi stupnjevi),
						'one' => q({0} Fahrenheitov stupanj),
						'other' => q({0} Fahrenheitovih stupnjeva),
					},
					'fathom' => {
						'few' => q({0} hvata),
						'name' => q(hvati),
						'one' => q({0} hvat),
						'other' => q({0} hvati),
					},
					'fluid-ounce' => {
						'few' => q({0} tekuće unce),
						'name' => q(tekuće unce),
						'one' => q({0} tekuća unca),
						'other' => q({0} tekućih unci),
					},
					'foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorija),
					},
					'foot' => {
						'few' => q({0} stope),
						'name' => q(stope),
						'one' => q({0} stopa),
						'other' => q({0} stopa),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'few' => q({0} furlonga),
						'name' => q(furlonzi),
						'one' => q({0} furlong),
						'other' => q({0} furlonga),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} galona),
						'name' => q(galoni),
						'one' => q({0} galon),
						'other' => q({0} galona),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'few' => q({0} imp. galona),
						'name' => q(imp. galoni),
						'one' => q({0} imp. galon),
						'other' => q({0} imp. galona),
						'per' => q({0} po imp. galonu),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} gigabita),
						'name' => q(gigabiti),
						'one' => q({0} gigabit),
						'other' => q({0} gigabita),
					},
					'gigabyte' => {
						'few' => q({0} gigabajta),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajta),
					},
					'gigahertz' => {
						'few' => q({0} gigaherca),
						'name' => q(gigaherci),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherca),
					},
					'gigawatt' => {
						'few' => q({0} gigavata),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavata),
					},
					'gram' => {
						'few' => q({0} grama),
						'name' => q(grami),
						'one' => q({0} gram),
						'other' => q({0} grama),
						'per' => q({0}/g),
					},
					'hectare' => {
						'few' => q({0} hektra),
						'name' => q(hektari),
						'one' => q({0} hektar),
						'other' => q({0} hektara),
					},
					'hectoliter' => {
						'few' => q({0} hektolitra),
						'name' => q(hektolitri),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitara),
					},
					'hectopascal' => {
						'few' => q({0} hektopaskala),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskala),
					},
					'hertz' => {
						'few' => q({0} herca),
						'name' => q(herci),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					'horsepower' => {
						'few' => q({0} konjske snage),
						'name' => q(konjske snage),
						'one' => q({0} konjska snaga),
						'other' => q({0} konjskih snaga),
					},
					'hour' => {
						'few' => q({0} sata),
						'name' => q(sati),
						'one' => q({0} sat),
						'other' => q({0} sati),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0} inča),
						'name' => q(inči),
						'one' => q({0} inč),
						'other' => q({0} inča),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'few' => q({0} inča žive),
						'name' => q(inči žive),
						'one' => q({0} inč žive),
						'other' => q({0} inča žive),
					},
					'joule' => {
						'few' => q({0} džula),
						'name' => q(džuli),
						'one' => q({0} džul),
						'other' => q({0} džula),
					},
					'karat' => {
						'few' => q({0} karata),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					'kelvin' => {
						'few' => q({0} kelvina),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} kelvina),
					},
					'kilobit' => {
						'few' => q({0} kilobita),
						'name' => q(kilobiti),
						'one' => q({0} kilobit),
						'other' => q({0} kilobita),
					},
					'kilobyte' => {
						'few' => q({0} kilobajta),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajta),
					},
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorija),
					},
					'kilogram' => {
						'few' => q({0} kilograma),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilograma),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'few' => q({0} kiloherca),
						'name' => q(kiloherci),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherca),
					},
					'kilojoule' => {
						'few' => q({0} kilodžula),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					'kilometer' => {
						'few' => q({0} kilometra),
						'name' => q(kilometri),
						'one' => q({0} kilometar),
						'other' => q({0} kilometara),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometra na sat),
						'name' => q(kilometri na sat),
						'one' => q({0} kilometar na sat),
						'other' => q({0} kilometara na sat),
					},
					'kilowatt' => {
						'few' => q({0} kilovata),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovata),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilovatsata),
						'name' => q(kilovatsati),
						'one' => q({0} kilovatsat),
						'other' => q({0} kilovatsati),
					},
					'knot' => {
						'few' => q({0} čvora),
						'name' => q(čvor),
						'one' => q({0} čvor),
						'other' => q({0} čvorova),
					},
					'light-year' => {
						'few' => q({0} svjetlosne godine),
						'name' => q(svjetlosne godine),
						'one' => q({0} svjetlosna godina),
						'other' => q({0} svjetlosnih godina),
					},
					'liter' => {
						'few' => q({0} litre),
						'name' => q(litre),
						'one' => q({0} litra),
						'other' => q({0} litara),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} litre na 100 kilometara),
						'name' => q(litre na 100 kilometara),
						'one' => q({0} litra na 100 kilometara),
						'other' => q({0} litara na 100 kilometara),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litre po kilometru),
						'name' => q(litre po kilometru),
						'one' => q({0} litra po kilometru),
						'other' => q({0} litara po kilometru),
					},
					'lux' => {
						'few' => q({0} luksa),
						'name' => q(luksi),
						'one' => q({0} luks),
						'other' => q({0} luksa),
					},
					'megabit' => {
						'few' => q({0} megabita),
						'name' => q(megabiti),
						'one' => q({0} megabit),
						'other' => q({0} megabita),
					},
					'megabyte' => {
						'few' => q({0} megabajta),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajta),
					},
					'megahertz' => {
						'few' => q({0} megaherca),
						'name' => q(megaherci),
						'one' => q({0} megaherc),
						'other' => q({0} megaherca),
					},
					'megaliter' => {
						'few' => q({0} megalitra),
						'name' => q(megalitri),
						'one' => q({0} megalitar),
						'other' => q({0} megalitara),
					},
					'megawatt' => {
						'few' => q({0} megavata),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavata),
					},
					'meter' => {
						'few' => q({0} metra),
						'name' => q(metri),
						'one' => q({0} metar),
						'other' => q({0} metara),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'few' => q({0} metra u sekundi),
						'name' => q(metri u sekundi),
						'one' => q({0} metar u sekundi),
						'other' => q({0} metara u sekundi),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metra u sekundi na kvadrat),
						'name' => q(metri u sekundi na kvadrat),
						'one' => q({0} metar u sekundi na kvadrat),
						'other' => q({0} metara u sekundi na kvadrat),
					},
					'metric-ton' => {
						'few' => q({0} tone),
						'name' => q(tone),
						'one' => q({0} tona),
						'other' => q({0} tona),
					},
					'microgram' => {
						'few' => q({0} mikrograma),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrograma),
					},
					'micrometer' => {
						'few' => q({0} mikrometra),
						'name' => q(mikrometri),
						'one' => q({0} mikrometar),
						'other' => q({0} mikrometara),
					},
					'microsecond' => {
						'few' => q({0} mikrosekunde),
						'name' => q(mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundi),
					},
					'mile' => {
						'few' => q({0} milje),
						'name' => q(milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					'mile-per-gallon' => {
						'few' => q({0} milje po galonu),
						'name' => q(milje po galonu),
						'one' => q({0} milja po galonu),
						'other' => q({0} milja po galonu),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} milje po imp. galonu),
						'name' => q(milje po imp. galonu),
						'one' => q({0} milja po imp. galonu),
						'other' => q({0} milja po imp. galonu),
					},
					'mile-per-hour' => {
						'few' => q({0} milje na sat),
						'name' => q(milje na sat),
						'one' => q({0} milja na sat),
						'other' => q({0} milja na sat),
					},
					'mile-scandinavian' => {
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavska milja),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milja),
					},
					'milliampere' => {
						'few' => q({0} miliampera),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					'millibar' => {
						'few' => q({0} milibara),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					'milligram' => {
						'few' => q({0} miligrama),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligrama),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} miligrama po decilitru),
						'name' => q(miligrami po decilitru),
						'one' => q({0} miligram po decilitru),
						'other' => q({0} miligrama po decilitru),
					},
					'milliliter' => {
						'few' => q({0} mililitra),
						'name' => q(mililitri),
						'one' => q({0} mililitar),
						'other' => q({0} mililitara),
					},
					'millimeter' => {
						'few' => q({0} milimetra),
						'name' => q(milimetri),
						'one' => q({0} milimetar),
						'other' => q({0} milimetara),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetra živina stupca),
						'name' => q(milimetri živina stupca),
						'one' => q({0} milimetar živina stupca),
						'other' => q({0} milimetara živina stupca),
					},
					'millimole-per-liter' => {
						'few' => q({0} milimola po litri),
						'name' => q(milimoli po litri),
						'one' => q({0} milimol po litri),
						'other' => q({0} milimola po litri),
					},
					'millisecond' => {
						'few' => q({0} milisekunde),
						'name' => q(milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundi),
					},
					'milliwatt' => {
						'few' => q({0} milivata),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivata),
					},
					'minute' => {
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minuta),
						'other' => q({0} minuta),
						'per' => q({0}/min),
					},
					'month' => {
						'few' => q({0} mjeseca),
						'name' => q(mjeseci),
						'one' => q({0} mjesec),
						'other' => q({0} mjeseci),
						'per' => q({0} mjesečno),
					},
					'nanometer' => {
						'few' => q({0} nanometra),
						'name' => q(nanometri),
						'one' => q({0} nanometar),
						'other' => q({0} nanometara),
					},
					'nanosecond' => {
						'few' => q({0} nanosekunde),
						'name' => q(nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundi),
					},
					'nautical-mile' => {
						'few' => q({0} nautičke milje),
						'name' => q(nautičke milje),
						'one' => q({0} nautička milja),
						'other' => q({0} nautičkih milja),
					},
					'ohm' => {
						'few' => q({0} oma),
						'name' => q(omi),
						'one' => q({0} om),
						'other' => q({0} oma),
					},
					'ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'few' => q({0} troy unce),
						'name' => q(troy unce),
						'one' => q({0} troy unca),
						'other' => q({0} troy unci),
					},
					'parsec' => {
						'few' => q({0} parseka),
						'name' => q(parseci),
						'one' => q({0} parsek),
						'other' => q({0} parseka),
					},
					'part-per-million' => {
						'few' => q({0} dijela na milijun),
						'name' => q(dijelovi na milijun),
						'one' => q({0} dio na milijun),
						'other' => q({0} dijelova na milijun),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'few' => q({0} pikometra),
						'name' => q(pikometri),
						'one' => q({0} pikometar),
						'other' => q({0} pikometara),
					},
					'pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinti),
					},
					'pint-metric' => {
						'few' => q({0} metričke pinte),
						'name' => q(metričke pinte),
						'one' => q({0} metrička pinta),
						'other' => q({0} metričkih pinti),
					},
					'point' => {
						'few' => q({0} točke),
						'name' => q(točke),
						'one' => q({0} točka),
						'other' => q({0} točaka),
					},
					'pound' => {
						'few' => q({0} funte),
						'name' => q(funte),
						'one' => q({0} funta),
						'other' => q({0} funti),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} funte po kvadratnom inču),
						'name' => q(funte po kvadratnom inču),
						'one' => q({0} funta po kvadratnom inču),
						'other' => q({0} funti po kvadratnom inču),
					},
					'quart' => {
						'few' => q({0} četvrtine),
						'name' => q(četvrtine),
						'one' => q({0} četvrtina),
						'other' => q({0} četvrtina),
					},
					'radian' => {
						'few' => q({0} radijana),
						'name' => q(radijani),
						'one' => q({0} radijan),
						'other' => q({0} radijana),
					},
					'revolution' => {
						'few' => q({0} okretaja),
						'name' => q(okretaj),
						'one' => q({0} okretaj),
						'other' => q({0} okretaja),
					},
					'second' => {
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'few' => q({0} kvadratna centimetra),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimetar),
						'other' => q({0} kvadratnih centimetara),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'few' => q({0} kvadratne stope),
						'name' => q(kvadratne stope),
						'one' => q({0} kvadratna stopa),
						'other' => q({0} kvadratnih stopa),
					},
					'square-inch' => {
						'few' => q({0} kvadratna inča),
						'name' => q(kvadratni inči),
						'one' => q({0} kvadratni inč),
						'other' => q({0} kvadratnih inča),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'few' => q({0} kvadratna kilometra),
						'name' => q(kvadratni kilometri),
						'one' => q({0} kvadratni kilometar),
						'other' => q({0} kvadratnih kilometara),
						'per' => q({0} po kvadratnom kilometru),
					},
					'square-meter' => {
						'few' => q({0} kvadratna metra),
						'name' => q(kvadratni metri),
						'one' => q({0} kvadratni metar),
						'other' => q({0} kvadratnih metara),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratne milje),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milja),
						'per' => q({0} po kvadratnoj milji),
					},
					'square-yard' => {
						'few' => q({0} kvadratna jarda),
						'name' => q(kvadratni jardi),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jardi),
					},
					'stone' => {
						'few' => q({0} kamena),
						'name' => q(kameni),
						'one' => q({0} kamen),
						'other' => q({0} kamena),
					},
					'tablespoon' => {
						'few' => q({0} žlice),
						'name' => q(žlice),
						'one' => q({0} žlica),
						'other' => q({0} žlica),
					},
					'teaspoon' => {
						'few' => q({0} žličice),
						'name' => q(žličice),
						'one' => q({0} žličica),
						'other' => q({0} žličica),
					},
					'terabit' => {
						'few' => q({0} terabita),
						'name' => q(terabiti),
						'one' => q({0} terabit),
						'other' => q({0} terabita),
					},
					'terabyte' => {
						'few' => q({0} terabajta),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajta),
					},
					'ton' => {
						'few' => q({0} kratke tone),
						'name' => q(kratke tone),
						'one' => q({0} kratka tona),
						'other' => q({0} kratkih tona),
					},
					'volt' => {
						'few' => q({0} volta),
						'name' => q(volti),
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					'watt' => {
						'few' => q({0} vata),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vati),
					},
					'week' => {
						'few' => q({0} tjedna),
						'name' => q(tjedni),
						'one' => q({0} tjedan),
						'other' => q({0} tjedana),
						'per' => q({0} tjedno),
					},
					'yard' => {
						'few' => q({0} jarda),
						'name' => q(jardi),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					'year' => {
						'few' => q({0} godine),
						'name' => q(godine),
						'one' => q({0} godina),
						'other' => q({0} godina),
						'per' => q({0} godišnje),
					},
				},
				'narrow' => {
					'acre' => {
						'few' => q({0} kj),
						'one' => q({0} kj),
						'other' => q({0} kj),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'few' => q({0} bita),
						'one' => q({0} bit),
						'other' => q({0} bitova),
					},
					'bushel' => {
						'few' => q({0} bu),
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'few' => q({0} bajta),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					'calorie' => {
						'few' => q({0} cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'day' => {
						'few' => q({0} d.),
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0}°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'few' => q({0} hv),
						'name' => q(hv),
						'one' => q({0} hv),
						'other' => q({0} hv),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'furlong' => {
						'few' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} KS),
						'one' => q({0} KS),
						'other' => q({0} KS),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'inch' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0}l/100km),
						'name' => q(l/100 km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram' => {
						'few' => q({0} mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} m),
						'name' => q(min),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'month' => {
						'few' => q({0} mj.),
						'name' => q(mj.),
						'one' => q({0} mj.),
						'other' => q({0} mj.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'few' => q({0} pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'few' => q({0} tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'few' => q({0} tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'few' => q({0} V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} tj.),
						'name' => q(tj.),
						'one' => q({0} tj.),
						'other' => q({0} tj.),
					},
					'yard' => {
						'few' => q({0} yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} g.),
						'name' => q(g.),
						'one' => q({0} g.),
						'other' => q({0} g.),
					},
				},
				'short' => {
					'acre' => {
						'few' => q({0} kj),
						'name' => q(kj),
						'one' => q({0} kj),
						'other' => q({0} kj),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'arc-second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'few' => q({0} bita),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bitova),
					},
					'bushel' => {
						'few' => q({0} bu),
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'few' => q({0} bajta),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					'calorie' => {
						'few' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} ct),
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'few' => q({0} st.),
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
					},
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'name' => q(šalice),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'few' => q({0} mc),
						'name' => q(m. šalica),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'few' => q({0} dana),
						'name' => q(dani),
						'one' => q({0} dan),
						'other' => q({0} dana),
						'per' => q({0}/d.),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0}°F),
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'few' => q({0} hv),
						'name' => q(hv),
						'one' => q({0} hv),
						'other' => q({0} hv),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'few' => q({0} ft),
						'name' => q(stope),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'few' => q({0} fur),
						'name' => q(furlonzi),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'few' => q({0} imp. gal.),
						'name' => q(imp. gal.),
						'one' => q({0} imp. gal.),
						'other' => q({0} imp. gal.),
						'per' => q({0}/imp. gal.),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} KS),
						'name' => q(KS),
						'one' => q({0} KS),
						'other' => q({0} KS),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0} in),
						'name' => q(inči),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'few' => q({0} čv),
						'name' => q(čv),
						'one' => q({0} čv),
						'other' => q({0} čv),
					},
					'light-year' => {
						'few' => q({0} ly),
						'name' => q(svjetlosne g.),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg imp.),
						'name' => q(milje/imp. gal.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'few' => q({0} mj.),
						'name' => q(mj.),
						'one' => q({0} mj.),
						'other' => q({0} mj.),
						'per' => q({0}/mj.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'few' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'few' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'few' => q({0} pt),
						'name' => q(točke),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'few' => q({0} okr.),
						'name' => q(okr.),
						'one' => q({0} okr.),
						'other' => q({0} okr.),
					},
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'few' => q({0} tbsp),
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'few' => q({0} tsp),
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} tn),
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'few' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} tj.),
						'name' => q(tj.),
						'one' => q({0} tj.),
						'other' => q({0} tj.),
						'per' => q({0}/tj.),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(jardi),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} g.),
						'name' => q(g.),
						'one' => q({0} g.),
						'other' => q({0} g.),
						'per' => q({0}/g.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:da|d|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ne|n)$' }
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
					'few' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mil'.'',
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'few' => '00 mil'.'',
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'few' => '000 mil'.'',
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'few' => '0 mlr'.'',
					'one' => '0 mlr'.'',
					'other' => '0 mlr'.'',
				},
				'10000000000' => {
					'few' => '00 mlr'.'',
					'one' => '00 mlr'.'',
					'other' => '00 mlr'.'',
				},
				'100000000000' => {
					'few' => '000 mlr'.'',
					'one' => '000 mlr'.'',
					'other' => '000 mlr'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'few' => '0 tisuće',
					'one' => '0 tisuća',
					'other' => '0 tisuća',
				},
				'10000' => {
					'few' => '00 tisuće',
					'one' => '00 tisuća',
					'other' => '00 tisuća',
				},
				'100000' => {
					'few' => '000 tisuće',
					'one' => '000 tisuća',
					'other' => '000 tisuća',
				},
				'1000000' => {
					'few' => '0 milijuna',
					'one' => '0 milijun',
					'other' => '0 milijuna',
				},
				'10000000' => {
					'few' => '00 milijuna',
					'one' => '00 milijun',
					'other' => '00 milijuna',
				},
				'100000000' => {
					'few' => '000 milijuna',
					'one' => '000 milijun',
					'other' => '000 milijuna',
				},
				'1000000000' => {
					'few' => '0 milijarde',
					'one' => '0 milijarda',
					'other' => '0 milijardi',
				},
				'10000000000' => {
					'few' => '00 milijarde',
					'one' => '00 milijarda',
					'other' => '00 milijardi',
				},
				'100000000000' => {
					'few' => '000 milijarde',
					'one' => '000 milijarda',
					'other' => '000 milijardi',
				},
				'1000000000000' => {
					'few' => '0 bilijuna',
					'one' => '0 bilijun',
					'other' => '0 bilijuna',
				},
				'10000000000000' => {
					'few' => '00 bilijuna',
					'one' => '00 bilijun',
					'other' => '00 bilijuna',
				},
				'100000000000000' => {
					'few' => '000 bilijuna',
					'one' => '000 bilijun',
					'other' => '000 bilijuna',
				},
			},
			'short' => {
				'1000' => {
					'few' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mil'.'',
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'few' => '00 mil'.'',
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'few' => '000 mil'.'',
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'few' => '0 mlr'.'',
					'one' => '0 mlr'.'',
					'other' => '0 mlr'.'',
				},
				'10000000000' => {
					'few' => '00 mlr'.'',
					'one' => '00 mlr'.'',
					'other' => '00 mlr'.'',
				},
				'100000000000' => {
					'few' => '000 mlr'.'',
					'one' => '000 mlr'.'',
					'other' => '000 mlr'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
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
			symbol => 'ADP',
			display_name => {
				'currency' => q(andorska pezeta),
				'few' => q(andorske pezete),
				'one' => q(andorska pezeta),
				'other' => q(andorskih pezeta),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(UAE dirham),
				'few' => q(UAE dirhama),
				'one' => q(UAE dirham),
				'other' => q(UAE dirhama),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(afganistanski afgani \(1927.–2002.\)),
				'few' => q(afganistanska afgana \(1927.–2002.\)),
				'one' => q(afganistanski afgan \(1927.–2002.\)),
				'other' => q(afganistanskih afgana \(1927.–2002.\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afganistanski afgani),
				'few' => q(afganistanska afgana),
				'one' => q(afganistanski afgan),
				'other' => q(afganistanskih afgana),
			},
		},
		'ALK' => {
			symbol => 'ALK',
			display_name => {
				'currency' => q(stari albanski lek),
				'few' => q(stara albanska leka),
				'one' => q(stari albanski lek),
				'other' => q(starih albanskih leka),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albanski lek),
				'few' => q(albanska leka),
				'one' => q(albanski lek),
				'other' => q(albanskih leka),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(armenski dram),
				'few' => q(armenska drama),
				'one' => q(armenski dram),
				'other' => q(armenskih drama),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(nizozemskoantilski gulden),
				'few' => q(nizozemskoantilska guldena),
				'one' => q(nizozemskoantilski gulden),
				'other' => q(nizozemskoantilskih guldena),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(angolska kvanza),
				'few' => q(angolske kvanze),
				'one' => q(angolska kvanza),
				'other' => q(angolskih kvanzi),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(angolska kvanza \(1977.–1990.\)),
				'few' => q(angolske kvanze \(1977.–1990.\)),
				'one' => q(angolska kvanza \(1977.–1990.\)),
				'other' => q(angolskih kvanzi \(1977.–1990.\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(angolska nova kvanza \(1990.–2000.\)),
				'few' => q(angolske nove kvanze \(1990.–2000.\)),
				'one' => q(angolska nova kvanza \(1990.–2000.\)),
				'other' => q(angolskih novih kvanzi \(1990.–2000.\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(angolska kvanza \(1995.–1999.\)),
				'few' => q(angolske kvanze \(1995.–1999.\)),
				'one' => q(angolska kvanza \(1995.–1999.\)),
				'other' => q(angolskih kvanzi \(1995.–1999.\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(argentinski austral),
				'few' => q(argentinska australa),
				'one' => q(argentinski austral),
				'other' => q(argentinskih australa),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(argentinski pezo lej \(1970.–1983.\)),
				'few' => q(argentinska pezo leja \(1970.–1983.\)),
				'one' => q(argentinski pezo lej \(1970.–1983.\)),
				'other' => q(argentinskih pezo leja \(1970.–1983.\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(argentinski pezo \(1881.–1970.\)),
				'few' => q(argentinska peza \(1881.–1970.\)),
				'one' => q(argentinski pezo \(1881.–1970.\)),
				'other' => q(argentinskih peza \(1881.–1970.\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(argentinski pezo \(1983.–1985.\)),
				'few' => q(argentinska peza \(1983.–1985.\)),
				'one' => q(argentinski pezo \(1983.–1985.\)),
				'other' => q(argentinskih peza \(1983.–1985.\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(argentinski pezo),
				'few' => q(argentinska pezosa),
				'one' => q(argentinski pezos),
				'other' => q(argentinskih pezosa),
			},
		},
		'ATS' => {
			symbol => 'ATS',
			display_name => {
				'currency' => q(austrijski šiling),
				'few' => q(austrijska šilinga),
				'one' => q(austrijski šiling),
				'other' => q(austrijskih šilinga),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(australski dolar),
				'few' => q(australska dolara),
				'one' => q(australski dolar),
				'other' => q(australskih dolara),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(arupski florin),
				'few' => q(arupska florina),
				'one' => q(arupski florin),
				'other' => q(arupskih florina),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(azerbajdžanski manat \(1993.–2006.\)),
				'few' => q(azerbajdžanska manata \(1993.–2006.\)),
				'one' => q(azerbajdžanski manat \(1993.–2006.\)),
				'other' => q(azerbajdžanskih manata \(1993.–2006.\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(azerbajdžanski manat),
				'few' => q(azerbajdžanska manata),
				'one' => q(azerbajdžanski manat),
				'other' => q(azerbajdžanskih manata),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(bosansko-hercegovački dinar),
				'few' => q(bosansko-hercegovačka dinara),
				'one' => q(bosansko-hercegovački dinar),
				'other' => q(bosansko-hercegovačkih dinara),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(konvertibilna marka),
				'few' => q(konvertibilne marke),
				'one' => q(konvertibilna marka),
				'other' => q(konvertibilnih maraka),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(bosansko-hercegovački novi dinar),
				'few' => q(bosansko-hercegovačka nova dinara),
				'one' => q(bosansko-hercegovački novi dinar),
				'other' => q(bosansko-hercegovačkih novih dinara),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadoski dolar),
				'few' => q(barbadoska dolara),
				'one' => q(barbadoski dolar),
				'other' => q(barbadoskih dolara),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(bangladeška taka),
				'few' => q(bangladeške take),
				'one' => q(bangladeška taka),
				'other' => q(bangladeških taka),
			},
		},
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(belgijski franak \(konvertibilan\)),
				'few' => q(belgijska franka \(konvertibilna\)),
				'one' => q(belgijski franak \(konvertibilan\)),
				'other' => q(belgijskih franaka \(konvertibilnih\)),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(belgijski franak),
				'few' => q(belgijska franka),
				'one' => q(belgijski franak),
				'other' => q(belgijskih franaka),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(belgijski franak \(financijski\)),
				'few' => q(belgijska franka \(financijska\)),
				'one' => q(belgijski franak \(financijski\)),
				'other' => q(belgijskih franaka \(financijskih\)),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(bugarski čvrsti lev),
				'few' => q(bugarska čvrsta leva),
				'one' => q(bugarski čvrsti lev),
				'other' => q(bugarskih čvrstih leva),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(bugarski socijalistički lev),
				'few' => q(bugarska socijalistička leva),
				'one' => q(bugarski socijalistički lev),
				'other' => q(bugarskih socijalističkih leva),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bugarski lev),
				'few' => q(bugarska leva),
				'one' => q(bugarski lev),
				'other' => q(bugarskih leva),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(stari bugarski lev),
				'few' => q(stara bugarska leva),
				'one' => q(stari bugarski lev),
				'other' => q(starih bugarskih leva),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahreinski dinar),
				'few' => q(bahreinska dinara),
				'one' => q(bahreinski dinar),
				'other' => q(bahreinskih dinara),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundski franak),
				'few' => q(burundska franka),
				'one' => q(burundski franak),
				'other' => q(burundskih franaka),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(bermudski dolar),
				'few' => q(bermudska dolara),
				'one' => q(bermudski dolar),
				'other' => q(bermudskih dolara),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(brunejski dolar),
				'few' => q(brunejska dolara),
				'one' => q(brunejski dolar),
				'other' => q(brunejskih dolara),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(bolivijski bolivijano),
				'few' => q(bolivijska bolivijana),
				'one' => q(bolivijski bolivijano),
				'other' => q(bolivijskih bolivijana),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(stari bolivijski bolivijano),
				'few' => q(stara bolivijska bolivijana),
				'one' => q(stari bolivijski bolivijano),
				'other' => q(starih bolivijskih bolivijana),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(bolivijski pezo),
				'few' => q(bolivijska peza),
				'one' => q(bolivijski pezo),
				'other' => q(bolivijskih peza),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(bolivijski mvdol),
				'few' => q(bolivijska mvdola),
				'one' => q(bolivijski mvdol),
				'other' => q(bolivijskih mvdola),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(brazilski novi cruzeiro \(1967.–1986.\)),
				'few' => q(brazilska nova cruzeira \(1967.–1986.\)),
				'one' => q(brazilski novi cruzeir \(1967.–1986.\)),
				'other' => q(brazilskih novih cruzeira \(1967.–1986.\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(brazilski cruzado),
				'few' => q(brazilska cruzada),
				'one' => q(brazilski cruzad),
				'other' => q(brazilskih cruzada),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(brazilski cruzeiro \(1990.–1993.\)),
				'few' => q(brazilska cruzeira \(1990.–1993.\)),
				'one' => q(brazilski cruzeir \(1990.–1993.\)),
				'other' => q(brazilskih cruzeira \(1990.–1993.\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brazilski real),
				'few' => q(brazilska reala),
				'one' => q(brazilski real),
				'other' => q(brazilskih reala),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(brazilski novi cruzado),
				'few' => q(brazilska nova cruzada),
				'one' => q(brazilski novi cruzad),
				'other' => q(brazilskih novih cruzada),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(brazilski cruzeiro),
				'few' => q(brazilska cruzeira),
				'one' => q(brazilski cruzeiro),
				'other' => q(brazilskih cruzeira),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(stari brazilski kruzeiro),
				'few' => q(stara brazilska kruzeira),
				'one' => q(stari brazilski kruzeiro),
				'other' => q(starih brazilskih kruzeira),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(bahamski dolar),
				'few' => q(bahamska dolara),
				'one' => q(bahamski dolar),
				'other' => q(bahamskih dolara),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(butanski ngultrum),
				'few' => q(butanska ngultruma),
				'one' => q(butanski ngultrum),
				'other' => q(butanskih ngultruma),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(burmanski kyat),
				'few' => q(burmanska kyata),
				'one' => q(burmanski kyat),
				'other' => q(burmanskih kyata),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(bocvanska pula),
				'few' => q(bocvanske pule),
				'one' => q(bocvanska pula),
				'other' => q(bocvanskih pula),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(bjeloruska nova rublja \(1994–1999\)),
				'few' => q(bjeloruske nove rublje \(1994–1999\)),
				'one' => q(bjeloruska nova rublja \(1994–1999\)),
				'other' => q(bjeloruskih novih rublji \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(bjeloruska rublja),
				'few' => q(bjeloruske rublje),
				'one' => q(bjeloruska rublja),
				'other' => q(bjeloruskih rublji),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(bjeloruska rublja \(2000–2016\)),
				'few' => q(bjeloruske rublje \(2000–2016\)),
				'one' => q(bjeloruska rublja \(2000–2016\)),
				'other' => q(bjeloruskih rublji \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(belizeanski dolar),
				'few' => q(belizeanska dolara),
				'one' => q(belizeanski dolar),
				'other' => q(belizeanskih dolara),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadski dolar),
				'few' => q(kanadska dolara),
				'one' => q(kanadski dolar),
				'other' => q(kanadskih dolara),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(kongoanski franak),
				'few' => q(kongoanska franka),
				'one' => q(kongoanski franak),
				'other' => q(kongoanskih franaka),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(WIR euro),
				'few' => q(WIR eura),
				'one' => q(WIR euro),
				'other' => q(WIR eura),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(švicarski franak),
				'few' => q(švicarska franka),
				'one' => q(švicarski franak),
				'other' => q(švicarskih franaka),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(WIR franak),
				'few' => q(WIR franka),
				'one' => q(WIR franak),
				'other' => q(WIR franaka),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(čileanski eskudo),
				'few' => q(čileanska eskuda),
				'one' => q(čileanski eskudo),
				'other' => q(čileanskih eskuda),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(čileanski unidades de fomentos),
				'few' => q(čileanska unidades de fomentos),
				'one' => q(čileanski unidades de fomentos),
				'other' => q(čileanskih unidades de fomentos),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(čileanski pezo),
				'few' => q(čileanska peza),
				'one' => q(čileanski pezo),
				'other' => q(čileanskih peza),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kineski juan \(offshore\)),
				'few' => q(kineska juana \(offshore\)),
				'one' => q(kineski juan \(offshore\)),
				'other' => q(kineskih juana \(offshore\)),
			},
		},
		'CNX' => {
			symbol => 'CNX',
			display_name => {
				'currency' => q(kineski narodni dolar),
				'few' => q(kineska narodna dolara),
				'one' => q(kineski narodni dolar),
				'other' => q(kineskih narodnih dolara),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(kineski yuan),
				'few' => q(kineska yuana),
				'one' => q(kineski yuan),
				'other' => q(kineskih yuana),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(kolumbijski pezo),
				'few' => q(kolumbijska peza),
				'one' => q(kolumbijski pezo),
				'other' => q(kolumbijskih peza),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(unidad de valor real),
				'few' => q(unidad de valor reala),
				'one' => q(unidad de valor real),
				'other' => q(unidad de valor reala),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(kostarikanski kolon),
				'few' => q(kostarikanska kolona),
				'one' => q(kostarikanski kolon),
				'other' => q(kostarikanskih kolona),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(stari srpski dinar),
				'few' => q(stara srpska dinara),
				'one' => q(stari srpski dinar),
				'other' => q(starih srpskih dinara),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(čehoslovačka kruna),
				'few' => q(čehoslovačke krune),
				'one' => q(čehoslovačka kruna),
				'other' => q(čehoslovačkih kruna),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubanski konvertibilni pezo),
				'few' => q(kubanska konvertibilna peza),
				'one' => q(kubanski konvertibilni pezo),
				'other' => q(kubanskih konvertibilnih peza),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubanski pezo),
				'few' => q(kubanska peza),
				'one' => q(kubanski pezo),
				'other' => q(kubanskih peza),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(zelenortski eskudo),
				'few' => q(zelenortska eskuda),
				'one' => q(zelenortski eskudo),
				'other' => q(zelenortskih eskuda),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(ciparska funta),
				'few' => q(ciparske funte),
				'one' => q(ciparska funta),
				'other' => q(ciparskih funti),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(češka kruna),
				'few' => q(češke krune),
				'one' => q(češka kruna),
				'other' => q(čeških kruna),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(istočnonjemačka marka),
				'few' => q(istočnonjemačke marke),
				'one' => q(istočnonjemačka marka),
				'other' => q(istočnonjemačkih marki),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(njemačka marka),
				'few' => q(njemačke marke),
				'one' => q(njemačka marka),
				'other' => q(njemačkih marki),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(džibutski franak),
				'few' => q(džibutska franka),
				'one' => q(džibutski franak),
				'other' => q(džibutskih franaka),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(danska kruna),
				'few' => q(danske krune),
				'one' => q(danska kruna),
				'other' => q(danskih kruna),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dominikanski pezo),
				'few' => q(dominikanska peza),
				'one' => q(dominikanski pezo),
				'other' => q(dominikanskih peza),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(alžirski dinar),
				'few' => q(alžirska dinara),
				'one' => q(alžirski dinar),
				'other' => q(alžirskih dinara),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(ekvatorska sukra),
				'few' => q(ekvatorske sucre),
				'one' => q(evatorska sucra),
				'other' => q(ekvatorskih sucri),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(ekvatorski unidad de valor constante \(UVC\)),
				'few' => q(ekvatorska unidad de valor constante \(UVC\)),
				'one' => q(ekvatorski unidad de valor constante \(UVC\)),
				'other' => q(ekvatorskih unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(estonska kruna),
				'few' => q(estonske krune),
				'one' => q(estonska kruna),
				'other' => q(estonskih kruna),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(egipatska funta),
				'few' => q(egipatske funte),
				'one' => q(egipatska funta),
				'other' => q(egipatskih funti),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(eritrejska nakfa),
				'few' => q(eritrejske nakfe),
				'one' => q(eritrejska nakfa),
				'other' => q(eritrejskih nakfi),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(španjolska pezeta \(A račun\)),
				'few' => q(španjolske pezete \(A račun\)),
				'one' => q(španjolska pezeta \(A račun\)),
				'other' => q(španjolskih pezeta \(A račun\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(španjolska pezeta \(konvertibilni račun\)),
				'few' => q(španjolske pezete \(konvertibilan račun\)),
				'one' => q(španjolska pezeta \(konvertibilan račun\)),
				'other' => q(španjolskih pezeta \(konvertibilan račun\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(španjolska pezeta),
				'few' => q(španjolske pezete),
				'one' => q(španjolska pezeta),
				'other' => q(španjolskih pezeta),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiopski bir),
				'few' => q(etiopska bira),
				'one' => q(etiopski bir),
				'other' => q(etiopskih bira),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(euro),
				'few' => q(eura),
				'one' => q(euro),
				'other' => q(eura),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(finska marka),
				'few' => q(finske marke),
				'one' => q(finska marka),
				'other' => q(finskih marki),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(fidžijski dolar),
				'few' => q(fidžijska dolara),
				'one' => q(fidžijski dolar),
				'other' => q(fidžijskih dolara),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(falklandska funta),
				'few' => q(falklandske funte),
				'one' => q(falklandska funta),
				'other' => q(falklandskih funti),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(francuski franak),
				'few' => q(francuska franka),
				'one' => q(francuski franak),
				'other' => q(francuskih franaka),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(britanska funta),
				'few' => q(britanske funte),
				'one' => q(britanska funta),
				'other' => q(britanskih funti),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(gruzijski kupon larit),
				'few' => q(gruzijska kupon larita),
				'one' => q(gruzijski kupon larit),
				'other' => q(gruzijskih kupon larita),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(gruzijski lari),
				'few' => q(gruzijska lara),
				'one' => q(gruzijski lar),
				'other' => q(gruzijskih lara),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(ganski cedi \(1979.–2007.\)),
				'few' => q(ganska ceda \(1979.–2007.\)),
				'one' => q(ganski cedi \(1979.–2007.\)),
				'other' => q(ganskih ceda \(1979.–2007.\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ganski cedi),
				'few' => q(ganska ceda),
				'one' => q(ganski cedi),
				'other' => q(ganskih ceda),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltarska funta),
				'few' => q(gibraltarske funte),
				'one' => q(gibraltarska funta),
				'other' => q(gibraltarskih funti),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambijski dalas),
				'few' => q(gambijska dalasa),
				'one' => q(gambijski dalas),
				'other' => q(gambijskih dalasa),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(gvinejski franak),
				'few' => q(gvinejska franka),
				'one' => q(gvinejski franak),
				'other' => q(gvinejskih franaka),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(gvinejski syli),
				'few' => q(gvinejska sylija),
				'one' => q(gvinejski syli),
				'other' => q(gvinejskih sylija),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(ekvatorski gvinejski ekwele),
				'few' => q(ekvatorski gvinejska ekwele),
				'one' => q(ekvatorski gvinejski ekwele),
				'other' => q(ekvatorskih gvinejskih ekwele),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(grčka drahma),
				'few' => q(grčke drahme),
				'one' => q(grčka drahma),
				'other' => q(grčkih drahmi),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(gvatemalski kvecal),
				'few' => q(gvatemalska kvecala),
				'one' => q(gvatemalski kvecal),
				'other' => q(gvatemalskih kvecala),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(portugalski gvinejski eskudo),
				'few' => q(portugalska gvinejska eskuda),
				'one' => q(portugalski gvinejski eskudo),
				'other' => q(portugalskih gvinejskih eskuda),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(gvinejskobisauski pezo),
				'few' => q(gvinejskobisauska peza),
				'one' => q(gvinejskobisauski pezo),
				'other' => q(gvinejskobisauskih peza),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(gvajanski dolar),
				'few' => q(gvajanska dolara),
				'one' => q(gvajanski dolar),
				'other' => q(gvajanskih dolara),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(hongkonški dolar),
				'few' => q(honkonška dolara),
				'one' => q(honkonški dolar),
				'other' => q(honkonških dolara),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(honduraška lempira),
				'few' => q(honduraške lempire),
				'one' => q(honduraška lempira),
				'other' => q(honduraških lempira),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(hrvatski dinar),
				'few' => q(hrvatska dinara),
				'one' => q(hrvatski dinar),
				'other' => q(hrvatskih dinara),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(hrvatska kuna),
				'few' => q(hrvatske kune),
				'one' => q(hrvatska kuna),
				'other' => q(hrvatskih kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haićanski gourd),
				'few' => q(haićanska gourda),
				'one' => q(haićanski gourd),
				'other' => q(haićanskih gourda),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(mađarska forinta),
				'few' => q(mađarske forinte),
				'one' => q(mađarska forinta),
				'other' => q(mađarskih forinti),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(indonezijska rupija),
				'few' => q(indonezijske rupije),
				'one' => q(indonezijska rupija),
				'other' => q(indonezijskih rupija),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(irska funta),
				'few' => q(irske funte),
				'one' => q(irska funta),
				'other' => q(irskih funti),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(izraelska funta),
				'few' => q(izraelske funte),
				'one' => q(izraelska funta),
				'other' => q(izraelskih funti),
			},
		},
		'ILR' => {
			symbol => 'ILR',
			display_name => {
				'currency' => q(stari izraelski šekel),
				'few' => q(stara izraelska šekela),
				'one' => q(stari izraelski šekel),
				'other' => q(starih izraelskih šekela),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(novi izraelski šekel),
				'few' => q(nova izraelska šekela),
				'one' => q(novi izraelski šekel),
				'other' => q(novih izraelskih šekela),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indijska rupija),
				'few' => q(indijske rupije),
				'one' => q(indijska rupija),
				'other' => q(indijskih rupija),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(irački dinar),
				'few' => q(iračka dinara),
				'one' => q(irački dinar),
				'other' => q(iračkih dinara),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iranski rijal),
				'few' => q(iranska rijala),
				'one' => q(iranski rijal),
				'other' => q(iranskih rijala),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(stara islandska kruna),
				'few' => q(stare islandske krune),
				'one' => q(stara islandska kruna),
				'other' => q(starih islandskih kruna),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(islandska kruna),
				'few' => q(islandske krune),
				'one' => q(islandska kruna),
				'other' => q(islandskih kruna),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(talijanska lira),
				'few' => q(talijanske lire),
				'one' => q(talijanska lira),
				'other' => q(talijanskih lira),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamajčanski dolar),
				'few' => q(jamajčanska dolara),
				'one' => q(jamajčanski dolar),
				'other' => q(jamajčanskih dolara),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(jordanski dinar),
				'few' => q(jordanska dinara),
				'one' => q(jordanski dinar),
				'other' => q(jordanskih dinara),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(japanski jen),
				'few' => q(japanska jena),
				'one' => q(japanski jen),
				'other' => q(japanskih jena),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(kenijski šiling),
				'few' => q(kenijska šilinga),
				'one' => q(kenijski šiling),
				'other' => q(kenijskih šilinga),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgiski som),
				'few' => q(kirgijska soma),
				'one' => q(kirgijski som),
				'other' => q(kirgijskih soma),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambođanski rijal),
				'few' => q(kambođanska rijala),
				'one' => q(kambođanski rijal),
				'other' => q(kambođanskih rijala),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(komorski franak),
				'few' => q(komorska franka),
				'one' => q(komorski franak),
				'other' => q(komorskih franaka),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(sjevernokorejski won),
				'few' => q(sjevernokorejska wona),
				'one' => q(sjevernokorejski won),
				'other' => q(sjevernokorejskih wona),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(južnokorejski hvan),
				'few' => q(južnokorejska hvana),
				'one' => q(južnokorejski hvan),
				'other' => q(južnokorejskih hvana),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(stari južnokorejski von),
				'few' => q(stara južnokorejska vona),
				'one' => q(stari južnokorejski von),
				'other' => q(starih južnokorejskih vona),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(južnokorejski won),
				'few' => q(južnokorejska wona),
				'one' => q(južnokorejski won),
				'other' => q(južnokorejskih wona),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuvajtski dinar),
				'few' => q(kuvajtska dinara),
				'one' => q(kuvajtski dinar),
				'other' => q(kuvajtskih dinara),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(kajmanski dolar),
				'few' => q(kajmanska dolara),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanskih dolara),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kazahstanski tenge),
				'few' => q(kazahstanska tengea),
				'one' => q(kazahstanski tenge),
				'other' => q(kazahstanskih tengea),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laoski kip),
				'few' => q(laoska kipa),
				'one' => q(laoski kip),
				'other' => q(laoskih kipa),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanonska funta),
				'few' => q(libanonske funte),
				'one' => q(libanonska funta),
				'other' => q(libanonskih funti),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(šrilankanska rupija),
				'few' => q(šrilankanske rupije),
				'one' => q(šrilankanska rupija),
				'other' => q(šrilankanskih rupija),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(liberijski dolar),
				'few' => q(liberijska dolara),
				'one' => q(liberijski dolar),
				'other' => q(liberijskih dolara),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(lesoto loti),
				'few' => q(lesoto lotija),
				'one' => q(lesoto loti),
				'other' => q(lesoto lotija),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(litavski litas),
				'few' => q(litavska litasa),
				'one' => q(litavski litas),
				'other' => q(litavskih litasa),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(litavski talonas),
				'few' => q(litavska talonasa),
				'one' => q(litavski talonas),
				'other' => q(litavskih talonasa),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(luksemburški konvertibilni franak),
				'few' => q(luksemburška konvertibilna franka),
				'one' => q(luksemburški konvertibilni franak),
				'other' => q(luksemburških konvertibilnih franaka),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(luksemburški franak),
				'few' => q(luksemburška franka),
				'one' => q(luksemburški franak),
				'other' => q(luksemburških franaka),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(luksemburški financijski franak),
				'few' => q(luksemburška financijska franka),
				'one' => q(luksemburški financijski franak),
				'other' => q(luksemburških financijskih franaka),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(letonski lats),
				'few' => q(letonska latsa),
				'one' => q(letonski lats),
				'other' => q(letonskih latsa),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(letonska rublja),
				'few' => q(letonske rublje),
				'one' => q(letonska rublja),
				'other' => q(letonskih rublji),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(libijski dinar),
				'few' => q(libijska dinara),
				'one' => q(libijski dinar),
				'other' => q(libijskih dinara),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(marokanski dirham),
				'few' => q(marokanska dirhama),
				'one' => q(marokanski dirham),
				'other' => q(marokanskih dirhama),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(marokanski franak),
				'few' => q(marokanska franka),
				'one' => q(marokanski franak),
				'other' => q(marokanskih franaka),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(monegaški franak),
				'few' => q(monegaška franka),
				'one' => q(monegaški franak),
				'other' => q(monegaških franaka),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(moldavski kupon),
				'few' => q(moldavska kupona),
				'one' => q(moldavski kupon),
				'other' => q(moldavskih kupona),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldavski lej),
				'few' => q(moldavska leja),
				'one' => q(moldavski lej),
				'other' => q(moldavskih leja),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(madagaskarski ariary),
				'few' => q(madagaskarska ariarija),
				'one' => q(madagaskarski ariary),
				'other' => q(madagaskarskih ariarija),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(madagaskarski franak),
				'few' => q(madagaskarska franka),
				'one' => q(madagaskarski franak),
				'other' => q(madagaskarskih franaka),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(makedonski denar),
				'few' => q(makedonska denara),
				'one' => q(makedonski denar),
				'other' => q(makedonskih denara),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(stari makedonski denar),
				'few' => q(stara makedonska denara),
				'one' => q(stari makedonski denar),
				'other' => q(starih makedonski denara),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(malijski franak),
				'few' => q(malijska franka),
				'one' => q(malijski franak),
				'other' => q(malijskih franaka),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(mjanmarski kjat),
				'few' => q(mjanmarska kjata),
				'one' => q(mjanmarski kjat),
				'other' => q(mjanmarskih kjata),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolska tugrika),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskih tugrika),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(makaoška pataka),
				'few' => q(makaoške patake),
				'one' => q(makaoška pataka),
				'other' => q(makaoških pataka),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(mauritanijska ouguja \(1973–2017\)),
				'few' => q(mauritanijske ouguje \(1973–2017\)),
				'one' => q(mauritanijska ouguja \(1973–2017\)),
				'other' => q(mauritanijskih ouguja \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritanijska ouguja),
				'few' => q(mauritanijske ouguje),
				'one' => q(mauritanijska ouguja),
				'other' => q(mauritanijskih ouguja),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(malteška lira),
				'few' => q(malteške lire),
				'one' => q(malteška lira),
				'other' => q(malteških lira),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(malteška funta),
				'few' => q(malteške funte),
				'one' => q(malteška funta),
				'other' => q(malteških funti),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(mauricijska rupija),
				'few' => q(mauricijske rupije),
				'one' => q(mauricijska rupija),
				'other' => q(mauricijskih rupija),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(maldivijska rupija),
				'few' => q(maldivijske rupije),
				'one' => q(maldivijska rupija),
				'other' => q(maldivijskih rupija),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maldivijska rufija),
				'few' => q(maldivijske rufije),
				'one' => q(maldivijska rufija),
				'other' => q(maldivijskih rufija),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(malavijska kvača),
				'few' => q(malavijske kvače),
				'one' => q(malavijska kvača),
				'other' => q(malavijskih kvača),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(meksički pezo),
				'few' => q(meksička peza),
				'one' => q(meksički pezo),
				'other' => q(meksičkih peza),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(meksički srebrni pezo \(1861–1992\)),
				'few' => q(meksička srebrna peza \(1861–1992\)),
				'one' => q(meksički srebrni pezo \(1861–1992\)),
				'other' => q(meksičkih srebrnih peza \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(meksički unidad de inversion \(UDI\)),
				'few' => q(meksička unidads de inversion \(UDI\)),
				'one' => q(meksički unidads de inversion \(UDI\)),
				'other' => q(meksičkih unidads de inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(malezijski ringit),
				'few' => q(malezijska ringita),
				'one' => q(malezijski ringit),
				'other' => q(malezijskih ringita),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(mozambijski eskudo),
				'few' => q(mozambijska eskuda),
				'one' => q(mozambijski eskudo),
				'other' => q(mozambijskih eskuda),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(stari mozambijski metikal),
				'few' => q(stara mozambijska metikala),
				'one' => q(stari mozambijski metikal),
				'other' => q(starih mozambijskih metikala),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(mozambički metikal),
				'few' => q(mozambijska metikala),
				'one' => q(mozambijski metikal),
				'other' => q(mozambijskih metikala),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namibijski dolar),
				'few' => q(namibijska dolara),
				'one' => q(namibijski dolar),
				'other' => q(namibijskih dolara),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(nigerijska naira),
				'few' => q(nigerijska naira),
				'one' => q(nigerijski nair),
				'other' => q(nigerijskih naira),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(nikaragvanska kordoba),
				'few' => q(nikaragvanske kordobe),
				'one' => q(nikaragvanska kordoba),
				'other' => q(nikaragvanskih kordoba),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(nikaragvanska zlatna kordoba),
				'few' => q(nikaragvanske zlatne kordobe),
				'one' => q(nikaragvanska zlatna kordoba),
				'other' => q(nikaragvanskih zlatnih kordoba),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(nizozemski gulden),
				'few' => q(nizozemska guldena),
				'one' => q(nizozemski gulden),
				'other' => q(nizozemskih guldena),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(norveška kruna),
				'few' => q(norveške krune),
				'one' => q(norveška kruna),
				'other' => q(norveških kruna),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(nepalska rupija),
				'few' => q(nepalske rupije),
				'one' => q(nepalska rupija),
				'other' => q(nepalskih rupija),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(novozelandski dolar),
				'few' => q(novozelandska dolara),
				'one' => q(novozelandski dolar),
				'other' => q(novozelandskih dolara),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(omanski rijal),
				'few' => q(omanska rijala),
				'one' => q(omanski rijal),
				'other' => q(omanskih rijala),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(panamska balboa),
				'few' => q(panamske balboe),
				'one' => q(panamska balboa),
				'other' => q(panamskih balboa),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(peruanski inti),
				'few' => q(peruanske inti),
				'one' => q(peruanski inti),
				'other' => q(peruanskih inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(peruanski sol),
				'few' => q(peruanska sola),
				'one' => q(peruanski sol),
				'other' => q(peruanskih sola),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(peruanski sol \(1863–1965\)),
				'few' => q(peruanska sola \(1863–1965\)),
				'one' => q(peruanski sol \(1863–1965\)),
				'other' => q(peruanskih sola \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(kina Papue Nove Gvineje),
				'few' => q(kine Papue Nove Gvineje),
				'one' => q(kina Papue Nove Gvineje),
				'other' => q(kina Papue Nove Gvineje),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filipinski pezo),
				'few' => q(filipinska peza),
				'one' => q(filipinski pezo),
				'other' => q(filipinskih peza),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskih rupija),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(poljska zlota),
				'few' => q(poljske zlote),
				'one' => q(poljska zlota),
				'other' => q(poljskih zlota),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(poljska zlota \(1950.–1995.\)),
				'few' => q(poljske zlote \(1950.–1995.\)),
				'one' => q(poljska zlota \(1950.–1995.\)),
				'other' => q(poljskih zlota \(1950.–1995.\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(portugalski eskudo),
				'few' => q(portugalska eskuda),
				'one' => q(portugalski eskudo),
				'other' => q(portugalskih eskuda),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(paragvajski gvarani),
				'few' => q(paragvajska gvaranija),
				'one' => q(paragvajski gvarani),
				'other' => q(paragvajskih gvaranija),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(katarski rial),
				'few' => q(katarska rijala),
				'one' => q(katarski rijal),
				'other' => q(katarskih rijala),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(rodezijski dolar),
				'few' => q(rodezijska dolara),
				'one' => q(rodezijski dolar),
				'other' => q(rodezijskih dolara),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(starorumunjski lek),
				'few' => q(stara rumunjska leja),
				'one' => q(stari rumunjski lej),
				'other' => q(starih rumunjskih leja),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(rumunjski lej),
				'few' => q(rumunjska leja),
				'one' => q(rumunjski lej),
				'other' => q(rumunjskih leja),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(srpski dinar),
				'few' => q(srpska dinara),
				'one' => q(srpski dinar),
				'other' => q(srpskih dinara),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(ruska rublja),
				'few' => q(ruske rublje),
				'one' => q(ruska rublja),
				'other' => q(ruskih rublji),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(ruska rublja \(1991.–1998.\)),
				'few' => q(ruske rublje \(1991.–1998.\)),
				'one' => q(ruska rublja \(1991.–1998.\)),
				'other' => q(ruskih rublji \(1991.–1998.\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(ruandski franak),
				'few' => q(ruandska franka),
				'one' => q(ruandski franak),
				'other' => q(ruandskih franaka),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(saudijski rial),
				'few' => q(saudijska rijala),
				'one' => q(saudijski rijal),
				'other' => q(saudijskih rijala),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(solmonskootočni dolar),
				'few' => q(solomonskootočna dolara),
				'one' => q(solomonskootočni dolar),
				'other' => q(solomonskootočnih dolara),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(sejšelska rupija),
				'few' => q(sejšelske rupije),
				'one' => q(sejšelska rupija),
				'other' => q(sejšelskih rupija),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(sudanski dinar),
				'few' => q(sudanska dinara),
				'one' => q(sudanski dinar),
				'other' => q(sudanskih dinara),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(sudanska funta),
				'few' => q(sudanske funte),
				'one' => q(sudanska funta),
				'other' => q(sudanskih funti),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(stara sudanska funta),
				'few' => q(stare sudanske funte),
				'one' => q(stara sudanska funta),
				'other' => q(starih sudanskih funti),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(švedska kruna),
				'few' => q(švedske krune),
				'one' => q(švedska kruna),
				'other' => q(švedskih kruna),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurska dolara),
				'one' => q(singapurski dolar),
				'other' => q(singapurskih dolara),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(svetohelenska funta),
				'few' => q(svetohelenske funte),
				'one' => q(svetohelenska funta),
				'other' => q(svetohelenskih funti),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(slovenski tolar),
				'few' => q(slovenska tolara),
				'one' => q(slovenski tolar),
				'other' => q(slovenskih tolara),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(slovačka kruna),
				'few' => q(slovačke krune),
				'one' => q(slovačka kruna),
				'other' => q(slovačkih kruna),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(sijeraleonski leone),
				'few' => q(sijeraleonske leone),
				'one' => q(sijeraleonski leon),
				'other' => q(sijeraleonskih leona),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(somalijski šiling),
				'few' => q(somalijska šilinga),
				'one' => q(somalijski šiling),
				'other' => q(somalijskih šilinga),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(surinamski dolar),
				'few' => q(surinamska dolara),
				'one' => q(surinamski dolar),
				'other' => q(surinamskih dolara),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(surinamski gulden),
				'few' => q(surinamska guldena),
				'one' => q(surinamski gulden),
				'other' => q(surinamskih guldena),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(južnosudanska funta),
				'few' => q(južnosudanske funte),
				'one' => q(južnosudanska funta),
				'other' => q(južnosudanskih funti),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(dobra Svetog Tome i Principa \(1977–2017\)),
				'few' => q(dobre Svetog Tome i Principa \(1977–2017\)),
				'one' => q(dobra Svetog Tome i Principa \(1977–2017\)),
				'other' => q(dobri Svetog Tome i Principa \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(dobra Svetog Tome i Principa),
				'few' => q(dobre Svetog Tome i Principa),
				'one' => q(dobra Svetog Tome i Principa),
				'other' => q(dobri Svetog Tome i Principa),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(sovjetska rublja),
				'few' => q(sovjetske rublje),
				'one' => q(sovjetska rublja),
				'other' => q(sovjetskih rublji),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(salvadorski kolon),
				'few' => q(salvadorska kolona),
				'one' => q(salvadorski kolon),
				'other' => q(salvadorskih kolona),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(sirijska funta),
				'few' => q(sirijske funte),
				'one' => q(sirijska funta),
				'other' => q(sirijskih funti),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(svazi lilangeni),
				'few' => q(svazi lilangena),
				'one' => q(svazi lilangeni),
				'other' => q(svazi lilangena),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(tajlandski baht),
				'few' => q(tajlandska bahta),
				'one' => q(tajlandski baht),
				'other' => q(tajlandskih bahta),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(tajikistanska rublja),
				'few' => q(tadžikistanske rublje),
				'one' => q(tadžikistanska rublja),
				'other' => q(tadžikistanskih rublji),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(tadžikistanski somoni),
				'few' => q(tadžikistanska somona),
				'one' => q(tadžikistanski somoni),
				'other' => q(tadžikistanskih somona),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(turkmenistanski manat \(1993.–2009.\)),
				'few' => q(turkmenistanska manata \(1993.–2009.\)),
				'one' => q(turkmenistanski manat \(1993.–2009.\)),
				'other' => q(turkmenistanskih manata \(1993.–2009.\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(turkmenistanski manat),
				'few' => q(turkmenistanska manata),
				'one' => q(turkmenistanski manat),
				'other' => q(turkmenistanskih manata),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tuniski dinar),
				'few' => q(tuniska dinara),
				'one' => q(tuniski dinar),
				'other' => q(tuniskih dinara),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(tongaška pa’anga),
				'few' => q(tongaške pa’ange),
				'one' => q(tongaška pa’anga),
				'other' => q(tongaških pa’angi),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(timorski eskudo),
				'few' => q(timorska eskuda),
				'one' => q(timorski eskudo),
				'other' => q(timorskih eskuda),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(turska lira \(1922.–2005.\)),
				'few' => q(turske lire \(1922.–2005.\)),
				'one' => q(turska lira \(1922.–2005.\)),
				'other' => q(turskih lira \(1922.–2005.\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(turska lira),
				'few' => q(turske lire),
				'one' => q(turska lira),
				'other' => q(turskih lira),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(trininadtobaški dolar),
				'few' => q(trinidadtobaška dolara),
				'one' => q(trinidadtobaški dolar),
				'other' => q(trinidadtobaških dolara),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(novotajvanski dolar),
				'few' => q(novotajvanska dolara),
				'one' => q(novotajvanski dolar),
				'other' => q(novotajvanskih dolara),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzanijski šiling),
				'few' => q(tanzanijska šilinga),
				'one' => q(tanzanijski šiling),
				'other' => q(tanzanijskih šilinga),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(ukrajinska hrivnja),
				'few' => q(ukrajinske hrivnje),
				'one' => q(ukrajinska hrivnja),
				'other' => q(ukrajinskih hrivnji),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(ukrajinski karbovanet),
				'few' => q(ukrajinska karbovantsiva),
				'one' => q(ukrajinski karbovantsiv),
				'other' => q(ukrajinskih karbovantsiva),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(ugandski šiling \(1966.–1987.\)),
				'few' => q(ugandska šilinga \(1966.–1987.\)),
				'one' => q(ugandski šiling \(1966.–1987.\)),
				'other' => q(ugandskih šilinga \(1966.–1987.\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(ugandski šiling),
				'few' => q(ugandska šilinga),
				'one' => q(ugandski šiling),
				'other' => q(ugandskih šilinga),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(američki dolar),
				'few' => q(američka dolara),
				'one' => q(američki dolar),
				'other' => q(američkih dolara),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(američki dolar \(sljedeći dan\)),
				'few' => q(američka dolara \(sljedeći dan\)),
				'one' => q(američki dolar \(sljedeći dan\)),
				'other' => q(američkih dolara \(sljedeći dan\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(američki dolar \(isti dan\)),
				'few' => q(američka dolara \(isti dan\)),
				'one' => q(američki dolar \(isti dan\)),
				'other' => q(američkih dolara \(isti dan\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(urugvajski pezo en unidades indexadas),
				'few' => q(urugvajska pesosa en unidades indexadas),
				'one' => q(urugvajski pesos en unidades indexadas),
				'other' => q(urugvajskih pesosa en unidades indexadas),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(urugvajski pezo \(1975.–1993.\)),
				'few' => q(urugvajska peza \(1975.–1993.\)),
				'one' => q(urugvajski pezo \(1975.–1993.\)),
				'other' => q(urugvajskih peza \(1975.–1993.\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(urugvajski pezo),
				'few' => q(urugvajska pezosa),
				'one' => q(urugvajski pezo),
				'other' => q(urugvajskih pezosa),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(uzbekistanski som),
				'few' => q(uzbekistanska soma),
				'one' => q(uzbekistanski som),
				'other' => q(uzbekistanskih soma),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(venezuelanski bolivar \(1871.–2008.\)),
				'few' => q(venezuelanska bolivara \(1871.–2008.\)),
				'one' => q(venezuelanski bolivar \(1871.–2008.\)),
				'other' => q(venezuelanskih bolivara \(1871.–2008.\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(venezuelanski bolivar),
				'few' => q(venezuelanska bolivara),
				'one' => q(venezuelanski bolivar),
				'other' => q(venezuelanskih bolivara),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vijetnamski dong),
				'few' => q(vijetnamska donga),
				'one' => q(vijetnamski dong),
				'other' => q(vijetnamskih donga),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(vijetnamski dong \(1978.–1985.\)),
				'few' => q(vijetnamska donga \(1978.–1985.\)),
				'one' => q(vijetnamski dong \(1978.–1985.\)),
				'other' => q(vijetnamskih donga \(1978.–1985.\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatski vatu),
				'few' => q(vanuatska vatua),
				'one' => q(vanuatski vatu),
				'other' => q(vanuatskih vatua),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(samoanska tala),
				'few' => q(samoanske tale),
				'one' => q(samoanska tala),
				'other' => q(samoanskih tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA franak BEAC),
				'few' => q(CFA franka BEAC),
				'one' => q(CFA franak BEAC),
				'other' => q(CFA franaka BEAC),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(srebro),
				'few' => q(srebra),
				'one' => q(srebro),
				'other' => q(srebra),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(zlato),
				'few' => q(zlata),
				'one' => q(zlato),
				'other' => q(zlata),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(Europska složena jedinica),
				'few' => q(europske složene jedinice),
				'one' => q(europska složena jedinica),
				'other' => q(europskih složenih jedinica),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(Europska monetarna jedinica),
				'few' => q(europske monetarne jedinice),
				'one' => q(europska monetarna jedinica),
				'other' => q(europskih monetarnih jedinica),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(europska obračunska jedinica \(XBC\)),
				'few' => q(europske obračunske jedinice \(XBC\)),
				'one' => q(europska obračunska jedinica \(XBC\)),
				'other' => q(europskih obračunskih jedinica \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(europska obračunska jedinica \(XBD\)),
				'few' => q(europske obračunske jedinice \(XBD\)),
				'one' => q(europska obračunska jedinica \(XBD\)),
				'other' => q(europskih obračunskih jedinica \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(istočnokaripski dolar),
				'few' => q(istočnokaripska dolara),
				'one' => q(istočnokaripski dolar),
				'other' => q(istočnokaripskih dolara),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(posebna crtaća prava),
				'few' => q(poseebna crtaća prava),
				'one' => q(posebno crtaće pravo),
				'other' => q(posebnih crtaćih prava),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(europska monetarna jedinica \(ECU\)),
				'few' => q(europske monetarne jedinice \(ECU\)),
				'one' => q(europska monetarna jedinica \(ECU\)),
				'other' => q(europskih monetarnih jedinica \(ECU\)),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(francuski zlatni franak),
				'few' => q(francuska zlatna franka),
				'one' => q(francuski zlatni franak),
				'other' => q(francuskih zlatnih franaka),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(francuski UIC-franak),
				'few' => q(francuska UIC-franka),
				'one' => q(francuski UIC-franak),
				'other' => q(francuskih UIC-franaka),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA franak BCEAO),
				'few' => q(CFA franka BCEAO),
				'one' => q(CFA franak BCEAO),
				'other' => q(CFA franaka BCEAO),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(paladij),
				'few' => q(paladija),
				'one' => q(paladij),
				'other' => q(paladija),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(CFP franak),
				'few' => q(CFP franka),
				'one' => q(CFP franak),
				'other' => q(CFP franaka),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(platina),
				'few' => q(platine),
				'one' => q(platina),
				'other' => q(platina),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(RINET fondovi),
				'few' => q(RINET fonda),
				'one' => q(RINET fond),
				'other' => q(RINET fondova),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(sukre),
				'few' => q(sukre),
				'one' => q(sukra),
				'other' => q(sukri),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(ispitni kod valute),
				'few' => q(ispitna koda valute),
				'one' => q(ispitni kod vlaute),
				'other' => q(ispitnih kodova valute),
			},
		},
		'XUA' => {
			symbol => 'XUA',
			display_name => {
				'currency' => q(obračunska jedinica ADB),
				'few' => q(obračunske jedinice ADB),
				'one' => q(obračunska jedinica ADB),
				'other' => q(obračunskih jedinica ADB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(nepoznata valuta),
				'few' => q(nepoznata valuta),
				'one' => q(nepoznata valuta),
				'other' => q(nepoznata valuta),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(jemenski dinar),
				'few' => q(jemenska dinara),
				'one' => q(jemenski dinar),
				'other' => q(jemenskih dinara),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(jemenski rial),
				'few' => q(jemenska rijala),
				'one' => q(jemenski rijal),
				'other' => q(jemenskih rijala),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(jugoslavenski čvrsti dinar),
				'few' => q(jugoslavenska čvrsta dinara),
				'one' => q(jugoslavenski čvrsti dinar),
				'other' => q(jugoslavenskih čvrstih dinara),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(jugoslavenski novi dinar),
				'few' => q(jugoslavenska nova dinara),
				'one' => q(jugoslavenski novi dinar),
				'other' => q(jugoslavenskih novih dinara),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(jugoslavenski konvertibilni dinar),
				'few' => q(jugoslavenska konvertibilna dinara),
				'one' => q(jugoslavenski konvertibilni dinar),
				'other' => q(jugoslavenskih konvertibilnih dinara),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(jugoslavenski reformirani dinar),
				'few' => q(jugoslavenska reformirana dinara),
				'one' => q(jugoslavenski reformirani dinar),
				'other' => q(jugoslavenskih reformiranih dinara),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(južnoafrički rand \(financijski\)),
				'few' => q(južnoafrička randa \(financijska\)),
				'one' => q(južnoafrički rand \(financijski\)),
				'other' => q(južnoafričkih randa \(financijskih\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(južnoafrički rand),
				'few' => q(južnoafrička randa),
				'one' => q(južnoafrički rand),
				'other' => q(južnoafričkih randa),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(zambijska kvača \(1968–2012\)),
				'few' => q(zambijske kvače \(1968–2012\)),
				'one' => q(zambijska kvača \(1968–2012\)),
				'other' => q(zambijskih kvača \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(zambijska kvača),
				'few' => q(zambijske kvače),
				'one' => q(zambijska kvača),
				'other' => q(zambijskih kvača),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(zairski novi zair),
				'few' => q(zairska nova zaira),
				'one' => q(zairski novi zair),
				'other' => q(zairskih novih zaira),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(zairski zair),
				'few' => q(zairska zaira),
				'one' => q(zairski zair),
				'other' => q(zairskih zaira),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(zimbabveanski dolar \(1980.–2008.\)),
				'few' => q(zimbabveanska dolara \(1980.–2008.\)),
				'one' => q(zimbabveanski dolar \(1980.–2008.\)),
				'other' => q(zimbabveanskih dolara \(1980.–2008.\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(zimbabveanski dolar \(2009\)),
				'few' => q(zimbabveanska dolara \(2009\)),
				'one' => q(zimbabveanski dolar \(2009\)),
				'other' => q(zimbabveanskih dolara \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(zimbabveanski dolar \(2008\)),
				'few' => q(zimbabveanska dolara \(2008\)),
				'one' => q(zimbabveanski dolar \(2008\)),
				'other' => q(zimbabveanskih dolara \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
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
					narrow => {
						nonleap => [
							'1.',
							'2.',
							'3.',
							'4.',
							'5.',
							'6.',
							'7.',
							'8.',
							'9.',
							'10.',
							'11.',
							'12.',
							'13.'
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
							'sij',
							'velj',
							'ožu',
							'tra',
							'svi',
							'lip',
							'srp',
							'kol',
							'ruj',
							'lis',
							'stu',
							'pro'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1.',
							'2.',
							'3.',
							'4.',
							'5.',
							'6.',
							'7.',
							'8.',
							'9.',
							'10.',
							'11.',
							'12.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'siječnja',
							'veljače',
							'ožujka',
							'travnja',
							'svibnja',
							'lipnja',
							'srpnja',
							'kolovoza',
							'rujna',
							'listopada',
							'studenoga',
							'prosinca'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'sij',
							'velj',
							'ožu',
							'tra',
							'svi',
							'lip',
							'srp',
							'kol',
							'ruj',
							'lis',
							'stu',
							'pro'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1.',
							'2.',
							'3.',
							'4.',
							'5.',
							'6.',
							'7.',
							'8.',
							'9.',
							'10.',
							'11.',
							'12.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'siječanj',
							'veljača',
							'ožujak',
							'travanj',
							'svibanj',
							'lipanj',
							'srpanj',
							'kolovoz',
							'rujan',
							'listopad',
							'studeni',
							'prosinac'
						],
						leap => [
							
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
					narrow => {
						nonleap => [
							'1.',
							'2.',
							'3.',
							'4.',
							'5.',
							'6.',
							'7.',
							'8.',
							'9.',
							'10.',
							'11.',
							'12.'
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
					narrow => {
						nonleap => [
							'1.',
							'2.',
							'3.',
							'4.',
							'5.',
							'6.',
							'7.',
							'8.',
							'9.',
							'10.',
							'11.',
							'12.'
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
					narrow => {
						nonleap => [
							'1.',
							'2.',
							'3.',
							'4.',
							'5.',
							'6.',
							'7.',
							'8.',
							'9.',
							'10.',
							'11.',
							'12.'
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
						mon => 'pon',
						tue => 'uto',
						wed => 'sri',
						thu => 'čet',
						fri => 'pet',
						sat => 'sub',
						sun => 'ned'
					},
					narrow => {
						mon => 'P',
						tue => 'U',
						wed => 'S',
						thu => 'Č',
						fri => 'P',
						sat => 'S',
						sun => 'N'
					},
					short => {
						mon => 'pon',
						tue => 'uto',
						wed => 'sri',
						thu => 'čet',
						fri => 'pet',
						sat => 'sub',
						sun => 'ned'
					},
					wide => {
						mon => 'ponedjeljak',
						tue => 'utorak',
						wed => 'srijeda',
						thu => 'četvrtak',
						fri => 'petak',
						sat => 'subota',
						sun => 'nedjelja'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'pon',
						tue => 'uto',
						wed => 'sri',
						thu => 'čet',
						fri => 'pet',
						sat => 'sub',
						sun => 'ned'
					},
					narrow => {
						mon => 'p',
						tue => 'u',
						wed => 's',
						thu => 'č',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
						mon => 'pon',
						tue => 'uto',
						wed => 'sri',
						thu => 'čet',
						fri => 'pet',
						sat => 'sub',
						sun => 'ned'
					},
					wide => {
						mon => 'ponedjeljak',
						tue => 'utorak',
						wed => 'srijeda',
						thu => 'četvrtak',
						fri => 'petak',
						sat => 'subota',
						sun => 'nedjelja'
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
					abbreviated => {0 => '1kv',
						1 => '2kv',
						2 => '3kv',
						3 => '4kv'
					},
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
					},
					wide => {0 => '1. kvartal',
						1 => '2. kvartal',
						2 => '3. kvartal',
						3 => '4. kvartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1. kv.',
						1 => '2. kv.',
						2 => '3. kv.',
						3 => '4. kv.'
					},
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
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
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
					'noon' => q{podne},
					'pm' => q{PM},
					'afternoon1' => q{popodne},
					'midnight' => q{ponoć},
					'morning1' => q{ujutro},
					'night1' => q{noću},
					'evening1' => q{navečer},
					'am' => q{AM},
				},
				'wide' => {
					'midnight' => q{ponoć},
					'afternoon1' => q{poslije podne},
					'pm' => q{PM},
					'noon' => q{podne},
					'am' => q{AM},
					'evening1' => q{navečer},
					'morning1' => q{ujutro},
					'night1' => q{noću},
				},
				'narrow' => {
					'afternoon1' => q{popodne},
					'midnight' => q{ponoć},
					'noon' => q{podne},
					'pm' => q{PM},
					'evening1' => q{navečer},
					'am' => q{AM},
					'morning1' => q{ujutro},
					'night1' => q{noću},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'noon' => q{podne},
					'pm' => q{PM},
					'midnight' => q{ponoć},
					'afternoon1' => q{popodne},
					'morning1' => q{ujutro},
					'night1' => q{noću},
					'evening1' => q{navečer},
					'am' => q{AM},
				},
				'narrow' => {
					'evening1' => q{navečer},
					'am' => q{AM},
					'morning1' => q{ujutro},
					'night1' => q{noću},
					'afternoon1' => q{popodne},
					'midnight' => q{ponoć},
					'noon' => q{podne},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'evening1' => q{navečer},
					'morning1' => q{ujutro},
					'night1' => q{noću},
					'afternoon1' => q{popodne},
					'midnight' => q{ponoć},
					'pm' => q{PM},
					'noon' => q{podne},
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
		},
		'chinese' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'pr. Kr.',
				'1' => 'po. Kr.'
			},
			narrow => {
				'0' => 'pr.n.e.',
				'1' => 'AD'
			},
			wide => {
				'0' => 'prije Krista',
				'1' => 'poslije Krista'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645.-650.)',
				'1' => 'Hakuchi (650.-671.)',
				'2' => 'Hakuhō (672.-686.)',
				'3' => 'Shuchō (686.-701.)',
				'4' => 'Taihō (701.-704.)',
				'5' => 'Keiun (704.-708.)',
				'6' => 'Wadō (708.-715.)',
				'7' => 'Reiki (715.-717.)',
				'8' => 'Yōrō (717.-724.)',
				'9' => 'Jinki (724.-729.)',
				'10' => 'Tempyō (729.-749.)',
				'11' => 'Tempyō-kampō (749.-749.)',
				'12' => 'Tempyō-shōhō (749.-757.)',
				'13' => 'Tempyō-hōji (757.-765.)',
				'14' => 'Temphō-jingo (765.-767.)',
				'15' => 'Jingo-keiun (767.-770.)',
				'16' => 'Hōki (770.-780.)',
				'17' => 'Ten-ō (781.-782.)',
				'18' => 'Enryaku (782.-806.)',
				'19' => 'Daidō (806.-810.)',
				'20' => 'Kōnin (810.-824.)',
				'21' => 'Tenchō (824.-834.)',
				'22' => 'Jōwa (834.-848.)',
				'23' => 'Kajō (848.-851.)',
				'24' => 'Ninju (851.-854.)',
				'25' => 'Saiko (854.-857.)',
				'26' => 'Tennan (857.-859.)',
				'27' => 'Jōgan (859.-877.)',
				'28' => 'Genkei (877.-885.)',
				'29' => 'Ninna (885.-889.)',
				'30' => 'Kampyō (889.-898.)',
				'31' => 'Shōtai (898.-901.)',
				'32' => 'Engi (901.-923.)',
				'33' => 'Enchō (923.-931.)',
				'34' => 'Shōhei (931.-938.)',
				'35' => 'Tengyō (938.-947.)',
				'36' => 'Tenryaku (947.-957.)',
				'37' => 'Tentoku (957.-961.)',
				'38' => 'Ōwa (961.-964.)',
				'39' => 'Kōhō (964.-968.)',
				'40' => 'Anna (968.-970.)',
				'41' => 'Tenroku (970.-973.)',
				'42' => 'Ten-en (973.-976.)',
				'43' => 'Jōgen (976.-978.)',
				'44' => 'Tengen (978.-983.)',
				'45' => 'Eikan (983.-985.)',
				'46' => 'Kanna (985.-987.)',
				'47' => 'Ei-en (987.-989.)',
				'48' => 'Eiso (989.-990.)',
				'49' => 'Shōryaku (990.-995.)',
				'50' => 'Chōtoku (995.-999.)',
				'51' => 'Chōhō (999.-1004.)',
				'52' => 'Kankō (1004.-1012.)',
				'53' => 'Chōwa (1012.-1017.)',
				'54' => 'Kannin (1017.-1021.)',
				'55' => 'Jian (1021.-1024.)',
				'56' => 'Manju (1024.-1028.)',
				'57' => 'Chōgen (1028.-1037.)',
				'58' => 'Chōryaku (1037.-1040.)',
				'59' => 'Chōkyū (1040.-1044.)',
				'60' => 'Kantoku (1044.-1046.)',
				'61' => 'Eishō (1046.-1053.)',
				'62' => 'Tengi (1053.-1058.)',
				'63' => 'Kōhei (1058.-1065.)',
				'64' => 'Jiryaku (1065.-1069.)',
				'65' => 'Enkyū (1069.-1074.)',
				'66' => 'Shōho (1074.-1077.)',
				'67' => 'Shōryaku (1077.-1081.)',
				'68' => 'Eiho (1081.-1084.)',
				'69' => 'Ōtoku (1084.-1087.)',
				'70' => 'Kanji (1087.-1094.)',
				'71' => 'Kaho (1094.-1096.)',
				'72' => 'Eichō (1096.-1097.)',
				'73' => 'Shōtoku (1097.-1099.)',
				'74' => 'Kōwa (1099.-1104.)',
				'75' => 'Chōji (1104.-1106.)',
				'76' => 'Kashō (1106.-1108.)',
				'77' => 'Tennin (1108.-1110.)',
				'78' => 'Ten-ei (1110.-1113.)',
				'79' => 'Eikyū (1113.-1118.)',
				'80' => 'Gen-ei (1118.-1120.)',
				'81' => 'Hoan (1120.-1124.)',
				'82' => 'Tenji (1124.-1126.)',
				'83' => 'Daiji (1126.-1131.)',
				'84' => 'Tenshō (1131.-1132.)',
				'85' => 'Chōshō (1132.-1135.)',
				'86' => 'Hoen (1135.-1141.)',
				'87' => 'Eiji (1141.-1142.)',
				'88' => 'Kōji (1142.-1144.)',
				'89' => 'Tenyō (1144.-1145.)',
				'90' => 'Kyūan (1145.-1151.)',
				'91' => 'Ninpei (1151.-1154.)',
				'92' => 'Kyūju (1154.-1156.)',
				'93' => 'Hogen (1156.-1159.)',
				'94' => 'Heiji (1159.-1160.)',
				'95' => 'Eiryaku (1160.-1161.)',
				'96' => 'Ōho (1161.-1163.)',
				'97' => 'Chōkan (1163.-1165.)',
				'98' => 'Eiman (1165.-1166.)',
				'99' => 'Nin-an (1166.-1169.)',
				'100' => 'Kaō (1169.-1171.)',
				'101' => 'Shōan (1171.-1175.)',
				'102' => 'Angen (1175.-1177.)',
				'103' => 'Jishō (1177.-1181.)',
				'104' => 'Yōwa (1181.-1182.)',
				'105' => 'Juei (1182.-1184.)',
				'106' => 'Genryuku (1184.-1185.)',
				'107' => 'Bunji (1185.-1190.)',
				'108' => 'Kenkyū (1190.-1199.)',
				'109' => 'Shōji (1199.-1201.)',
				'110' => 'Kennin (1201.-1204.)',
				'111' => 'Genkyū (1204.-1206.)',
				'112' => 'Ken-ei (1206.-1207.)',
				'113' => 'Shōgen (1207.-1211.)',
				'114' => 'Kenryaku (1211.-1213.)',
				'115' => 'Kenpō (1213.-1219.)',
				'116' => 'Shōkyū (1219.-1222.)',
				'117' => 'Jōō (1222.-1224.)',
				'118' => 'Gennin (1224.-1225.)',
				'119' => 'Karoku (1225.-1227.)',
				'120' => 'Antei (1227.-1229.)',
				'121' => 'Kanki (1229.-1232.)',
				'122' => 'Jōei (1232.-1233.)',
				'123' => 'Tempuku (1233.-1234.)',
				'124' => 'Bunryaku (1234.-1235.)',
				'125' => 'Katei (1235.-1238.)',
				'126' => 'Ryakunin (1238.-1239.)',
				'127' => 'En-ō (1239.-1240.)',
				'128' => 'Ninji (1240.-1243.)',
				'129' => 'Kangen (1243.-1247.)',
				'130' => 'Hōji (1247.-1249.)',
				'131' => 'Kenchō (1249.-1256.)',
				'132' => 'Kōgen (1256.-1257.)',
				'133' => 'Shōka (1257.-1259.)',
				'134' => 'Shōgen (1259.-1260.)',
				'135' => 'Bun-ō (1260.-1261.)',
				'136' => 'Kōchō (1261.-1264.)',
				'137' => 'Bun-ei (1264.-1275.)',
				'138' => 'Kenji (1275.-1278.)',
				'139' => 'Kōan (1278.-1288.)',
				'140' => 'Shōō (1288.-1293.)',
				'141' => 'Einin (1293.-1299.)',
				'142' => 'Shōan (1299.-1302.)',
				'143' => 'Kengen (1302.-1303.)',
				'144' => 'Kagen (1303.-1306.)',
				'145' => 'Tokuji (1306.-1308.)',
				'146' => 'Enkei (1308.-1311.)',
				'147' => 'Ōchō (1311.-1312.)',
				'148' => 'Shōwa (1312.-1317.)',
				'149' => 'Bunpō (1317.-1319.)',
				'150' => 'Genō (1319.-1321.)',
				'151' => 'Genkyō (1321.-1324.)',
				'152' => 'Shōchū (1324.-1326.)',
				'153' => 'Kareki (1326.-1329.)',
				'154' => 'Gentoku (1329.-1331.)',
				'155' => 'Genkō (1331.-1334.)',
				'156' => 'Kemmu (1334.-1336.)',
				'157' => 'Engen (1336.-1340.)',
				'158' => 'Kōkoku (1340.-1346.)',
				'159' => 'Shōhei (1346.-1370.)',
				'160' => 'Kentoku (1370.-1372.)',
				'161' => 'Bunchū (1372.-1375.)',
				'162' => 'Tenju (1375.-1379.)',
				'163' => 'Kōryaku (1379.-1381.)',
				'164' => 'Kōwa (1381.-1384.)',
				'165' => 'Genchū (1384.-1392.)',
				'166' => 'Meitoku (1384.-1387.)',
				'167' => 'Kakei (1387.-1389.)',
				'168' => 'Kōō (1389.-1390.)',
				'169' => 'Meitoku (1390.-1394.)',
				'170' => 'Ōei (1394.-1428.)',
				'171' => 'Shōchō (1428.-1429.)',
				'172' => 'Eikyō (1429.-1441.)',
				'173' => 'Kakitsu (1441.-1444.)',
				'174' => 'Bun-an (1444.-1449.)',
				'175' => 'Hōtoku (1449.-1452.)',
				'176' => 'Kyōtoku (1452.-1455.)',
				'177' => 'Kōshō (1455.-1457.)',
				'178' => 'Chōroku (1457.-1460.)',
				'179' => 'Kanshō (1460.-1466.)',
				'180' => 'Bunshō (1466.-1467.)',
				'181' => 'Ōnin (1467.-1469.)',
				'182' => 'Bunmei (1469.-1487.)',
				'183' => 'Chōkyō (1487.-1489.)',
				'184' => 'Entoku (1489.-1492.)',
				'185' => 'Meiō (1492.-1501.)',
				'186' => 'Bunki (1501.-1504.)',
				'187' => 'Eishō (1504.-1521.)',
				'188' => 'Taiei (1521.-1528.)',
				'189' => 'Kyōroku (1528.-1532.)',
				'190' => 'Tenmon (1532.-1555.)',
				'191' => 'Kōji (1555.-1558.)',
				'192' => 'Eiroku (1558.-1570.)',
				'193' => 'Genki (1570.-1573.)',
				'194' => 'Tenshō (1573.-1592.)',
				'195' => 'Bunroku (1592.-1596.)',
				'196' => 'Keichō (1596.-1615.)',
				'197' => 'Genwa (1615.-1624.)',
				'198' => 'Kan-ei (1624.-1644.)',
				'199' => 'Shōho (1644.-1648.)',
				'200' => 'Keian (1648.-1652.)',
				'201' => 'Shōō (1652.-1655.)',
				'202' => 'Meiryaku (1655.-1658.)',
				'203' => 'Manji (1658.-1661.)',
				'204' => 'Kanbun (1661.-1673.)',
				'205' => 'Enpō (1673.-1681.)',
				'206' => 'Tenwa (1681.-1684.)',
				'207' => 'Jōkyō (1684.-1688.)',
				'208' => 'Genroku (1688.-1704.)',
				'209' => 'Hōei (1704.-1711.)',
				'210' => 'Shōtoku (1711.-1716.)',
				'211' => 'Kyōhō (1716.-1736.)',
				'212' => 'Genbun (1736.-1741.)',
				'213' => 'Kanpō (1741.-1744.)',
				'214' => 'Enkyō (1744.-1748.)',
				'215' => 'Kan-en (1748.-1751.)',
				'216' => 'Hōryaku (1751.-1764.)',
				'217' => 'Meiwa (1764.-1772.)',
				'218' => 'An-ei (1772.-1781.)',
				'219' => 'Tenmei (1781.-1789.)',
				'220' => 'Kansei (1789.-1801.)',
				'221' => 'Kyōwa (1801.-1804.)',
				'222' => 'Bunka (1804.-1818.)',
				'223' => 'Bunsei (1818.-1830.)',
				'224' => 'Tenpō (1830.-1844.)',
				'225' => 'Kōka (1844.-1848.)',
				'226' => 'Kaei (1848.-1854.)',
				'227' => 'Ansei (1854.-1860.)',
				'228' => 'Man-en (1860.-1861.)',
				'229' => 'Bunkyū (1861.-1864.)',
				'230' => 'Genji (1864.-1865.)',
				'231' => 'Keiō (1865.-1868.)',
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
		},
		'roc' => {
			abbreviated => {
				'0' => 'prije R.O.C.',
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
		},
		'chinese' => {
			'full' => q{E, d. M. y.},
			'long' => q{d. M. y.},
			'medium' => q{d. M. y.},
			'short' => q{d. M. y.},
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d. MMMM y. G},
			'long' => q{d. MMMM y. G},
			'medium' => q{d. MMM y. G},
			'short' => q{dd. MM. y. GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y.},
			'long' => q{d. MMMM y.},
			'medium' => q{d. MMM y.},
			'short' => q{dd. MM. y.},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{EEEE, d. MMMM y. G},
			'long' => q{d. MMMM y. G},
			'medium' => q{d. M. y. G},
			'short' => q{d. M. y. GGGGG},
		},
		'japanese' => {
			'full' => q{EEEE, d. MMMM y. G},
			'long' => q{d. MMMM y. G},
			'medium' => q{d. M. y. G},
			'short' => q{d. M. y. GGGGG},
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
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss (zzzz)},
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
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} 'u' {0}},
			'long' => q{{1} 'u' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'u' {0}},
			'long' => q{{1} 'u' {0}},
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
		'japanese' => {
			Ed => q{E, d.},
			Gy => q{y. GGG},
			GyMMM => q{LLL y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			M => q{L.},
			MEd => q{E, d. M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d.},
			y => q{y. GGG},
			yM => q{M. y. GGGGG},
			yMEd => q{E, d. M. y. GGGGG},
			yMMM => q{LLL y. GGGGG},
			yMMMEd => q{E, d. MMM y. GGGGG},
			yMMMd => q{d. MMM y. GGGGG},
			yMd => q{d. M. y. GGGGG},
			yQQQ => q{QQQ y. GGGGG},
			yyyy => q{y. G},
			yyyyM => q{M. y. G},
			yyyyMEd => q{E, d. M. y. G},
			yyyyMMM => q{LLL y. G},
			yyyyMMMEd => q{E, d. MMM y. G},
			yyyyMMMM => q{LLLL y. G},
			yyyyMMMd => q{d. MMM y. G},
			yyyyMd => q{d. M. y. G},
			yyyyQQQ => q{QQQ y. G},
			yyyyQQQQ => q{QQQQ y. G},
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
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{LLL y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L.},
			MEd => q{E, dd. MM.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd. MM.},
			d => q{d.},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			ms => q{mm:ss},
			y => q{y. G},
			yyyy => q{y. G},
			yyyyM => q{MM. y. GGGGG},
			yyyyMEd => q{E, dd. MM. y. GGGGG},
			yyyyMMM => q{LLL y. G},
			yyyyMMMEd => q{E, d. MMM y. G},
			yyyyMMMM => q{LLLL y. G},
			yyyyMMMd => q{d. MMM y. G},
			yyyyMd => q{dd. MM. y. GGGGG},
			yyyyQQQ => q{QQQ y. G},
			yyyyQQQQ => q{QQQQ y. G},
		},
		'islamic' => {
			Ed => q{E, d.},
			Gy => q{y. G},
			GyMMM => q{LLL y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			M => q{L.},
			MEd => q{E, d. M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d.},
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
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{LLL y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L.},
			MEd => q{E, dd. MM.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{W. 'tjedan' 'u' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{dd. MM.},
			Md => q{dd. MM.},
			d => q{d.},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y.},
			yM => q{MM. y.},
			yMEd => q{E, dd. MM. y.},
			yMM => q{MM. y.},
			yMMM => q{LLL y.},
			yMMMEd => q{E, d. MMM y.},
			yMMMM => q{LLLL y.},
			yMMMd => q{d. MMM y.},
			yMd => q{dd. MM. y.},
			yQQQ => q{QQQ y.},
			yQQQQ => q{QQQQ y.},
			yw => q{w. 'tjedan' 'u' Y.},
		},
		'roc' => {
			M => q{L.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			d => q{d.},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} ({1})',
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
				H => q{HH – HH'h'},
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
				H => q{HH – HH 'h' v},
			},
			M => {
				M => q{MM. – MM.},
			},
			MEd => {
				M => q{E, dd. MM. – E, dd. MM.},
				d => q{E, dd. MM. – E, dd. MM.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, dd. MMM – E, dd. MMM},
				d => q{E, dd. – E, dd. MMM},
			},
			MMMd => {
				M => q{dd. MMM – dd. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{dd. MM. – dd. MM.},
				d => q{dd. MM. – dd. MM.},
			},
			d => {
				d => q{dd. – dd.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h'h' a},
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
				h => q{h – h 'h' a v},
			},
			y => {
				y => q{y. – y. G},
			},
			yM => {
				M => q{MM. y. – MM. y. G},
				y => q{MM. y. – MM. y. G},
			},
			yMEd => {
				M => q{E, dd. MM. y. – E, dd. MM. y. G},
				d => q{E, dd. MM. y. – E, dd. MM. y. G},
				y => q{E, dd. MM. y. – E, dd. MM. y. G},
			},
			yMMM => {
				M => q{LLL – LLL y. G},
				y => q{LLL y. – LLL y. G},
			},
			yMMMEd => {
				M => q{E, dd. MMM – E, dd. MMM y. G},
				d => q{E, dd. – E, dd. MMM y. G},
				y => q{E, dd. MMM y. – E, dd. MMM y. G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y. G},
				y => q{LLLL y. – LLLL y. G},
			},
			yMMMd => {
				M => q{dd. MMM – dd. MMM y. G},
				d => q{dd. – dd. MMM y. G},
				y => q{dd. MMM y. – dd. MMM y. G},
			},
			yMd => {
				M => q{dd. MM. y. – dd. MM. y. G},
				d => q{dd. MM. y. – dd. MM. y. G},
				y => q{dd. MM. y. – dd. MM. y. G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH – HH 'h'},
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
				H => q{HH – HH 'h' v},
			},
			M => {
				M => q{MM. – MM.},
			},
			MEd => {
				M => q{E, dd. MM. – E, dd. MM.},
				d => q{E, dd. MM. – E, dd. MM.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, dd. MMM – E, dd. MMM},
				d => q{E, dd. – E, dd. MMM},
			},
			MMMd => {
				M => q{dd. MMM – dd. MMM},
				d => q{dd. – dd. MMM},
			},
			Md => {
				M => q{dd. MM. – dd. MM.},
				d => q{dd. MM. – dd. MM.},
			},
			d => {
				d => q{dd. – dd.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h 'h' a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h 'h' a v},
			},
			y => {
				y => q{y. – y.},
			},
			yM => {
				M => q{MM. y. – MM. y.},
				y => q{MM. y. – MM. y.},
			},
			yMEd => {
				M => q{E, dd. MM. y. – E, dd. MM. y.},
				d => q{E, dd. MM. y. – E, dd. MM. y.},
				y => q{E, dd. MM. y. – E, dd. MM. y.},
			},
			yMMM => {
				M => q{LLL – LLL y.},
				y => q{LLL y. – LLL y.},
			},
			yMMMEd => {
				M => q{E, dd. MMM – E, dd. MMM y.},
				d => q{E, dd. – E, dd. MMM y.},
				y => q{E, dd. MMM y. – E, dd. MMM y.},
			},
			yMMMM => {
				M => q{LLLL – LLLL y.},
				y => q{LLLL y. – LLLL y.},
			},
			yMMMd => {
				M => q{dd. MMM – dd. MMM y.},
				d => q{dd. – dd. MMM y.},
				y => q{dd. MMM y. – dd. MMM y.},
			},
			yMd => {
				M => q{dd. MM. y. – dd. MM. y.},
				d => q{dd. MM. y. – dd. MM. y.},
				y => q{dd. MM. y. – dd. MM. y.},
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
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(spring begins),
						1 => q(rain water),
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
		hourFormat => q(+HH:mm; -HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0}, ljetno vrijeme),
		regionFormat => q({0}, standardno vrijeme),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre ljetno vrijeme#,
				'generic' => q#Acre vrijeme#,
				'standard' => q#Acre standardno vrijeme#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#afganistansko vrijeme#,
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
			exemplarCity => q#Alžir#,
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
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
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
				'standard' => q#srednjoafričko vrijeme#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#istočnoafričko vrijeme#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#južnoafričko vrijeme#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#zapadnoafričko ljetno vrijeme#,
				'generic' => q#zapadnoafričko vrijeme#,
				'standard' => q#zapadnoafričko standardno vrijeme#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#aljaško ljetno vrijeme#,
				'generic' => q#aljaško vrijeme#,
				'standard' => q#aljaško standardno vrijeme#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#altmajsko ljetno vrijeme#,
				'generic' => q#altmajsko vrijeme#,
				'standard' => q#altmajsko standardno vrijeme#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#amazonsko ljetno vrijeme#,
				'generic' => q#amazonsko vrijeme#,
				'standard' => q#amazonsko standardno vrijeme#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angvila#,
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
			exemplarCity => q#Tucuman#,
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
			exemplarCity => q#Bahia Banderas#,
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
			exemplarCity => q#Bogota#,
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
			exemplarCity => q#Cancun#,
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
			exemplarCity => q#Kajman#,
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
			exemplarCity => q#Kostarika#,
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
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
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
			exemplarCity => q#Guadalupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gvajana#,
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
			exemplarCity => q#Jamajka#,
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
			exemplarCity => q#Martinique#,
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
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de México#,
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
			exemplarCity => q#Beulah, Sjeverna Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Sjeverna Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Sjeverna Dakota#,
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
			exemplarCity => q#Portoriko#,
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
			exemplarCity => q#Saint Barthélemy#,
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
		'America_Central' => {
			long => {
				'daylight' => q#središnje ljetno vrijeme#,
				'generic' => q#središnje vrijeme#,
				'standard' => q#središnje standardno vrijeme#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#istočno ljetno vrijeme#,
				'generic' => q#istočno vrijeme#,
				'standard' => q#istočno standardno vrijeme#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#planinsko ljetno vrijeme#,
				'generic' => q#planinsko vrijeme#,
				'standard' => q#planinsko standardno vrijeme#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#pacifičko ljetno vrijeme#,
				'generic' => q#pacifičko vrijeme#,
				'standard' => q#pacifičko standardno vrijeme#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#anadirsko ljetno vrijeme#,
				'generic' => q#anadirsko vrijeme#,
				'standard' => q#anadirsko standardno vrijeme#,
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
				'daylight' => q#ljetno vrijeme Apije#,
				'generic' => q#vrijeme Apije#,
				'standard' => q#standardno vrijeme Apije#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#ljetno vrijeme grada Aktau#,
				'generic' => q#vrijeme grada Aktau#,
				'standard' => q#standardno vrijeme grada Aktau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#ljetno vrijeme grada Aktobe#,
				'generic' => q#vrijeme grada Aktobe#,
				'standard' => q#standardno vrijeme grada Aktobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arapsko ljetno vrijeme#,
				'generic' => q#arapsko vrijeme#,
				'standard' => q#arapsko standardno vrijeme#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentinsko ljetno vrijeme#,
				'generic' => q#argentinsko vrijeme#,
				'standard' => q#argentinsko standardno vrijeme#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#zapadnoargentinsko ljetno vrijeme#,
				'generic' => q#zapadnoargentinsko vrijeme#,
				'standard' => q#zapadnoargentinsko standardno vrijeme#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armensko ljetno vrijeme#,
				'generic' => q#armensko vrijeme#,
				'standard' => q#armensko standardno vrijeme#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma Ata#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
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
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunej#,
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
			exemplarCity => q#Damask#,
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
			exemplarCity => q#Dušanbe#,
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
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Džakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
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
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
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
			exemplarCity => q#Nikozija#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznjeck#,
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
			exemplarCity => q#Pjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Ši Min#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šangaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
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
			exemplarCity => q#Ulan Bator#,
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
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlantsko ljetno vrijeme#,
				'generic' => q#atlantsko vrijeme#,
				'standard' => q#atlantsko standardno vrijeme#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorski otoci#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Zelenortski Otoci#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ferojski otoci#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Južna Georgija#,
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
		'Australia_Central' => {
			long => {
				'daylight' => q#srednjoaustralsko ljetno vrijeme#,
				'generic' => q#srednjoaustralsko vrijeme#,
				'standard' => q#srednjoaustralsko standardno vrijeme#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#australsko središnje zapadno ljetno vrijeme#,
				'generic' => q#australsko središnje zapadno vrijeme#,
				'standard' => q#australsko središnje zapadno standardno vrijeme#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#istočnoaustralsko ljetno vrijeme#,
				'generic' => q#istočnoaustralsko vrijeme#,
				'standard' => q#istočnoaustralsko standardno vrijeme#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#zapadnoaustralsko ljetno vrijeme#,
				'generic' => q#zapadnoaustralsko vrijeme#,
				'standard' => q#zapadnoaustralsko standardno vrijeme#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#azerbajdžansko ljetno vrijeme#,
				'generic' => q#azerbajdžansko vrijeme#,
				'standard' => q#azerbajdžansko standardno vrijeme#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#azorsko ljetno vrijeme#,
				'generic' => q#azorsko vrijeme#,
				'standard' => q#azorsko standardno vrijeme#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladeško ljetno vrijeme#,
				'generic' => q#bangladeško vrijeme#,
				'standard' => q#bangladeško standardno vrijeme#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#butansko vrijeme#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#bolivijsko vrijeme#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#brazilijsko ljetno vrijeme#,
				'generic' => q#brazilijsko vrijeme#,
				'standard' => q#brazilijsko standardno vrijeme#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#vrijeme za Brunej Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ljetno vrijeme Zelenortskog otočja#,
				'generic' => q#vrijeme Zelenortskog otočja#,
				'standard' => q#standardno vrijeme Zelenortskog otočja#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#vrijeme Caseyja#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#standardno vrijeme Chamorra#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ljetno vrijeme Chathama#,
				'generic' => q#vrijeme Chathama#,
				'standard' => q#standardno vrijeme Chathama#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#čileansko ljetno vrijeme#,
				'generic' => q#čileansko vrijeme#,
				'standard' => q#čileansko standardno vrijeme#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#kinesko ljetno vrijeme#,
				'generic' => q#kinesko vrijeme#,
				'standard' => q#kinesko standardno vrijeme#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#choibalsansko ljetno vrijeme#,
				'generic' => q#choibalsansko vrijeme#,
				'standard' => q#choibalsansko standardno vrijeme#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#vrijeme Božićnog otoka#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#vrijeme Kokosovih otoka#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolumbijsko ljetno vrijeme#,
				'generic' => q#kolumbijsko vrijeme#,
				'standard' => q#kolumbijsko standardno vrijeme#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookovi otoci, polusatni pomak, ljetno vrijeme#,
				'generic' => q#vrijeme Cookovih otoka#,
				'standard' => q#standardno vrijeme Cookovih otoka#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubansko ljetno vrijeme#,
				'generic' => q#kubansko vrijeme#,
				'standard' => q#kubansko standardno vrijeme#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#vrijeme Davisa#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#vrijeme Dumont-d’Urvillea#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#istočnotimorsko vrijeme#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ljetno vrijeme Uskršnjeg otoka#,
				'generic' => q#vrijeme Uskršnjeg otoka#,
				'standard' => q#standardno vrijeme Uskršnjeg otoka#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ekvadorsko vrijeme#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinirano svjetsko vrijeme#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Nepoznati grad#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukurešt#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budimpešta#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišinjev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#irsko standardno vrijeme#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Otok Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalinjingrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#britansko ljetno vrijeme#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburg#,
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
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariz#,
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
			exemplarCity => q#Rim#,
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
			exemplarCity => q#Skoplje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
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
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Beč#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporožje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#srednjoeuropsko ljetno vrijeme#,
				'generic' => q#srednjoeuropsko vrijeme#,
				'standard' => q#srednjoeuropsko standardno vrijeme#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#istočnoeuropsko ljetno vrijeme#,
				'generic' => q#istočnoeuropsko vrijeme#,
				'standard' => q#istočnoeuropsko standardno vrijeme#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#dalekoistočno europsko vrijeme#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#zapadnoeuropsko ljetno vrijeme#,
				'generic' => q#zapadnoeuropsko vrijeme#,
				'standard' => q#zapadnoeuropsko standardno vrijeme#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#falklandsko ljetno vrijeme#,
				'generic' => q#falklandsko vrijeme#,
				'standard' => q#falklandsko standardno vrijeme#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ljetno vrijeme Fidžija#,
				'generic' => q#vrijeme Fidžija#,
				'standard' => q#standardno vrijeme Fidžija#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#vrijeme Francuske Gvajane#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#južnofrancusko i antarktičko vrijeme#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#univerzalno vrijeme#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#vrijeme Galapagosa#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#vrijeme Gambiera#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#gruzijsko ljetno vrijeme#,
				'generic' => q#gruzijsko vrijeme#,
				'standard' => q#gruzijsko standardno vrijeme#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#vrijeme Gilbertovih otoka#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#istočnogrenlandsko ljetno vrijeme#,
				'generic' => q#istočnogrenlandsko vrijeme#,
				'standard' => q#istočnogrenlandsko standardno vrijeme#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#zapadnogrenlandsko ljetno vrijeme#,
				'generic' => q#zapadnogrenlandsko vrijeme#,
				'standard' => q#zapadnogrenlandsko standardno vrijeme#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#guamsko standardno vrijeme#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#zaljevsko standardno vrijeme#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#gvajansko vrijeme#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#havajsko-aleutsko ljetno vrijeme#,
				'generic' => q#havajsko-aleutsko vrijeme#,
				'standard' => q#havajsko-aleutsko standardno vrijeme#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hongkonško ljetno vrijeme#,
				'generic' => q#hongkonško vrijeme#,
				'standard' => q#hongkonško standardno vrijeme#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#hovdsko ljetno vrijeme#,
				'generic' => q#hovdsko vrijeme#,
				'standard' => q#hovdsko standardno vrijeme#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indijsko vrijeme#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Božićni otok#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosovi otoci#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komori#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivi#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricijus#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#vrijeme Indijskog oceana#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indokinesko vrijeme#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#srednjoindonezijsko vrijeme#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#istočnoindonezijsko vrijeme#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#zapadnoindonezijsko vrijeme#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iransko ljetno vrijeme#,
				'generic' => q#iransko vrijeme#,
				'standard' => q#iransko standardno vrijeme#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#irkutsko ljetno vrijeme#,
				'generic' => q#irkutsko vrijeme#,
				'standard' => q#irkutsko standardno vrijeme#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#izraelsko ljetno vrijeme#,
				'generic' => q#izraelsko vrijeme#,
				'standard' => q#izraelsko standardno vrijeme#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japansko ljetno vrijeme#,
				'generic' => q#japansko vrijeme#,
				'standard' => q#japansko standardno vrijeme#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-kamčatsko ljetno vrijeme#,
				'generic' => q#Petropavlovsk-kamčatsko vrijeme#,
				'standard' => q#Petropavlovsk-kamčatsko standardno vrijeme#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#istočnokazahstansko vrijeme#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#zapadnokazahstansko vrijeme#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#korejsko ljetno vrijeme#,
				'generic' => q#korejsko vrijeme#,
				'standard' => q#korejsko standardno vrijeme#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#vrijeme Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#krasnojarsko ljetno vrijeme#,
				'generic' => q#krasnojarsko vrijeme#,
				'standard' => q#krasnojarsko standardno vrijeme#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgistansko vrijeme#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#lankansko vrijeme#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#vrijeme Otoka Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ljetno vrijeme otoka Lord Howe#,
				'generic' => q#vrijeme otoka Lord Howe#,
				'standard' => q#standardno vrijeme otoka Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#ljetno makaosko vrijeme#,
				'generic' => q#makaosko vrijeme#,
				'standard' => q#standardno makaosko vrijeme#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#vrijeme otoka Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#magadansko ljetno vrijeme#,
				'generic' => q#magadansko vrijeme#,
				'standard' => q#magadansko standardno vrijeme#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malezijsko vrijeme#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maldivsko vrijeme#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#markižansko vrijeme#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#vrijeme Maršalovih Otoka#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ljetno vrijeme Mauricijusa#,
				'generic' => q#vrijeme Mauricijusa#,
				'standard' => q#standardno vrijeme Mauricijusa#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#mawsonsko vrijeme#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#sjeverozapadno meksičko ljetno vrijeme#,
				'generic' => q#sjeverozapadno meksičko vrijeme#,
				'standard' => q#sjeverozapadno meksičko standardno vrijeme#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#meksičko pacifičko ljetno vrijeme#,
				'generic' => q#meksičko pacifičko vrijeme#,
				'standard' => q#meksičko pacifičko standardno vrijeme#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ulanbatorsko ljetno vrijeme#,
				'generic' => q#ulanbatorsko vrijeme#,
				'standard' => q#ulanbatorsko standardno vrijeme#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#moskovsko ljetno vrijeme#,
				'generic' => q#moskovsko vrijeme#,
				'standard' => q#moskovsko standardno vrijeme#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#mjanmarsko vrijeme#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#vrijeme Naurua#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepalsko vrijeme#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#ljetno vrijeme Nove Kaledonije#,
				'generic' => q#vrijeme Nove Kaledonije#,
				'standard' => q#standardno vrijeme Nove Kaledonije#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#novozelandsko ljetno vrijeme#,
				'generic' => q#novozelandsko vrijeme#,
				'standard' => q#novozelandsko standardno vrijeme#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#newfoundlandsko ljetno vrijeme#,
				'generic' => q#newfoundlandsko vrijeme#,
				'standard' => q#newfoundlandsko standardno vrijeme#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#vrijeme Niuea#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#vrijeme Otoka Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ljetno vrijeme grada Fernando de Noronha#,
				'generic' => q#vrijeme grada Fernando de Noronha#,
				'standard' => q#standardno vrijeme grada Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#vrijeme Sjevernomarijanskih Otoka#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#novosibirsko ljetno vrijeme#,
				'generic' => q#novosibirsko vrijeme#,
				'standard' => q#novosibirsko standardno vrijeme#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#omsko ljetno vrijeme#,
				'generic' => q#omsko vrijeme#,
				'standard' => q#omsko standardno vrijeme#,
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
			exemplarCity => q#Uskršnji otok#,
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
			exemplarCity => q#Fidži#,
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
			exemplarCity => q#Markižansko otočje#,
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
				'daylight' => q#pakistansko ljetno vrijeme#,
				'generic' => q#pakistansko vrijeme#,
				'standard' => q#pakistansko standardno vrijeme#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#vrijeme Palaua#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#vrijeme Papue Nove Gvineje#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paragvajsko ljetno vrijeme#,
				'generic' => q#paragvajsko vrijeme#,
				'standard' => q#paragvajsko standardno vrijeme#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruansko ljetno vrijeme#,
				'generic' => q#peruansko vrijeme#,
				'standard' => q#peruansko standardno vrijeme#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filipinsko ljetno vrijeme#,
				'generic' => q#filipinsko vrijeme#,
				'standard' => q#filipinsko standardno vrijeme#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#vrijeme Otoka Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ljetno vrijeme za Sveti Petar i Mikelon#,
				'generic' => q#vrijeme za Sveti Petar i Mikelon#,
				'standard' => q#standardno vrijeme za Sveti Petar i Mikelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#vrijeme Pitcairna#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#vrijeme Ponapea#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#pjongjanško vrijeme#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#ljetno vrijeme grada Kizilorde#,
				'generic' => q#vrijeme grada Kizilorde#,
				'standard' => q#standardno vrijeme grada Kizilorde#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#vrijeme Reuniona#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#vrijeme Rothere#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sahalinsko ljetno vrijeme#,
				'generic' => q#sahalinsko vrijeme#,
				'standard' => q#sahalinsko standardno vrijeme#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#samarsko ljetno vrijeme#,
				'generic' => q#samarsko vrijeme#,
				'standard' => q#samarsko standardno vrijeme#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoansko ljetno vrijeme#,
				'generic' => q#samoansko vrijeme#,
				'standard' => q#samoansko standardno vrijeme#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#sejšelsko vrijeme#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singapursko vrijeme#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#vrijeme Salomonskih Otoka#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#vrijeme Južne Georgije#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinamsko vrijeme#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#vrijeme Syowe#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#vrijeme Tahitija#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#tajpeško ljetno vrijeme#,
				'generic' => q#tajpeško vrijeme#,
				'standard' => q#tajpeško standardno vrijeme#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tadžikistansko vrijeme#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#vrijeme Tokelaua#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ljetno vrijeme Tonge#,
				'generic' => q#vrijeme Tonge#,
				'standard' => q#standardno vrijeme Tonge#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#vrijeme Chuuka#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmenistansko ljetno vrijeme#,
				'generic' => q#turkmenistansko vrijeme#,
				'standard' => q#turkmenistansko standardno vrijeme#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#vrijeme Tuvalua#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#urugvajsko ljetno vrijeme#,
				'generic' => q#urugvajsko vrijeme#,
				'standard' => q#urugvajsko standardno vrijeme#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzbekistansko ljetno vrijeme#,
				'generic' => q#uzbekistansko vrijeme#,
				'standard' => q#uzbekistansko standardno vrijeme#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ljetno vrijeme Vanuatua#,
				'generic' => q#vrijeme Vanuatua#,
				'standard' => q#standardno vrijeme Vanuatua#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelsko vrijeme#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#vladivostočko ljetno vrijeme#,
				'generic' => q#vladivostočko vrijeme#,
				'standard' => q#vladivostočko standardno vrijeme#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#volgogradsko ljetno vrijeme#,
				'generic' => q#volgogradsko vrijeme#,
				'standard' => q#volgogradsko standardno vrijeme#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#vostočko vrijeme#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#vrijeme Otoka Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#vrijeme Otoka Wallis i Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#jakutsko ljetno vrijeme#,
				'generic' => q#jakutsko vrijeme#,
				'standard' => q#jakutsko standardno vrijeme#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ekaterinburško ljetno vrijeme#,
				'generic' => q#ekaterinburško vrijeme#,
				'standard' => q#ekaterinburško standardno vrijeme#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
