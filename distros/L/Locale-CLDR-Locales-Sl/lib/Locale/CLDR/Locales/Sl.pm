=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sl - Package for language Slovenian

=cut

package Locale::CLDR::Locales::Sl;
# This file auto generated from Data\common\main\sl.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
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
					rule => q(nič),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vejica →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ena),
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
					rule => q(dvaset[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←deset[ →→]),
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
					rule => q(štiristo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petsto[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šesto[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedemsto[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osemsto[ →→]),
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
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nič),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vejica →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ena),
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
					rule => q(štiri),
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
					rule => q(sedem),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osem),
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
					rule => q(enajst),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dvanajst),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trinajst),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(štrinajst),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(petnajst),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(šestnajst),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sedemnajst),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(asemnajst),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(devetnajst),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvaset[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←deset[ →→]),
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
					rule => q(štiristo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petsto[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šesto[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedemsto[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osemsto[ →→]),
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
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nič),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vejica →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ena),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dve),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvaset[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←deset[ →→]),
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
					rule => q(štiristo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(petsto[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(šesto[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sedemsto[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(osemsto[ →→]),
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
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afarščina',
 				'ab' => 'abhaščina',
 				'ace' => 'ačejščina',
 				'ach' => 'ačolijščina',
 				'ada' => 'adangmejščina',
 				'ady' => 'adigejščina',
 				'ae' => 'avestijščina',
 				'af' => 'afrikanščina',
 				'afh' => 'afrihili',
 				'agq' => 'aghemščina',
 				'ain' => 'ainujščina',
 				'ak' => 'akanščina',
 				'akk' => 'akadščina',
 				'ale' => 'aleutščina',
 				'alt' => 'južna altajščina',
 				'am' => 'amharščina',
 				'an' => 'aragonščina',
 				'ang' => 'stara angleščina',
 				'ann' => 'obolo',
 				'anp' => 'angikaščina',
 				'ar' => 'arabščina',
 				'ar_001' => 'sodobna standardna arabščina',
 				'arc' => 'aramejščina',
 				'arn' => 'mapudungunščina',
 				'arp' => 'arapaščina',
 				'ars' => 'nadždska arabščina',
 				'arw' => 'aravaščina',
 				'as' => 'asamščina',
 				'asa' => 'asujščina',
 				'ast' => 'asturijščina',
 				'atj' => 'atikamekwščina',
 				'av' => 'avarščina',
 				'awa' => 'avadščina',
 				'ay' => 'ajmarščina',
 				'az' => 'azerbajdžanščina',
 				'az@alt=short' => 'azerščina',
 				'ba' => 'baškirščina',
 				'bal' => 'beludžijščina',
 				'ban' => 'balijščina',
 				'bas' => 'basa',
 				'be' => 'beloruščina',
 				'bej' => 'bedža',
 				'bem' => 'bemba',
 				'bez' => 'benajščina',
 				'bg' => 'bolgarščina',
 				'bgc' => 'harjanščina',
 				'bgn' => 'zahodnobalučijščina',
 				'bho' => 'bodžpuri',
 				'bi' => 'bislamščina',
 				'bik' => 'bikolski jezik',
 				'bin' => 'edo',
 				'bla' => 'siksika',
 				'blo' => 'anii',
 				'bm' => 'bambarščina',
 				'bn' => 'bengalščina',
 				'bo' => 'tibetanščina',
 				'br' => 'bretonščina',
 				'bra' => 'bradžbakanščina',
 				'brx' => 'bodojščina',
 				'bs' => 'bosanščina',
 				'bua' => 'burjatščina',
 				'bug' => 'buginščina',
 				'byn' => 'blinščina',
 				'ca' => 'katalonščina',
 				'cad' => 'kadoščina',
 				'car' => 'karibski jezik',
 				'cay' => 'kajuščina',
 				'ccp' => 'chakma',
 				'ce' => 'čečenščina',
 				'ceb' => 'sebuanščina',
 				'cgg' => 'čigajščina',
 				'ch' => 'čamorščina',
 				'chb' => 'čibčevščina',
 				'chg' => 'čagatajščina',
 				'chk' => 'trukeščina',
 				'chm' => 'marijščina',
 				'chn' => 'činuški žargon',
 				'cho' => 'čoktavščina',
 				'chp' => 'čipevščina',
 				'chr' => 'čerokeščina',
 				'chy' => 'čejenščina',
 				'ckb' => 'osrednja kurdščina',
 				'ckb@alt=variant' => 'soranska kurdščina',
 				'clc' => 'čilkotinščina',
 				'co' => 'korziščina',
 				'cop' => 'koptščina',
 				'cr' => 'krijščina',
 				'crg' => 'mičifščina',
 				'crh' => 'krimska tatarščina',
 				'crj' => 'jugovzhodna krijščina',
 				'crk' => 'nižinska krijščina',
 				'crl' => 'severovzhodna krijščina',
 				'crm' => 'moose-krijščina',
 				'crr' => 'karolinska algonkinščina',
 				'crs' => 'sejšelska francoska kreolščina',
 				'cs' => 'češčina',
 				'csb' => 'kašubščina',
 				'csw' => 'močvirska krijščina',
 				'cu' => 'stara cerkvena slovanščina',
 				'cv' => 'čuvaščina',
 				'cy' => 'valižanščina',
 				'da' => 'danščina',
 				'dak' => 'dakotščina',
 				'dar' => 'darginščina',
 				'dav' => 'taitajščina',
 				'de' => 'nemščina',
 				'de_AT' => 'avstrijska nemščina',
 				'de_CH' => 'visoka nemščina (Švica)',
 				'del' => 'delavarščina',
 				'den' => 'slavejščina',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarmajščina',
 				'doi' => 'dogri',
 				'dsb' => 'dolnja lužiška srbščina',
 				'dua' => 'duala',
 				'dum' => 'srednja nizozemščina',
 				'dv' => 'diveščina',
 				'dyo' => 'jola-fonjiščina',
 				'dyu' => 'diula',
 				'dz' => 'dzonka',
 				'dzg' => 'dazaga',
 				'ebu' => 'embujščina',
 				'ee' => 'evenščina',
 				'efi' => 'efiščina',
 				'egy' => 'stara egipčanščina',
 				'eka' => 'ekajuk',
 				'el' => 'grščina',
 				'elx' => 'elamščina',
 				'en' => 'angleščina',
 				'en_AU' => 'avstralska angleščina',
 				'en_CA' => 'kanadska angleščina',
 				'en_GB' => 'britanska angleščina',
 				'en_GB@alt=short' => 'angleščina (ZK)',
 				'en_US' => 'ameriška angleščina',
 				'en_US@alt=short' => 'angleščina (ZDA)',
 				'enm' => 'srednja angleščina',
 				'eo' => 'esperanto',
 				'es' => 'španščina',
 				'es_419' => 'latinskoameriška španščina',
 				'es_ES' => 'evropska španščina',
 				'es_MX' => 'mehiška španščina',
 				'et' => 'estonščina',
 				'eu' => 'baskovščina',
 				'ewo' => 'evondovščina',
 				'fa' => 'perzijščina',
 				'fa_AF' => 'darijščina',
 				'fan' => 'fangijščina',
 				'fat' => 'fantijščina',
 				'ff' => 'fulščina',
 				'fi' => 'finščina',
 				'fil' => 'filipinščina',
 				'fj' => 'fidžijščina',
 				'fo' => 'ferščina',
 				'fon' => 'fonščina',
 				'fr' => 'francoščina',
 				'fr_CA' => 'kanadska francoščina',
 				'fr_CH' => 'švicarska francoščina',
 				'frc' => 'cajunska francoščina',
 				'frm' => 'srednja francoščina',
 				'fro' => 'stara francoščina',
 				'frr' => 'severna frizijščina',
 				'frs' => 'vzhodna frizijščina',
 				'fur' => 'furlanščina',
 				'fy' => 'zahodna frizijščina',
 				'ga' => 'irščina',
 				'gaa' => 'ga',
 				'gag' => 'gagavščina',
 				'gay' => 'gajščina',
 				'gba' => 'gbajščina',
 				'gd' => 'škotska gelščina',
 				'gez' => 'etiopščina',
 				'gil' => 'kiribatščina',
 				'gl' => 'galicijščina',
 				'gmh' => 'srednja visoka nemščina',
 				'gn' => 'gvaranijščina',
 				'goh' => 'stara visoka nemščina',
 				'gon' => 'gondi',
 				'gor' => 'gorontalščina',
 				'got' => 'gotščina',
 				'grb' => 'grebščina',
 				'grc' => 'stara grščina',
 				'gsw' => 'nemščina (Švica)',
 				'gu' => 'gudžaratščina',
 				'guz' => 'gusijščina',
 				'gv' => 'manščina',
 				'gwi' => 'gvičin',
 				'ha' => 'havščina',
 				'hai' => 'haidščina',
 				'haw' => 'havajščina',
 				'hax' => 'južna haidščina',
 				'he' => 'hebrejščina',
 				'hi' => 'hindijščina',
 				'hi_Latn@alt=variant' => 'hingleščina',
 				'hil' => 'hiligajnonščina',
 				'hit' => 'hetitščina',
 				'hmn' => 'hmonščina',
 				'ho' => 'hiri motu',
 				'hr' => 'hrvaščina',
 				'hsb' => 'gornja lužiška srbščina',
 				'ht' => 'haitijska kreolščina',
 				'hu' => 'madžarščina',
 				'hup' => 'hupa',
 				'hur' => 'halkomelenščina',
 				'hy' => 'armenščina',
 				'hz' => 'herero',
 				'ia' => 'interlingva',
 				'iba' => 'ibanščina',
 				'ibb' => 'ibibijščina',
 				'id' => 'indonezijščina',
 				'ie' => 'interlingve',
 				'ig' => 'igboščina',
 				'ii' => 'sečuanska jiščina',
 				'ik' => 'inupiaščina',
 				'ikt' => 'zahodna kanadska inuktituščina',
 				'ilo' => 'ilokanščina',
 				'inh' => 'inguščina',
 				'io' => 'ido',
 				'is' => 'islandščina',
 				'it' => 'italijanščina',
 				'iu' => 'inuktitutščina',
 				'ja' => 'japonščina',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'mačamejščina',
 				'jpr' => 'judovska perzijščina',
 				'jrb' => 'judovska arabščina',
 				'jv' => 'javanščina',
 				'ka' => 'gruzijščina',
 				'kaa' => 'karakalpaščina',
 				'kab' => 'kabilščina',
 				'kac' => 'kačinščina',
 				'kaj' => 'jju',
 				'kam' => 'kambaščina',
 				'kaw' => 'kavi',
 				'kbd' => 'kabardinščina',
 				'kcg' => 'tjapska nigerijščina',
 				'kde' => 'makondščina',
 				'kea' => 'zelenortskootoška kreolščina',
 				'kfo' => 'koro',
 				'kg' => 'kongovščina',
 				'kgp' => 'kaingangščina',
 				'kha' => 'kasi',
 				'kho' => 'kotanščina',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikujščina',
 				'kj' => 'kvanjama',
 				'kk' => 'kazaščina',
 				'kkj' => 'kako',
 				'kl' => 'grenlandščina',
 				'kln' => 'kalenjinščina',
 				'km' => 'kmerščina',
 				'kmb' => 'kimbundu',
 				'kn' => 'kanareščina',
 				'ko' => 'korejščina',
 				'koi' => 'komi-permjaščina',
 				'kok' => 'konkanščina',
 				'kos' => 'kosrajščina',
 				'kpe' => 'kpelejščina',
 				'kr' => 'kanurščina',
 				'krc' => 'karačaj-balkarščina',
 				'krl' => 'karelščina',
 				'kru' => 'kuruk',
 				'ks' => 'kašmirščina',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölnsko narečje',
 				'ku' => 'kurdščina',
 				'kum' => 'kumiščina',
 				'kut' => 'kutenajščina',
 				'kv' => 'komijščina',
 				'kw' => 'kornijščina',
 				'kwk' => 'kvakvala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirgiščina',
 				'la' => 'latinščina',
 				'lad' => 'ladinščina',
 				'lag' => 'langijščina',
 				'lah' => 'landa',
 				'lam' => 'lamba',
 				'lb' => 'luksemburščina',
 				'lez' => 'lezginščina',
 				'lg' => 'ganda',
 				'li' => 'limburščina',
 				'lij' => 'ligurščina',
 				'lil' => 'lilovetščina',
 				'lkt' => 'lakotščina',
 				'lmo' => 'lombardščina',
 				'ln' => 'lingala',
 				'lo' => 'laoščina',
 				'lol' => 'mongo',
 				'lou' => 'louisianska kreolščina',
 				'loz' => 'lozi',
 				'lrc' => 'severna lurijščina',
 				'lsm' => 'saamijščina',
 				'lt' => 'litovščina',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luisenščina',
 				'lun' => 'lunda',
 				'lus' => 'mizojščina',
 				'luy' => 'luhijščina',
 				'lv' => 'latvijščina',
 				'mad' => 'madurščina',
 				'mag' => 'magadščina',
 				'mai' => 'maitili',
 				'mak' => 'makasarščina',
 				'man' => 'mandingo',
 				'mas' => 'masajščina',
 				'mdf' => 'mokšavščina',
 				'mdr' => 'mandarščina',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisjenščina',
 				'mg' => 'malgaščina',
 				'mga' => 'srednja irščina',
 				'mgh' => 'makuva-meto',
 				'mgo' => 'meta',
 				'mh' => 'marshallovščina',
 				'mi' => 'maorščina',
 				'mic' => 'mikmaščina',
 				'min' => 'minangkabau',
 				'mk' => 'makedonščina',
 				'ml' => 'malajalamščina',
 				'mn' => 'mongolščina',
 				'mnc' => 'mandžurščina',
 				'mni' => 'manipurščina',
 				'moe' => 'inuaimunščina',
 				'moh' => 'mohoščina',
 				'mos' => 'mosijščina',
 				'mr' => 'maratščina',
 				'ms' => 'malajščina',
 				'mt' => 'malteščina',
 				'mua' => 'mundang',
 				'mul' => 'več jezikov',
 				'mus' => 'creekovščina',
 				'mwl' => 'mirandeščina',
 				'mwr' => 'marvarščina',
 				'my' => 'burmanščina',
 				'myv' => 'erzjanščina',
 				'mzn' => 'mazanderanščina',
 				'na' => 'naurujščina',
 				'nan' => 'min nan kitajščina',
 				'nap' => 'napolitanščina',
 				'naq' => 'khoekhoe',
 				'nb' => 'knjižna norveščina',
 				'nd' => 'severna ndebelščina',
 				'nds' => 'nizka nemščina',
 				'nds_NL' => 'nizka saščina',
 				'ne' => 'nepalščina',
 				'new' => 'nevarščina',
 				'ng' => 'ndonga',
 				'nia' => 'niaščina',
 				'niu' => 'niuejščina',
 				'nl' => 'nizozemščina',
 				'nl_BE' => 'flamščina',
 				'nmg' => 'kwasio',
 				'nn' => 'novonorveščina',
 				'nnh' => 'ngiemboonščina',
 				'no' => 'norveščina',
 				'nog' => 'nogajščina',
 				'non' => 'stara nordijščina',
 				'nqo' => 'n’ko',
 				'nr' => 'južna ndebelščina',
 				'nso' => 'severna sotščina',
 				'nus' => 'nuerščina',
 				'nv' => 'navajščina',
 				'nwc' => 'klasična nevarščina',
 				'ny' => 'njanščina',
 				'nym' => 'njamveščina',
 				'nyn' => 'njankole',
 				'nyo' => 'njoro',
 				'nzi' => 'nzima',
 				'oc' => 'okcitanščina',
 				'oj' => 'anašinabščina',
 				'ojb' => 'severozahodna očipvejščina',
 				'ojc' => 'osrednja očipvejščina',
 				'ojs' => 'oči-krijščina',
 				'ojw' => 'zahodna očipvejščina',
 				'oka' => 'okanaganščina',
 				'om' => 'oromo',
 				'or' => 'odijščina',
 				'os' => 'osetinščina',
 				'osa' => 'osage',
 				'ota' => 'otomanska turščina',
 				'pa' => 'pandžabščina',
 				'pag' => 'pangasinanščina',
 				'pam' => 'pampanščina',
 				'pap' => 'papiamentu',
 				'pau' => 'palavanščina',
 				'pcm' => 'nigerijski pidžin',
 				'peo' => 'stara perzijščina',
 				'phn' => 'feničanščina',
 				'pi' => 'palijščina',
 				'pis' => 'pidžin',
 				'pl' => 'poljščina',
 				'pon' => 'ponpejščina',
 				'pqm' => 'maliseet-passamaquoddščina',
 				'prg' => 'stara pruščina',
 				'pro' => 'stara provansalščina',
 				'ps' => 'paštunščina',
 				'pt' => 'portugalščina',
 				'pt_BR' => 'brazilska portugalščina',
 				'pt_PT' => 'evropska portugalščina',
 				'qu' => 'kečuanščina',
 				'quc' => 'quiche',
 				'raj' => 'radžastanščina',
 				'rap' => 'rapanujščina',
 				'rar' => 'rarotongščina',
 				'rhg' => 'rohinščina',
 				'rm' => 'retoromanščina',
 				'rn' => 'rundščina',
 				'ro' => 'romunščina',
 				'ro_MD' => 'moldavščina',
 				'rof' => 'rombo',
 				'rom' => 'romščina',
 				'ru' => 'ruščina',
 				'rup' => 'aromunščina',
 				'rw' => 'ruandščina',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrt',
 				'sad' => 'sandavščina',
 				'sah' => 'jakutščina',
 				'sam' => 'samaritanska aramejščina',
 				'saq' => 'samburščina',
 				'sas' => 'sasaščina',
 				'sat' => 'santalščina',
 				'sba' => 'ngambajščina',
 				'sbp' => 'sangujščina',
 				'sc' => 'sardinščina',
 				'scn' => 'sicilijanščina',
 				'sco' => 'škotščina',
 				'sd' => 'sindščina',
 				'sdh' => 'južna kurdščina',
 				'se' => 'severna samijščina',
 				'seh' => 'sena',
 				'sel' => 'selkupščina',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'stara irščina',
 				'sh' => 'srbohrvaščina',
 				'shi' => 'tahelitska berberščina',
 				'shn' => 'šanščina',
 				'si' => 'sinhalščina',
 				'sid' => 'sidamščina',
 				'sk' => 'slovaščina',
 				'sl' => 'slovenščina',
 				'slh' => 'južna lušucidščina',
 				'sm' => 'samoanščina',
 				'sma' => 'južna samijščina',
 				'smj' => 'luleška samijščina',
 				'smn' => 'inarska samijščina',
 				'sms' => 'skoltska samijščina',
 				'sn' => 'šonščina',
 				'snk' => 'soninke',
 				'so' => 'somalščina',
 				'sq' => 'albanščina',
 				'sr' => 'srbščina',
 				'srn' => 'surinamska kreolščina',
 				'srr' => 'sererščina',
 				'ss' => 'svazijščina',
 				'ssy' => 'saho',
 				'st' => 'sesoto',
 				'str' => 'ožinska sališčina',
 				'su' => 'sundanščina',
 				'suk' => 'sukuma',
 				'sus' => 'susujščina',
 				'sux' => 'sumerščina',
 				'sv' => 'švedščina',
 				'sw' => 'svahili',
 				'sw_CD' => 'kongoški svahili',
 				'swb' => 'šikomor',
 				'syc' => 'klasična sirščina',
 				'syr' => 'sirščina',
 				'szl' => 'šlezijščina',
 				'ta' => 'tamilščina',
 				'tce' => 'južna tučonščina',
 				'te' => 'telugijščina',
 				'tem' => 'temnejščina',
 				'teo' => 'teso',
 				'tet' => 'tetumščina',
 				'tg' => 'tadžiščina',
 				'tgx' => 'tagiščina',
 				'th' => 'tajščina',
 				'tht' => 'taltanščina',
 				'ti' => 'tigrajščina',
 				'tig' => 'tigrejščina',
 				'tiv' => 'tivščina',
 				'tk' => 'turkmenščina',
 				'tkl' => 'tokelavščina',
 				'tl' => 'tagalogščina',
 				'tlh' => 'klingonščina',
 				'tli' => 'tlingitščina',
 				'tmh' => 'tamajaščina',
 				'tn' => 'cvanščina',
 				'to' => 'tongščina',
 				'tog' => 'malavijska tongščina',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turščina',
 				'trv' => 'taroko',
 				'ts' => 'congščina',
 				'tsi' => 'tsimščina',
 				'tt' => 'tatarščina',
 				'ttm' => 'severna tučonščina',
 				'tum' => 'tumbukščina',
 				'tvl' => 'tuvalujščina',
 				'tw' => 'tvi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitščina',
 				'tyv' => 'tuvinščina',
 				'tzm' => 'tamašek (Srednji Atlas)',
 				'udm' => 'udmurtščina',
 				'ug' => 'ujgurščina',
 				'uga' => 'ugaritski jezik',
 				'uk' => 'ukrajinščina',
 				'umb' => 'umbundščina',
 				'und' => 'neznan jezik',
 				'ur' => 'urdujščina',
 				'uz' => 'uzbeščina',
 				'vai' => 'vajščina',
 				've' => 'venda',
 				'vec' => 'beneščina',
 				'vi' => 'vietnamščina',
 				'vmw' => 'makuva',
 				'vo' => 'volapik',
 				'vot' => 'votjaščina',
 				'vun' => 'vunjo',
 				'wa' => 'valonščina',
 				'wae' => 'walser',
 				'wal' => 'valamščina',
 				'war' => 'varajščina',
 				'was' => 'vašajščina',
 				'wbp' => 'varlpirščina',
 				'wo' => 'volofščina',
 				'wuu' => 'wu-kitajščina',
 				'xal' => 'kalmiščina',
 				'xh' => 'koščina',
 				'xnr' => 'kangri',
 				'xog' => 'sogščina',
 				'yao' => 'jaojščina',
 				'yap' => 'japščina',
 				'yav' => 'jangben',
 				'ybb' => 'jembajščina',
 				'yi' => 'jidiš',
 				'yo' => 'jorubščina',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantonščina',
 				'yue@alt=menu' => 'kitajščina (kantonščina)',
 				'za' => 'džuangščina',
 				'zap' => 'zapoteščina',
 				'zbl' => 'znakovni jezik Bliss',
 				'zen' => 'zenaščina',
 				'zgh' => 'standardni maroški tamazig',
 				'zh' => 'kitajščina',
 				'zh@alt=menu' => 'kitajščina (mandarinščina)',
 				'zh_Hans' => 'poenostavljena kitajščina',
 				'zh_Hans@alt=long' => 'poenostavljena mandarinska kitajščina',
 				'zh_Hant' => 'tradicionalna kitajščina',
 				'zh_Hant@alt=long' => 'tradicionalna mandarinska kitajščina',
 				'zu' => 'zulujščina',
 				'zun' => 'zunijščina',
 				'zxx' => 'brez jezikoslovne vsebine',
 				'zza' => 'zazajščina',

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
			'Adlm' => 'adlamski',
 			'Arab' => 'arabski',
 			'Arab@alt=variant' => 'perzijskoarabski',
 			'Aran' => 'nastalik',
 			'Armi' => 'imperialno-aramejski',
 			'Armn' => 'armenski',
 			'Avst' => 'avestanski',
 			'Bali' => 'balijski',
 			'Batk' => 'bataški',
 			'Beng' => 'bengalski',
 			'Blis' => 'znakovna pisava Bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'bramanski',
 			'Brai' => 'braillova pisava',
 			'Bugi' => 'buginski',
 			'Buhd' => 'buhidski',
 			'Cakm' => 'čakmajski',
 			'Cans' => 'poenotena zlogovna pisava kanadskih staroselcev',
 			'Cher' => 'čerokeški',
 			'Cirt' => 'kirt',
 			'Copt' => 'koptski',
 			'Cprt' => 'ciprski',
 			'Cyrl' => 'cirilica',
 			'Cyrs' => 'starocerkvenoslovanska cirilica',
 			'Deva' => 'devanagarščica',
 			'Dsrt' => 'fonetska pisava deseret',
 			'Egyd' => 'demotska egipčanska pisava',
 			'Egyh' => 'hieratska egipčanska pisava',
 			'Egyp' => 'egipčanska slikovna pisava',
 			'Ethi' => 'etiopski',
 			'Geok' => 'cerkvenogruzijski',
 			'Geor' => 'gruzijski',
 			'Glag' => 'glagoliški',
 			'Goth' => 'gotski',
 			'Grek' => 'grški',
 			'Gujr' => 'gudžaratski',
 			'Guru' => 'gurmuki',
 			'Hanb' => 'han + bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'kanji',
 			'Hano' => 'hanunski',
 			'Hans' => 'poenostavljena pisava',
 			'Hans@alt=stand-alone' => 'poenostavljena pisava han',
 			'Hant' => 'tradicionalna pisava',
 			'Hant@alt=stand-alone' => 'tradicionalna pisava han',
 			'Hebr' => 'hebrejski',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahavhmonska zlogovna pisava',
 			'Hrkt' => 'japonska zlogovnica',
 			'Hung' => 'staroogrski',
 			'Inds' => 'induški',
 			'Ital' => 'staroitalski',
 			'Jamo' => 'jamo',
 			'Java' => 'javanski',
 			'Jpan' => 'japonski',
 			'Kali' => 'karenski',
 			'Kana' => 'katakana',
 			'Khar' => 'gandarski',
 			'Khmr' => 'kmerski',
 			'Knda' => 'kanadski',
 			'Kore' => 'korejski',
 			'Kthi' => 'kajatski',
 			'Laoo' => 'laoški',
 			'Latf' => 'fraktura',
 			'Latg' => 'gelski latinični',
 			'Latn' => 'latinica',
 			'Lepc' => 'lepški',
 			'Limb' => 'limbuški',
 			'Lina' => 'linearna pisava A',
 			'Linb' => 'linearna pisava B',
 			'Lyci' => 'licijski',
 			'Lydi' => 'lidijski',
 			'Mand' => 'mandanski',
 			'Mani' => 'manihejski',
 			'Maya' => 'majevska slikovna pisava',
 			'Mero' => 'meroitski',
 			'Mlym' => 'malajalamski',
 			'Mong' => 'mongolska',
 			'Moon' => 'Moonova pisava za slepe',
 			'Mtei' => 'meiteiski',
 			'Mymr' => 'mjanmarski',
 			'Nkoo' => 'nkojski',
 			'Ogam' => 'ogamski',
 			'Olck' => 'santalski',
 			'Orkh' => 'orkonski',
 			'Orya' => 'orijski',
 			'Osma' => 'osmanski',
 			'Perm' => 'staropermijski',
 			'Phag' => 'pagpajski',
 			'Phli' => 'vrezani napisi pahlavi',
 			'Phlp' => 'psalmski pahlavi',
 			'Phlv' => 'knjižno palavanski',
 			'Phnx' => 'feničanski',
 			'Plrd' => 'Pollardova fonetska pisava',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runski',
 			'Samr' => 'samaritanski',
 			'Sara' => 'saratski',
 			'Sgnw' => 'znakovna pisava',
 			'Shaw' => 'šojevski',
 			'Sinh' => 'sinhalski',
 			'Sund' => 'sundanski',
 			'Sylo' => 'siletsko-nagarijski',
 			'Syrc' => 'sirijski',
 			'Syre' => 'sirska abeceda estrangelo',
 			'Syrj' => 'zahodnosirijski',
 			'Syrn' => 'vzhodnosirijski',
 			'Tagb' => 'tagbanski',
 			'Taml' => 'tamilski',
 			'Tavt' => 'tajsko-vietnamski',
 			'Telu' => 'teluški',
 			'Teng' => 'tengvarski',
 			'Tfng' => 'tifinajski',
 			'Tglg' => 'tagaloški',
 			'Thaa' => 'tanajski',
 			'Thai' => 'tajski',
 			'Tibt' => 'tibetanski',
 			'Ugar' => 'ugaritski',
 			'Vaii' => 'zlogovna pisava vai',
 			'Visp' => 'vidni govor',
 			'Xpeo' => 'staroperzijski',
 			'Xsux' => 'sumersko-akadski klinopis',
 			'Yiii' => 'jiški',
 			'Zinh' => 'podedovan',
 			'Zmth' => 'matematična znamenja',
 			'Zsye' => 'čustvenček',
 			'Zsym' => 'simboli',
 			'Zxxx' => 'nenapisano',
 			'Zyyy' => 'splošno',
 			'Zzzz' => 'neznan ali neveljaven zapis',

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
			'001' => 'svet',
 			'002' => 'Afrika',
 			'003' => 'Severna Amerika',
 			'005' => 'Južna Amerika',
 			'009' => 'Oceanija',
 			'011' => 'Zahodna Afrika',
 			'013' => 'Srednja Amerika',
 			'014' => 'Vzhodna Afrika',
 			'015' => 'Severna Afrika',
 			'017' => 'Srednja Afrika',
 			'018' => 'Južna Afrika',
 			'019' => 'Amerike',
 			'021' => 'severnoameriška celina',
 			'029' => 'Karibi',
 			'030' => 'Vzhodna Azija',
 			'034' => 'Južna Azija',
 			'035' => 'Jugovzhodna Azija',
 			'039' => 'Južna Evropa',
 			'053' => 'Avstralija in Nova Zelandija',
 			'054' => 'Melanezija',
 			'057' => 'mikronezijska regija',
 			'061' => 'Polinezija',
 			'142' => 'Azija',
 			'143' => 'Osrednja Azija',
 			'145' => 'Zahodna Azija',
 			'150' => 'Evropa',
 			'151' => 'Vzhodna Evropa',
 			'154' => 'Severna Evropa',
 			'155' => 'Zahodna Evropa',
 			'202' => 'podsaharska Afrika',
 			'419' => 'Latinska Amerika',
 			'AC' => 'Otok Ascension',
 			'AD' => 'Andora',
 			'AE' => 'Združeni arabski emirati',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigva in Barbuda',
 			'AI' => 'Angvila',
 			'AL' => 'Albanija',
 			'AM' => 'Armenija',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentina',
 			'AS' => 'Ameriška Samoa',
 			'AT' => 'Avstrija',
 			'AU' => 'Avstralija',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandski otoki',
 			'AZ' => 'Azerbajdžan',
 			'BA' => 'Bosna in Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgija',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bolgarija',
 			'BH' => 'Bahrajn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermudi',
 			'BN' => 'Brunej',
 			'BO' => 'Bolivija',
 			'BQ' => 'Nizozemski Karibi',
 			'BR' => 'Brazilija',
 			'BS' => 'Bahami',
 			'BT' => 'Butan',
 			'BV' => 'Bouvetov otok',
 			'BW' => 'Bocvana',
 			'BY' => 'Belorusija',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosovi otoki',
 			'CD' => 'Demokratična republika Kongo',
 			'CD@alt=variant' => 'Kongo (Demokratična republika Kongo)',
 			'CF' => 'Srednjeafriška republika',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republika)',
 			'CH' => 'Švica',
 			'CI' => 'Slonokoščena obala',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cookovi otoki',
 			'CL' => 'Čile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kitajska',
 			'CO' => 'Kolumbija',
 			'CP' => 'Otok Clipperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Zelenortski otoki',
 			'CW' => 'Curaçao',
 			'CX' => 'Božični otok',
 			'CY' => 'Ciper',
 			'CZ' => 'Češka',
 			'CZ@alt=variant' => 'Češka republika',
 			'DE' => 'Nemčija',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Džibuti',
 			'DK' => 'Danska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikanska republika',
 			'DZ' => 'Alžirija',
 			'EA' => 'Ceuta in Melilla',
 			'EC' => 'Ekvador',
 			'EE' => 'Estonija',
 			'EG' => 'Egipt',
 			'EH' => 'Zahodna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Španija',
 			'ET' => 'Etiopija',
 			'EU' => 'Evropska unija',
 			'EZ' => 'evroobmočje',
 			'FI' => 'Finska',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandski otoki',
 			'FK@alt=variant' => 'Falklandski otoki (Malvini)',
 			'FM' => 'Mikronezija',
 			'FO' => 'Ferski otoki',
 			'FR' => 'Francija',
 			'GA' => 'Gabon',
 			'GB' => 'Združeno kraljestvo',
 			'GB@alt=short' => 'ZK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzija',
 			'GF' => 'Francoska Gvajana',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grenlandija',
 			'GM' => 'Gambija',
 			'GN' => 'Gvineja',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatorialna Gvineja',
 			'GR' => 'Grčija',
 			'GS' => 'Južna Georgia in Južni Sandwichevi otoki',
 			'GT' => 'Gvatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gvineja Bissau',
 			'GY' => 'Gvajana',
 			'HK' => 'Posebno upravno območje Ljudske republike Kitajske Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardov otok in McDonaldovi otoki',
 			'HN' => 'Honduras',
 			'HR' => 'Hrvaška',
 			'HT' => 'Haiti',
 			'HU' => 'Madžarska',
 			'IC' => 'Kanarski otoki',
 			'ID' => 'Indonezija',
 			'IE' => 'Irska',
 			'IL' => 'Izrael',
 			'IM' => 'Otok Man',
 			'IN' => 'Indija',
 			'IO' => 'Britansko ozemlje v Indijskem oceanu',
 			'IO@alt=chagos' => 'Otočje Chagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandija',
 			'IT' => 'Italija',
 			'JE' => 'Jersey',
 			'JM' => 'Jamajka',
 			'JO' => 'Jordanija',
 			'JP' => 'Japonska',
 			'KE' => 'Kenija',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komori',
 			'KN' => 'Saint Kitts in Nevis',
 			'KP' => 'Severna Koreja',
 			'KR' => 'Južna Koreja',
 			'KW' => 'Kuvajt',
 			'KY' => 'Kajmanski otoki',
 			'KZ' => 'Kazahstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Lihtenštajn',
 			'LK' => 'Šrilanka',
 			'LR' => 'Liberija',
 			'LS' => 'Lesoto',
 			'LT' => 'Litva',
 			'LU' => 'Luksemburg',
 			'LV' => 'Latvija',
 			'LY' => 'Libija',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavija',
 			'ME' => 'Črna gora',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallovi otoki',
 			'MK' => 'Severna Makedonija',
 			'ML' => 'Mali',
 			'MM' => 'Mjanmar (Burma)',
 			'MN' => 'Mongolija',
 			'MO' => 'Posebno upravno območje Ljudske republike Kitajske Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Severni Marianski otoki',
 			'MQ' => 'Martinik',
 			'MR' => 'Mavretanija',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivi',
 			'MW' => 'Malavi',
 			'MX' => 'Mehika',
 			'MY' => 'Malezija',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibija',
 			'NC' => 'Nova Kaledonija',
 			'NE' => 'Niger',
 			'NF' => 'Norfolški otok',
 			'NG' => 'Nigerija',
 			'NI' => 'Nikaragva',
 			'NL' => 'Nizozemska',
 			'NO' => 'Norveška',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelandija',
 			'NZ@alt=variant' => 'Aotearoa Nova Zelandija',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francoska Polinezija',
 			'PG' => 'Papua Nova Gvineja',
 			'PH' => 'Filipini',
 			'PK' => 'Pakistan',
 			'PL' => 'Poljska',
 			'PM' => 'Saint Pierre in Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Portoriko',
 			'PS' => 'Palestinsko ozemlje',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalska',
 			'PW' => 'Palau',
 			'PY' => 'Paragvaj',
 			'QA' => 'Katar',
 			'QO' => 'Ostala oceanija',
 			'RE' => 'Reunion',
 			'RO' => 'Romunija',
 			'RS' => 'Srbija',
 			'RU' => 'Rusija',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudova Arabija',
 			'SB' => 'Salomonovi otoki',
 			'SC' => 'Sejšeli',
 			'SD' => 'Sudan',
 			'SE' => 'Švedska',
 			'SG' => 'Singapur',
 			'SH' => 'Sveta Helena',
 			'SI' => 'Slovenija',
 			'SJ' => 'Svalbard in Jan Mayen',
 			'SK' => 'Slovaška',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinam',
 			'SS' => 'Južni Sudan',
 			'ST' => 'Sao Tome in Principe',
 			'SV' => 'Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sirija',
 			'SZ' => 'Esvatini',
 			'SZ@alt=variant' => 'Svazi',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Otoki Turks in Caicos',
 			'TD' => 'Čad',
 			'TF' => 'Francosko južno ozemlje',
 			'TG' => 'Togo',
 			'TH' => 'Tajska',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Vzhodni Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunizija',
 			'TO' => 'Tonga',
 			'TR' => 'Turčija',
 			'TR@alt=variant' => 'Türkiye',
 			'TT' => 'Trinidad in Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tajvan',
 			'TZ' => 'Tanzanija',
 			'UA' => 'Ukrajina',
 			'UG' => 'Uganda',
 			'UM' => 'Stranski zunanji otoki Združenih držav',
 			'UN' => 'Združeni narodi',
 			'UN@alt=short' => 'ZN',
 			'US' => 'Združene države Amerike',
 			'US@alt=short' => 'ZDA',
 			'UY' => 'Urugvaj',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Saint Vincent in Grenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Britanski Deviški otoki',
 			'VI' => 'Ameriški Deviški otoki',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis in Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'psevdonaglasi',
 			'XB' => 'psevdobidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Južnoafriška republika',
 			'ZM' => 'Zambija',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Neznano ali neveljavno območje',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'tradicionalni nemški pravopis',
 			'1994' => 'standardizirani rezijanski pravopis (1994)',
 			'1996' => 'novi nemški pravopis (1996)',
 			'1606NICT' => 'pozna srednja francoščina (do 1606)',
 			'1694ACAD' => 'zgodnja sodobna francoščina',
 			'1959ACAD' => 'akademska beloruska slovnica',
 			'AREVELA' => 'vzhodna armenščina',
 			'AREVMDA' => 'zahodna armenščina',
 			'BAKU1926' => 'modernizirana turška latinica',
 			'BISKE' => 'rezijansko narečje Bila (San Giorgio)',
 			'BOONT' => 'boonvilski jezik',
 			'FONIPA' => 'mednarodna fonetična pisava IPA',
 			'FONUPA' => 'uralska fonetska pisava UPA',
 			'KKCOR' => 'standardni pravopis',
 			'LIPAW' => 'rezijansko narečje iz Lipovca (Lipovaz)',
 			'MONOTON' => 'monotonalni pravopis',
 			'NEDIS' => 'nadiško narečje',
 			'NJIVA' => 'rezijansko narečje Njiva (Gniva)',
 			'OSOJS' => 'rezijansko narečje iz Osojan (Oseacco)',
 			'PINYIN' => 'romanizacija pindžin',
 			'POLYTON' => 'politonalni pravopis',
 			'POSIX' => 'standard prenosljivosti programske opreme',
 			'REVISED' => 'revidiran pravopis',
 			'ROZAJ' => 'rezijanščina',
 			'SAAHO' => 'eritrejsko narečje soho',
 			'SCOTLAND' => 'standardna škotska angleščina',
 			'SCOUSE' => 'liverpoolsko angleško narečje scouse',
 			'SOLBA' => 'rezijansko narečje iz Solbice (Stolvizza)',
 			'TARASK' => 'Taraškievičeva beloruska slovnica',
 			'UCCOR' => 'poenoten pravopis',
 			'UCRCOR' => 'revidiran poenoten pravopis',
 			'VALENCIA' => 'valencijski pravopis',
 			'WADEGILE' => 'romanizacija Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'koledar',
 			'cf' => 'oblika zapisa valute',
 			'colalternate' => 'Razvrščanje s prezrtimi znaki',
 			'colbackwards' => 'Razvrščanje z obratnimi naglasi',
 			'colcasefirst' => 'Razvrščanje velike črke/male črke',
 			'colcaselevel' => 'Razvrščanje, občutljivo na velike/male črke',
 			'collation' => 'razvrščanje',
 			'colnormalization' => 'Normalizirano razvrščanje',
 			'colnumeric' => 'Številsko razvrščanje',
 			'colstrength' => 'Moč razvrščanja',
 			'currency' => 'valuta',
 			'hc' => 'urni prikaz (12 ali 24)',
 			'lb' => 'Slog preloma vrstic',
 			'ms' => 'merski sistem',
 			'numbers' => 'številke',
 			'timezone' => 'Časovni pas',
 			'va' => 'Različica območnih nastavitev',
 			'x' => 'Zasebna-uporaba',

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
 				'buddhist' => q{budistični koledar},
 				'chinese' => q{kitajski koledar},
 				'coptic' => q{koptski koledar},
 				'dangi' => q{stari korejski koledar},
 				'ethiopic' => q{etiopski koledar},
 				'ethiopic-amete-alem' => q{etiopsko ametsko alemski koledar},
 				'gregorian' => q{gregorijanski koledar},
 				'hebrew' => q{hebrejski koledar},
 				'indian' => q{indijanski koledar},
 				'islamic' => q{islamski koledar},
 				'islamic-civil' => q{islamski civilni koledar},
 				'islamic-rgsa' => q{islamski koledar ( Saudova Arabija, opazovalni)},
 				'islamic-tbla' => q{islamski koledar (tabelarni, astronomska epoha)},
 				'islamic-umalqura' => q{islamski koledar Umm al-Qura},
 				'iso8601' => q{koledar ISO-8601},
 				'japanese' => q{japonski koledar},
 				'persian' => q{perzijski koledar},
 				'roc' => q{koledar Minguo},
 			},
 			'cf' => {
 				'account' => q{oblika zapisa valute v računovodstvu},
 				'standard' => q{standardna oblika zapisa valute},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Razvrščanje simbolov},
 				'shifted' => q{Razvrščanje s prezrtjem simbolov},
 			},
 			'colbackwards' => {
 				'no' => q{Navadno razvrščanje naglasov},
 				'yes' => q{Obratno razvrščanje naglasov},
 			},
 			'colcasefirst' => {
 				'lower' => q{Razvrščanje malih črk najprej},
 				'no' => q{Razvrščanje v običajnem zaporedju velikih/malih črk},
 				'upper' => q{Razvrščanje velikih črk najprej},
 			},
 			'colcaselevel' => {
 				'no' => q{Razvrščanje ne glede na velike/male črke},
 				'yes' => q{Razvrščanje ob upoštevanju velikih/malih črk},
 			},
 			'collation' => {
 				'big5han' => q{razvrščanje po sistemu tradicionalne kitajščine - Big5},
 				'compat' => q{prej uporabljeno razvrščanje za združljivost},
 				'dictionary' => q{slovarsko razvrščanje},
 				'ducet' => q{Privzeto razvrščanje Unicode},
 				'emoji' => q{razvrščanje čustvenčkov},
 				'eor' => q{evropska pravila razvrščanja},
 				'gb2312han' => q{razvrščanje po sistemu poenostavljene kitajščine - GB2312},
 				'phonebook' => q{razvrščanje po sistemu telefonskega imenika},
 				'phonetic' => q{fonetično razvrščanje},
 				'pinyin' => q{razvrščanje po sistemu pinjin},
 				'search' => q{Splošno iskanje},
 				'searchjl' => q{Iskanje po začetnem soglasniku hangul},
 				'standard' => q{Standardno razvrščanje},
 				'stroke' => q{razvrščanje po zaporedju pisanja pismenk},
 				'traditional' => q{razvrščanje po tradicionalnem sistemu},
 				'unihan' => q{razvrščanje po radikalih in potezah},
 				'zhuyin' => q{razvrščanje po pismenkah zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Razvrščanje brez normaliziranja},
 				'yes' => q{Normalizirano razvrščanje Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{Ločeno razvrščanje številk},
 				'yes' => q{Številsko razvrščanje števk},
 			},
 			'colstrength' => {
 				'identical' => q{Razvrščanje vsega},
 				'primary' => q{Razvrščanje samo osnovnih črk},
 				'quaternary' => q{Razvrščanje po naglasih/velikih črkah/malih črkah/širini/kana},
 				'secondary' => q{Razvrščanje naglasov},
 				'tertiary' => q{Razvrščanje po naglasih/velikih črkah/malih črkah/širini},
 			},
 			'd0' => {
 				'fwidth' => q{Polna širina},
 				'hwidth' => q{Polovična širina},
 				'npinyin' => q{Številsko},
 			},
 			'hc' => {
 				'h11' => q{12-urni sistem (0–11)},
 				'h12' => q{12-urni sistem (1–12)},
 				'h23' => q{24-urni sistem (0–23)},
 				'h24' => q{24-urni sistem (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Prosti slog preloma vrstic},
 				'normal' => q{Običajni slog preloma vrstic},
 				'strict' => q{Strogi slog preloma vrstic},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{metrični sistem},
 				'uksystem' => q{imperialni merski sistem},
 				'ussystem' => q{merski sistem Združenih držav},
 			},
 			'numbers' => {
 				'ahom' => q{števke ahom},
 				'arab' => q{arabskoindijske števke},
 				'arabext' => q{razširjene arabskoindijske števke},
 				'armn' => q{armenske številke},
 				'armnlow' => q{armenske majhne številke},
 				'bali' => q{balinezijske števke},
 				'beng' => q{bengalske števke},
 				'brah' => q{brahmi števke},
 				'cakm' => q{čakmajske števke},
 				'cham' => q{Cham števke},
 				'cyrl' => q{cirilične številke},
 				'deva' => q{devangarske števke},
 				'ethi' => q{etiopijske številke},
 				'finance' => q{Finančne številke},
 				'fullwide' => q{števke polne širine},
 				'geor' => q{gruzijske številke},
 				'gonm' => q{Masaram gondi števke},
 				'grek' => q{grške številke},
 				'greklow' => q{grške male številke},
 				'gujr' => q{gudžaratske števke},
 				'guru' => q{gurmuške števke},
 				'hanidec' => q{kitajske decimalne številke},
 				'hans' => q{poenostavljene kitajske številke},
 				'hansfin' => q{poenostavljene kitajske finančne številke},
 				'hant' => q{tradicionalne kitajske številke},
 				'hantfin' => q{tradicionalne kitajske finančne številke},
 				'hebr' => q{hebrejske številke},
 				'hmng' => q{Pahawh Hmong števke},
 				'java' => q{javanske števke},
 				'jpan' => q{japonske številke},
 				'jpanfin' => q{japonske finančne številke},
 				'kali' => q{Kayah Li števke},
 				'khmr' => q{kmerske števke},
 				'knda' => q{kanaredske števke},
 				'lana' => q{Tai Tham Hora števke},
 				'lanatham' => q{Tai Tham Tham števke},
 				'laoo' => q{laoške števke},
 				'latn' => q{zahodne števke},
 				'lepc' => q{Lepcha števke},
 				'limb' => q{Limbu števke},
 				'mathbold' => q{Krepke matematične števke},
 				'mathdbl' => q{dvojno prečrtane matematične števke},
 				'mathmono' => q{matematične števke z enim prostorom},
 				'mathsanb' => q{matematične krepke Sans-Serif števke},
 				'mathsans' => q{matematične Sans-Serif števke},
 				'mlym' => q{malajalamske števke},
 				'modi' => q{Modi števke},
 				'mong' => q{Mongolske števke},
 				'mroo' => q{Mro števke},
 				'mtei' => q{meiteiske števke},
 				'mymr' => q{mjanmarske števke},
 				'mymrshan' => q{mjanmarske shan števke},
 				'mymrtlng' => q{mjanmarske števke Tai Laing},
 				'native' => q{izvorne števke},
 				'nkoo' => q{N’Ko števke},
 				'olck' => q{santalske števke},
 				'orya' => q{orijske števke},
 				'osma' => q{osmanijske števke},
 				'roman' => q{rimske številke},
 				'romanlow' => q{rimske male številke},
 				'saur' => q{Saurashtra števke},
 				'shrd' => q{Sharada števke},
 				'sind' => q{Khudawadi števke},
 				'sinh' => q{Sinhala Lith števke},
 				'sora' => q{Sora Sompeng števke},
 				'sund' => q{sundijske števke},
 				'takr' => q{Takri števke},
 				'talu' => q{Nove Tai Lue števke},
 				'taml' => q{tradicionalne tamilske številke},
 				'tamldec' => q{tamilske števke},
 				'telu' => q{teluške števke},
 				'thai' => q{tajske števke},
 				'tibt' => q{tibetanske števke},
 				'tirh' => q{Tirhuta števke},
 				'traditional' => q{Tradicionalne številke},
 				'vaii' => q{števke vai},
 				'wara' => q{Warang Citi števke},
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
			'metric' => q{metrični},
 			'UK' => q{angleški},
 			'US' => q{imperialni},

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
 			'script' => 'Pisava: {0}',
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
			auxiliary => qr{[áàăâåäā æ ç ć đ éèĕêëē íìĭîïī ñ óòŏôöøō œ q úùŭûüū w x yÿ]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a b c č d e f g h i j k l m n o p r s š t u v z ž]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ – , ; \: ! ? . … ' "„‟ « » ( ) \[ \] \{ \} @ *]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(stran neba),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(stran neba),
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
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
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
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
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
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(rona{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(rona{0}),
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
						'1' => q(kveta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kveta{0}),
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
						'few' => q({0} težni pospeški),
						'name' => q(težni pospešek),
						'one' => q({0} težni pospešek),
						'other' => q({0} težnih pospeškov),
						'two' => q({0} težna pospeška),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(masculine),
						'few' => q({0} težni pospeški),
						'name' => q(težni pospešek),
						'one' => q({0} težni pospešek),
						'other' => q({0} težnih pospeškov),
						'two' => q({0} težna pospeška),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'few' => q({0} metri na kvadratno sekundo),
						'name' => q(metri na kvadratno sekundo),
						'one' => q({0} meter na kvadratno sekundo),
						'other' => q({0} metrov na kvadratno sekundo),
						'two' => q({0} metra na kvadratno sekundo),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'few' => q({0} metri na kvadratno sekundo),
						'name' => q(metri na kvadratno sekundo),
						'one' => q({0} meter na kvadratno sekundo),
						'other' => q({0} metrov na kvadratno sekundo),
						'two' => q({0} metra na kvadratno sekundo),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'few' => q({0} kotne minute),
						'name' => q(kotna minuta),
						'one' => q({0} kotna minuta),
						'other' => q({0} kotnih minut),
						'two' => q({0} kotni minuti),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'few' => q({0} kotne minute),
						'name' => q(kotna minuta),
						'one' => q({0} kotna minuta),
						'other' => q({0} kotnih minut),
						'two' => q({0} kotni minuti),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'few' => q({0} kotne sekunde),
						'name' => q(kotna sekunda),
						'one' => q({0} kotna sekunda),
						'other' => q({0} kotnih sekund),
						'two' => q({0} kotni sekundi),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'few' => q({0} kotne sekunde),
						'name' => q(kotna sekunda),
						'one' => q({0} kotna sekunda),
						'other' => q({0} kotnih sekund),
						'two' => q({0} kotni sekundi),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(feminine),
						'few' => q({0} stopinje),
						'name' => q(stopinja),
						'one' => q({0} stopinja),
						'other' => q({0} stopinj),
						'two' => q({0} stopinji),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(feminine),
						'few' => q({0} stopinje),
						'name' => q(stopinja),
						'one' => q({0} stopinja),
						'other' => q({0} stopinj),
						'two' => q({0} stopinji),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'few' => q({0} radiani),
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianov),
						'two' => q({0} radiana),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'few' => q({0} radiani),
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianov),
						'two' => q({0} radiana),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(masculine),
						'few' => q({0} vrtljaji),
						'name' => q(vrtljaj),
						'one' => q({0} vrtljaj),
						'other' => q({0} vrtljajev),
						'two' => q({0} vrtljaja),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(masculine),
						'few' => q({0} vrtljaji),
						'name' => q(vrtljaj),
						'one' => q({0} vrtljaj),
						'other' => q({0} vrtljajev),
						'two' => q({0} vrtljaja),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} akri),
						'one' => q({0} aker),
						'other' => q({0} akrov),
						'two' => q({0} akra),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} akri),
						'one' => q({0} aker),
						'other' => q({0} akrov),
						'two' => q({0} akra),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'few' => q({0} hektari),
						'name' => q(hektari),
						'one' => q({0} hektar),
						'other' => q({0} hektarov),
						'two' => q({0} hektara),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'few' => q({0} hektari),
						'name' => q(hektari),
						'one' => q({0} hektar),
						'other' => q({0} hektarov),
						'two' => q({0} hektara),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} kvadratni centimetri),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimeter),
						'other' => q({0} kvadratnih centimetrov),
						'per' => q({0} na kvadratni centimeter),
						'two' => q({0} kvadratna centimetra),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} kvadratni centimetri),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimeter),
						'other' => q({0} kvadratnih centimetrov),
						'per' => q({0} na kvadratni centimeter),
						'two' => q({0} kvadratna centimetra),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} kvadratni čevlji),
						'name' => q(kvadratni čevelj),
						'one' => q({0} kvadratni čevelj),
						'other' => q({0} kvadratnih čevljev),
						'two' => q({0} kvadratna čevlja),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} kvadratni čevlji),
						'name' => q(kvadratni čevelj),
						'one' => q({0} kvadratni čevelj),
						'other' => q({0} kvadratnih čevljev),
						'two' => q({0} kvadratna čevlja),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} kvadratni palci),
						'name' => q(kvadratni palec),
						'one' => q({0} kvadratni palec),
						'other' => q({0} kvadratnih palcev),
						'per' => q({0} na kvadratni palec),
						'two' => q({0} kvadratna palca),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} kvadratni palci),
						'name' => q(kvadratni palec),
						'one' => q({0} kvadratni palec),
						'other' => q({0} kvadratnih palcev),
						'per' => q({0} na kvadratni palec),
						'two' => q({0} kvadratna palca),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kvadratni kilometri),
						'name' => q(kvadratni kilometri),
						'one' => q({0} kvadratni kilometer),
						'other' => q({0} kvadratnih kilometrov),
						'per' => q({0} na kvadratni kilometer),
						'two' => q({0} kvadratna kilometra),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kvadratni kilometri),
						'name' => q(kvadratni kilometri),
						'one' => q({0} kvadratni kilometer),
						'other' => q({0} kvadratnih kilometrov),
						'per' => q({0} na kvadratni kilometer),
						'two' => q({0} kvadratna kilometra),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'few' => q({0} kvadratni metri),
						'name' => q(kvadratni metri),
						'one' => q({0} kvadratni meter),
						'other' => q({0} kvadratnih metrov),
						'per' => q({0} na kvadratni meter),
						'two' => q({0} kvadratna metra),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'few' => q({0} kvadratni metri),
						'name' => q(kvadratni metri),
						'one' => q({0} kvadratni meter),
						'other' => q({0} kvadratnih metrov),
						'per' => q({0} na kvadratni meter),
						'two' => q({0} kvadratna metra),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratna milja),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milj),
						'per' => q({0} na kvadratno miljo),
						'two' => q({0} kvadratni milji),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratna milja),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milj),
						'per' => q({0} na kvadratno miljo),
						'two' => q({0} kvadratni milji),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} kvadratni jardi),
						'name' => q(kvadratni jard),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jardov),
						'two' => q({0} kvadratna jarda),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} kvadratni jardi),
						'name' => q(kvadratni jard),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jardov),
						'two' => q({0} kvadratna jarda),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'few' => q({0} elementi),
						'one' => q({0} element),
						'other' => q({0} elementov),
						'two' => q({0} elementa),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'few' => q({0} elementi),
						'one' => q({0} element),
						'other' => q({0} elementov),
						'two' => q({0} elementa),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'few' => q({0} karati),
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karatov),
						'two' => q({0} karata),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'few' => q({0} karati),
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karatov),
						'two' => q({0} karata),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'few' => q({0} miligrami na deciliter),
						'name' => q(miligrami na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramov na deciliter),
						'two' => q({0} miligrama na deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'few' => q({0} miligrami na deciliter),
						'name' => q(miligrami na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramov na deciliter),
						'two' => q({0} miligrama na deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'few' => q({0} milimoli na liter),
						'name' => q(milimol na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolov na liter),
						'two' => q({0} milimola na liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'few' => q({0} milimoli na liter),
						'name' => q(milimol na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolov na liter),
						'two' => q({0} milimola na liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(masculine),
						'few' => q({0} moli),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} molov),
						'two' => q({0} mola),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(masculine),
						'few' => q({0} moli),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} molov),
						'two' => q({0} mola),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'few' => q({0} odstotki),
						'one' => q({0} odstotek),
						'other' => q({0} odstotkov),
						'two' => q({0} odstotka),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'few' => q({0} odstotki),
						'one' => q({0} odstotek),
						'other' => q({0} odstotkov),
						'two' => q({0} odstotka),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'few' => q({0} promili),
						'one' => q({0} promile),
						'other' => q({0} promilov),
						'two' => q({0} promila),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'few' => q({0} promili),
						'one' => q({0} promile),
						'other' => q({0} promilov),
						'two' => q({0} promila),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(masculine),
						'few' => q({0} delci na milijon),
						'name' => q(delci na milijon),
						'one' => q({0} delec na milijon),
						'other' => q({0} delcev na milijon),
						'two' => q({0} delca na milijon),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(masculine),
						'few' => q({0} delci na milijon),
						'name' => q(delci na milijon),
						'one' => q({0} delec na milijon),
						'other' => q({0} delcev na milijon),
						'two' => q({0} delca na milijon),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(feminine),
						'few' => q({0} desettisočine),
						'name' => q(desettisočina),
						'one' => q({0} desettisočina),
						'other' => q({0} desettisočin),
						'two' => q({0} desettisočini),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(feminine),
						'few' => q({0} desettisočine),
						'name' => q(desettisočina),
						'one' => q({0} desettisočina),
						'other' => q({0} desettisočin),
						'two' => q({0} desettisočini),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(masculine),
						'few' => q({0} delci na milijardo),
						'name' => q(delci na milijardo),
						'one' => q({0} delec na milijardo),
						'other' => q({0} delcev na milijardo),
						'two' => q({0} delca na milijardo),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(masculine),
						'few' => q({0} delci na milijardo),
						'name' => q(delci na milijardo),
						'one' => q({0} delec na milijardo),
						'other' => q({0} delcev na milijardo),
						'two' => q({0} delca na milijardo),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri na 100 kilometrov),
						'name' => q(litri na 100 kilometrov),
						'one' => q({0} liter na 100 kilometrov),
						'other' => q({0} litrov na 100 kilometrov),
						'two' => q({0} litra na 100 kilometrov),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri na 100 kilometrov),
						'name' => q(litri na 100 kilometrov),
						'one' => q({0} liter na 100 kilometrov),
						'other' => q({0} litrov na 100 kilometrov),
						'two' => q({0} litra na 100 kilometrov),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri na kilometer),
						'name' => q(litri na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrov na kilometer),
						'two' => q({0} litra na kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri na kilometer),
						'name' => q(litri na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrov na kilometer),
						'two' => q({0} litra na kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} milje na galono),
						'name' => q(milje na galono),
						'one' => q({0} milja na galono),
						'other' => q({0} milj na galono),
						'two' => q({0} milji na galono),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} milje na galono),
						'name' => q(milje na galono),
						'one' => q({0} milja na galono),
						'other' => q({0} milj na galono),
						'two' => q({0} milji na galono),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} milje na imperialno galono),
						'name' => q(milje na imperialno galono),
						'one' => q({0} milja na imperialno galono),
						'other' => q({0} milj na imperialno galono),
						'two' => q({0} milji na imperialno galono),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} milje na imperialno galono),
						'name' => q(milje na imperialno galono),
						'one' => q({0} milja na imperialno galono),
						'other' => q({0} milj na imperialno galono),
						'two' => q({0} milji na imperialno galono),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} vzhodno),
						'north' => q({0} severno),
						'south' => q({0} južno),
						'west' => q({0} zahodno),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} vzhodno),
						'north' => q({0} severno),
						'south' => q({0} južno),
						'west' => q({0} zahodno),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'few' => q({0} biti),
						'one' => q({0} bit),
						'other' => q({0} bitov),
						'two' => q({0} bita),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'few' => q({0} biti),
						'one' => q({0} bit),
						'other' => q({0} bitov),
						'two' => q({0} bita),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
						'few' => q({0} bajti),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
						'two' => q({0} bajta),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
						'few' => q({0} bajti),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
						'two' => q({0} bajta),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
						'few' => q({0} gigabiti),
						'name' => q(gigabiti),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitov),
						'two' => q({0} gigabita),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'few' => q({0} gigabiti),
						'name' => q(gigabiti),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitov),
						'two' => q({0} gigabita),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'few' => q({0} gigabajti),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtov),
						'two' => q({0} gigabajta),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'few' => q({0} gigabajti),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtov),
						'two' => q({0} gigabajta),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'few' => q({0} kilobiti),
						'name' => q(kilobiti),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitov),
						'two' => q({0} kilobita),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'few' => q({0} kilobiti),
						'name' => q(kilobiti),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitov),
						'two' => q({0} kilobita),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
						'few' => q({0} kilobajti),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtov),
						'two' => q({0} kilobajta),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
						'few' => q({0} kilobajti),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtov),
						'two' => q({0} kilobajta),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'few' => q({0} megabiti),
						'name' => q(megabiti),
						'one' => q({0} megabit),
						'other' => q({0} megabitov),
						'two' => q({0} megabita),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'few' => q({0} megabiti),
						'name' => q(megabiti),
						'one' => q({0} megabit),
						'other' => q({0} megabitov),
						'two' => q({0} megabita),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'few' => q({0} megabajti),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtov),
						'two' => q({0} megabajta),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'few' => q({0} megabajti),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtov),
						'two' => q({0} megabajta),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(masculine),
						'few' => q({0} petabajti),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtov),
						'two' => q({0} petabajta),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
						'few' => q({0} petabajti),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtov),
						'two' => q({0} petabajta),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'few' => q({0} terabiti),
						'name' => q(terabiti),
						'one' => q({0} terabit),
						'other' => q({0} terabitov),
						'two' => q({0} terabita),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
						'few' => q({0} terabiti),
						'name' => q(terabiti),
						'one' => q({0} terabit),
						'other' => q({0} terabitov),
						'two' => q({0} terabita),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
						'few' => q({0} terabajti),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtov),
						'two' => q({0} terabajta),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
						'few' => q({0} terabajti),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtov),
						'two' => q({0} terabajta),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'few' => q({0} stoletja),
						'name' => q(stoletja),
						'one' => q({0} stoletje),
						'other' => q({0} stoletij),
						'two' => q({0} stoletji),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'few' => q({0} stoletja),
						'name' => q(stoletja),
						'one' => q({0} stoletje),
						'other' => q({0} stoletij),
						'two' => q({0} stoletji),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'few' => q({0} dni),
						'one' => q({0} dan),
						'other' => q({0} dni),
						'two' => q({0} dneva),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'few' => q({0} dni),
						'one' => q({0} dan),
						'other' => q({0} dni),
						'two' => q({0} dneva),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(feminine),
						'few' => q({0} dekade),
						'name' => q(dekade),
						'one' => q({0} dekada),
						'other' => q({0} dekad),
						'two' => q({0} dekadi),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'few' => q({0} dekade),
						'name' => q(dekade),
						'one' => q({0} dekada),
						'other' => q({0} dekad),
						'two' => q({0} dekadi),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'few' => q({0} ure),
						'one' => q({0} ura),
						'other' => q({0} ur),
						'per' => q({0} na uro),
						'two' => q({0} uri),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'few' => q({0} ure),
						'one' => q({0} ura),
						'other' => q({0} ur),
						'per' => q({0} na uro),
						'two' => q({0} uri),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekunde),
						'name' => q(mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekund),
						'two' => q({0} mikrosekundi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekunde),
						'name' => q(mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekund),
						'two' => q({0} mikrosekundi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekunde),
						'name' => q(milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekund),
						'two' => q({0} millisekundi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekunde),
						'name' => q(milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekund),
						'two' => q({0} millisekundi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minuta),
						'other' => q({0} minut),
						'per' => q({0} na minuto),
						'two' => q({0} minuti),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minuta),
						'other' => q({0} minut),
						'per' => q({0} na minuto),
						'two' => q({0} minuti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'few' => q({0} meseci),
						'one' => q({0} mesec),
						'other' => q({0} mesecev),
						'per' => q({0} na mesec),
						'two' => q({0} meseca),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'few' => q({0} meseci),
						'one' => q({0} mesec),
						'other' => q({0} mesecev),
						'per' => q({0} na mesec),
						'two' => q({0} meseca),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekunde),
						'name' => q(nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekund),
						'two' => q({0} nanosekundi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekunde),
						'name' => q(nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekund),
						'two' => q({0} nanosekundi),
					},
					# Long Unit Identifier
					'duration-night' => {
						'1' => q(feminine),
						'few' => q({0} noči),
						'name' => q(noči),
						'one' => q({0} noč),
						'other' => q({0} noči),
						'per' => q({0} na noč),
						'two' => q({0} noči),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(feminine),
						'few' => q({0} noči),
						'name' => q(noči),
						'one' => q({0} noč),
						'other' => q({0} noči),
						'per' => q({0} na noč),
						'two' => q({0} noči),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'few' => q({0} četrtletja),
						'name' => q(četrtletje),
						'one' => q({0} četrtletje),
						'other' => q({0} četrtletij),
						'per' => q({0}/četrtletje),
						'two' => q({0} četrtletji),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'few' => q({0} četrtletja),
						'name' => q(četrtletje),
						'one' => q({0} četrtletje),
						'other' => q({0} četrtletij),
						'per' => q({0}/četrtletje),
						'two' => q({0} četrtletji),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekund),
						'per' => q({0} na sekundo),
						'two' => q({0} sekundi),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekund),
						'per' => q({0} na sekundo),
						'two' => q({0} sekundi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(masculine),
						'few' => q({0} tedni),
						'one' => q({0} teden),
						'other' => q({0} tednov),
						'per' => q({0} na teden),
						'two' => q({0} tedna),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(masculine),
						'few' => q({0} tedni),
						'one' => q({0} teden),
						'other' => q({0} tednov),
						'per' => q({0} na teden),
						'two' => q({0} tedna),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(neuter),
						'few' => q({0} let),
						'one' => q({0} leto),
						'other' => q({0} let),
						'per' => q({0} na leto),
						'two' => q({0} leti),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(neuter),
						'few' => q({0} let),
						'one' => q({0} leto),
						'other' => q({0} let),
						'per' => q({0} na leto),
						'two' => q({0} leti),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'few' => q({0} amperi),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} amperov),
						'two' => q({0} ampera),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'few' => q({0} amperi),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} amperov),
						'two' => q({0} ampera),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'few' => q({0} milliamperi),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliamperov),
						'two' => q({0} miliampera),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'few' => q({0} milliamperi),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliamperov),
						'two' => q({0} miliampera),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'few' => q({0} ohmi),
						'name' => q(ohmi),
						'one' => q({0} ohm),
						'other' => q({0} ohmov),
						'two' => q({0} ohma),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'few' => q({0} ohmi),
						'name' => q(ohmi),
						'one' => q({0} ohm),
						'other' => q({0} ohmov),
						'two' => q({0} ohma),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'few' => q({0} volti),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} voltov),
						'two' => q({0} volta),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'few' => q({0} volti),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} voltov),
						'two' => q({0} volta),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} britanske toplotne enote),
						'name' => q(britanske toplotne enote),
						'one' => q({0} britanska toplotna enota),
						'other' => q({0} britanskih toplotnih enot),
						'two' => q({0} britanski toplotni enoti),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} britanske toplotne enote),
						'name' => q(britanske toplotne enote),
						'one' => q({0} britanska toplotna enota),
						'other' => q({0} britanskih toplotnih enot),
						'two' => q({0} britanski toplotni enoti),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorij),
						'two' => q({0} kaloriji),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorij),
						'two' => q({0} kaloriji),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektronvolti),
						'name' => q(elektronvolti),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltov),
						'two' => q({0} elektronvolta),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektronvolti),
						'name' => q(elektronvolti),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltov),
						'two' => q({0} elektronvolta),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorij),
						'two' => q({0} kaloriji),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorij),
						'two' => q({0} kaloriji),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'few' => q({0} džuli),
						'name' => q(džuli),
						'one' => q({0} džul),
						'other' => q({0} džulov),
						'two' => q({0} džula),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'few' => q({0} džuli),
						'name' => q(džuli),
						'one' => q({0} džul),
						'other' => q({0} džulov),
						'two' => q({0} džula),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorij),
						'two' => q({0} kilokaloriji),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorij),
						'two' => q({0} kilokaloriji),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'few' => q({0} kilodžuli),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžulov),
						'two' => q({0} kilodžula),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'few' => q({0} kilodžuli),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžulov),
						'two' => q({0} kilodžula),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(feminine),
						'few' => q({0} kilovatne ure),
						'name' => q(kilovatne ure),
						'one' => q({0} kilovatna ura),
						'other' => q({0} kilovatnih ur),
						'two' => q({0} kilovatni uri),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(feminine),
						'few' => q({0} kilovatne ure),
						'name' => q(kilovatne ure),
						'one' => q({0} kilovatna ura),
						'other' => q({0} kilovatnih ur),
						'two' => q({0} kilovatni uri),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'few' => q({0} kilovatne ure na 100 kilometrov),
						'name' => q(kilovatne ure na 100 kilometrov),
						'one' => q({0} kilovatna ura na 100 kilometrov),
						'other' => q({0} kilovatnih ur na 100 kilometrov),
						'two' => q({0} kilovatni uri na 100 kilometrov),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'few' => q({0} kilovatne ure na 100 kilometrov),
						'name' => q(kilovatne ure na 100 kilometrov),
						'one' => q({0} kilovatna ura na 100 kilometrov),
						'other' => q({0} kilovatnih ur na 100 kilometrov),
						'two' => q({0} kilovatni uri na 100 kilometrov),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'few' => q({0} newtoni),
						'name' => q(newtoni),
						'one' => q({0} newton),
						'other' => q({0} newtonov),
						'two' => q({0} newtona),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'few' => q({0} newtoni),
						'name' => q(newtoni),
						'one' => q({0} newton),
						'other' => q({0} newtonov),
						'two' => q({0} newtona),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} funti sile),
						'name' => q(funti sile),
						'one' => q({0} funt sile),
						'other' => q({0} funtov sile),
						'two' => q({0} funta sile),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} funti sile),
						'name' => q(funti sile),
						'one' => q({0} funt sile),
						'other' => q({0} funtov sile),
						'two' => q({0} funta sile),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'few' => q({0} gigaherci),
						'name' => q(gigaherc),
						'one' => q({0} gigaherc),
						'other' => q({0} gigahercev),
						'two' => q({0} gigaherca),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'few' => q({0} gigaherci),
						'name' => q(gigaherc),
						'one' => q({0} gigaherc),
						'other' => q({0} gigahercev),
						'two' => q({0} gigaherca),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'few' => q({0} herci),
						'name' => q(herc),
						'one' => q({0} herc),
						'other' => q({0} hercev),
						'two' => q({0} herca),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'few' => q({0} herci),
						'name' => q(herc),
						'one' => q({0} herc),
						'other' => q({0} hercev),
						'two' => q({0} herca),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'few' => q({0} kiloherci),
						'name' => q(kiloherc),
						'one' => q({0} kiloherc),
						'other' => q({0} kilohercev),
						'two' => q({0} kiloherca),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'few' => q({0} kiloherci),
						'name' => q(kiloherc),
						'one' => q({0} kiloherc),
						'other' => q({0} kilohercev),
						'two' => q({0} kiloherca),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'few' => q({0} megaherci),
						'name' => q(megaherc),
						'one' => q({0} megaherc),
						'other' => q({0} megahercev),
						'two' => q({0} megaherca),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'few' => q({0} megaherci),
						'name' => q(megaherc),
						'one' => q({0} megaherc),
						'other' => q({0} megahercev),
						'two' => q({0} megaherca),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'name' => q(pike na centimeter),
						'one' => q({0} pika na centimeter),
						'other' => q({0} pik na centimeter),
						'two' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'name' => q(pike na centimeter),
						'one' => q({0} pika na centimeter),
						'other' => q({0} pik na centimeter),
						'two' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} pike na palec),
						'name' => q(pik na palec),
						'one' => q({0} pika na palec),
						'other' => q({0} pik na palec),
						'two' => q({0} piki na palec),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} pike na palec),
						'name' => q(pik na palec),
						'one' => q({0} pika na palec),
						'other' => q({0} pik na palec),
						'two' => q({0} piki na palec),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'few' => q({0} emi),
						'one' => q({0} emov),
						'other' => q({0} emov),
						'two' => q({0} ema),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'few' => q({0} emi),
						'one' => q({0} emov),
						'other' => q({0} emov),
						'two' => q({0} ema),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'few' => q({0} megapiksli),
						'name' => q(megapiksli),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikslov),
						'two' => q({0} megapiksla),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'few' => q({0} megapiksli),
						'name' => q(megapiksli),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikslov),
						'two' => q({0} megapiksla),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'few' => q({0} piksli),
						'name' => q(piksli),
						'one' => q({0} piksel),
						'other' => q({0} pikslov),
						'two' => q({0} piksla),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'few' => q({0} piksli),
						'name' => q(piksli),
						'one' => q({0} piksel),
						'other' => q({0} pikslov),
						'two' => q({0} piksla),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(feminine),
						'few' => q({0} slikovne pike na centimeter),
						'name' => q(slikovne pike na centimeter),
						'one' => q({0} slikovna pika na centimeter),
						'other' => q({0} slikovnih pik na centimeter),
						'two' => q({0} slikovni piki na centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(feminine),
						'few' => q({0} slikovne pike na centimeter),
						'name' => q(slikovne pike na centimeter),
						'one' => q({0} slikovna pika na centimeter),
						'other' => q({0} slikovnih pik na centimeter),
						'two' => q({0} slikovni piki na centimeter),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomske enote),
						'name' => q(astronomska enota),
						'one' => q({0} astronomska enota),
						'other' => q({0} astronomskih enot),
						'two' => q({0} astronomski enoti),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomske enote),
						'name' => q(astronomska enota),
						'one' => q({0} astronomska enota),
						'other' => q({0} astronomskih enot),
						'two' => q({0} astronomski enoti),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri),
						'name' => q(centimetri),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrov),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetra),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri),
						'name' => q(centimetri),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrov),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetra),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'few' => q({0} decimetri),
						'name' => q(decimetri),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrov),
						'two' => q({0} decimetra),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'few' => q({0} decimetri),
						'name' => q(decimetri),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrov),
						'two' => q({0} decimetra),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} Zemljini polmeri),
						'name' => q(Zemljin polmer),
						'one' => q({0} Zemljin polmer),
						'other' => q({0} Zemljinih polmerov),
						'two' => q({0} Zemljina polmera),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} Zemljini polmeri),
						'name' => q(Zemljin polmer),
						'one' => q({0} Zemljin polmer),
						'other' => q({0} Zemljinih polmerov),
						'two' => q({0} Zemljina polmera),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} sežnji),
						'one' => q({0} seženj),
						'other' => q({0} sežnjev),
						'two' => q({0} sežnja),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} sežnji),
						'one' => q({0} seženj),
						'other' => q({0} sežnjev),
						'two' => q({0} sežnja),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} čevlji),
						'name' => q(čevlji),
						'one' => q({0} čevelj),
						'other' => q({0} čevljev),
						'per' => q({0} na čevelj),
						'two' => q({0} čevlja),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} čevlji),
						'name' => q(čevlji),
						'one' => q({0} čevelj),
						'other' => q({0} čevljev),
						'per' => q({0} na čevelj),
						'two' => q({0} čevlja),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlongi),
						'one' => q({0} furlong),
						'other' => q({0} furlongov),
						'two' => q({0} furlonga),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlongi),
						'one' => q({0} furlong),
						'other' => q({0} furlongov),
						'two' => q({0} furlonga),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} palci),
						'name' => q(palec),
						'one' => q({0} palec),
						'other' => q({0} palcev),
						'per' => q({0} na palec),
						'two' => q({0} palca),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} palci),
						'name' => q(palec),
						'one' => q({0} palec),
						'other' => q({0} palcev),
						'per' => q({0} na palec),
						'two' => q({0} palca),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri),
						'name' => q(kilometri),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrov),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometra),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri),
						'name' => q(kilometri),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrov),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometra),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} svetlobna leta),
						'name' => q(svetlobnih let),
						'one' => q({0} svetlobno leto),
						'other' => q({0} svetlobnih let),
						'two' => q({0} svetlobni leti),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} svetlobna leta),
						'name' => q(svetlobnih let),
						'one' => q({0} svetlobno leto),
						'other' => q({0} svetlobnih let),
						'two' => q({0} svetlobni leti),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'few' => q({0} metri),
						'name' => q(metri),
						'one' => q({0} meter),
						'other' => q({0} metrov),
						'per' => q({0} na meter),
						'two' => q({0} metra),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'few' => q({0} metri),
						'name' => q(metri),
						'one' => q({0} meter),
						'other' => q({0} metrov),
						'per' => q({0} na meter),
						'two' => q({0} metra),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'few' => q({0} mikrometri),
						'name' => q(mikrometri),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrov),
						'two' => q({0} mikrometra),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'few' => q({0} mikrometri),
						'name' => q(mikrometri),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrov),
						'two' => q({0} mikrometra),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} milje),
						'name' => q(milje),
						'one' => q({0} milja),
						'other' => q({0} milj),
						'two' => q({0} milji),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} milje),
						'name' => q(milje),
						'one' => q({0} milja),
						'other' => q({0} milj),
						'two' => q({0} milji),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavska milja),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milj),
						'two' => q({0} skandinavski milji),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavska milja),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milj),
						'two' => q({0} skandinavski milji),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'few' => q({0} milimetri),
						'name' => q(milimetri),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrov),
						'two' => q({0} milimetra),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'few' => q({0} milimetri),
						'name' => q(milimetri),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrov),
						'two' => q({0} milimetra),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'few' => q({0} nanometri),
						'name' => q(nanometri),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrov),
						'two' => q({0} nanometra),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'few' => q({0} nanometri),
						'name' => q(nanometri),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrov),
						'two' => q({0} nanometra),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} navtične milje),
						'name' => q(navtična milja),
						'one' => q({0} navtična milja),
						'other' => q({0} navtičnih milj),
						'two' => q({0} navtični milji),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} navtične milje),
						'name' => q(navtična milja),
						'one' => q({0} navtična milja),
						'other' => q({0} navtičnih milj),
						'two' => q({0} navtični milji),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parseki),
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsekov),
						'two' => q({0} parseka),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parseki),
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsekov),
						'two' => q({0} parseka),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'few' => q({0} pikometri),
						'name' => q(pikometri),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrov),
						'two' => q({0} pikometra),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'few' => q({0} pikometri),
						'name' => q(pikometri),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrov),
						'two' => q({0} pikometra),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(feminine),
						'few' => q({0} točke),
						'name' => q(točke),
						'one' => q({0} točka),
						'other' => q({0} točk),
						'two' => q({0} točki),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(feminine),
						'few' => q({0} točke),
						'name' => q(točke),
						'one' => q({0} točka),
						'other' => q({0} točk),
						'two' => q({0} točki),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} polmeri sonca),
						'name' => q(polmeri sonca),
						'one' => q({0} polmer sonca),
						'other' => q({0} polmerov sonca),
						'two' => q({0} polmera sonca),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} polmeri sonca),
						'name' => q(polmeri sonca),
						'one' => q({0} polmer sonca),
						'other' => q({0} polmerov sonca),
						'two' => q({0} polmera sonca),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} jardi),
						'name' => q(jardi),
						'one' => q({0} jard),
						'other' => q({0} jardov),
						'two' => q({0} jarda),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} jardi),
						'name' => q(jardi),
						'one' => q({0} jard),
						'other' => q({0} jardov),
						'two' => q({0} jarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'few' => q({0} kandele),
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandel),
						'two' => q({0} kandeli),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'few' => q({0} kandele),
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandel),
						'two' => q({0} kandeli),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'few' => q({0} lumni),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumnov),
						'two' => q({0} lumna),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'few' => q({0} lumni),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumnov),
						'two' => q({0} lumna),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'few' => q({0} luksi),
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksov),
						'two' => q({0} luksa),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'few' => q({0} luksi),
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksov),
						'two' => q({0} luksa),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} svetilnosti sonca),
						'name' => q(svetilnosti sonca),
						'one' => q({0} svetilnost sonca),
						'other' => q({0} svetilnosti sonca),
						'two' => q({0} svetilnosti sonca),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} svetilnosti sonca),
						'name' => q(svetilnosti sonca),
						'one' => q({0} svetilnost sonca),
						'other' => q({0} svetilnosti sonca),
						'two' => q({0} svetilnosti sonca),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'few' => q({0} karati),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karatov),
						'two' => q({0} karata),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'few' => q({0} karati),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karatov),
						'two' => q({0} karata),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltoni),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} daltonov),
						'two' => q({0} daltona),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltoni),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} daltonov),
						'two' => q({0} daltona),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} mase Zemlje),
						'name' => q(mase Zemlje),
						'one' => q({0} masa Zemlje),
						'other' => q({0} mas Zemlje),
						'two' => q({0} masi Zemlje),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} mase Zemlje),
						'name' => q(mase Zemlje),
						'one' => q({0} masa Zemlje),
						'other' => q({0} mas Zemlje),
						'two' => q({0} masi Zemlje),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'few' => q({0} grami),
						'name' => q(grami),
						'one' => q({0} gram),
						'other' => q({0} gramov),
						'per' => q({0} na gram),
						'two' => q({0} grama),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'few' => q({0} grami),
						'name' => q(grami),
						'one' => q({0} gram),
						'other' => q({0} gramov),
						'per' => q({0} na gram),
						'two' => q({0} grama),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'few' => q({0} kilogrami),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramov),
						'per' => q({0} na kilogram),
						'two' => q({0} kilograma),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'few' => q({0} kilogrami),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramov),
						'per' => q({0} na kilogram),
						'two' => q({0} kilograma),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'few' => q({0} mikrogrami),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramov),
						'two' => q({0} mikrograma),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'few' => q({0} mikrogrami),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramov),
						'two' => q({0} mikrograma),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'few' => q({0} miligrami),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligramov),
						'two' => q({0} miligrama),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'few' => q({0} miligrami),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligramov),
						'two' => q({0} miligrama),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unče),
						'name' => q(unče),
						'one' => q({0} unča),
						'other' => q({0} unč),
						'per' => q({0} na unčo),
						'two' => q({0} unči),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unče),
						'name' => q(unče),
						'one' => q({0} unča),
						'other' => q({0} unč),
						'per' => q({0} na unčo),
						'two' => q({0} unči),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} trojanske unče),
						'name' => q(trojanske unče),
						'one' => q({0} trojanska unča),
						'other' => q({0} trojanskih unč),
						'two' => q({0} trojanski unči),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} trojanske unče),
						'name' => q(trojanske unče),
						'one' => q({0} trojanska unča),
						'other' => q({0} trojanskih unč),
						'two' => q({0} trojanski unči),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} funti),
						'name' => q(funti),
						'one' => q({0} funt),
						'other' => q({0} funtov),
						'per' => q({0} na funt),
						'two' => q({0} funta),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} funti),
						'name' => q(funti),
						'one' => q({0} funt),
						'other' => q({0} funtov),
						'per' => q({0} na funt),
						'two' => q({0} funta),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} mase sonca),
						'name' => q(mase sonca),
						'one' => q({0} masa sonca),
						'other' => q({0} mas sonca),
						'two' => q({0} masi sonca),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} mase sonca),
						'name' => q(mase sonca),
						'one' => q({0} masa sonca),
						'other' => q({0} mas sonca),
						'two' => q({0} masi sonca),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} stoni),
						'one' => q({0} stone),
						'other' => q({0} stonov),
						'two' => q({0} stona),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} stoni),
						'one' => q({0} stone),
						'other' => q({0} stonov),
						'two' => q({0} stona),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} ameriške tone),
						'name' => q(ameriške tone),
						'one' => q({0} ameriška tona),
						'other' => q({0} ameriških ton),
						'two' => q({0} ameriški toni),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} ameriške tone),
						'name' => q(ameriške tone),
						'one' => q({0} ameriška tona),
						'other' => q({0} ameriških ton),
						'two' => q({0} ameriški toni),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'few' => q({0} metrične tone),
						'name' => q(metrične tone),
						'one' => q({0} metrična tona),
						'other' => q({0} metričnih ton),
						'two' => q({0} metrični toni),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'few' => q({0} metrične tone),
						'name' => q(metrične tone),
						'one' => q({0} metrična tona),
						'other' => q({0} metričnih ton),
						'two' => q({0} metrični toni),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(masculine),
						'few' => q({0} gigavati),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavatov),
						'two' => q({0} gigavata),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'few' => q({0} gigavati),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavatov),
						'two' => q({0} gigavata),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} konjske moči),
						'name' => q(konjska moč),
						'one' => q({0} konjska moč),
						'other' => q({0} konjskih moči),
						'two' => q({0} konjski moči),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} konjske moči),
						'name' => q(konjska moč),
						'one' => q({0} konjska moč),
						'other' => q({0} konjskih moči),
						'two' => q({0} konjski moči),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'few' => q({0} kilovati),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovatov),
						'two' => q({0} kilovata),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'few' => q({0} kilovati),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovatov),
						'two' => q({0} kilovata),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'few' => q({0} megavati),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavatov),
						'two' => q({0} megavata),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'few' => q({0} megavati),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavatov),
						'two' => q({0} megavata),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
						'few' => q({0} milivati),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivatov),
						'two' => q({0} milivata),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'few' => q({0} milivati),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivatov),
						'two' => q({0} milivata),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'few' => q({0} vati),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vatov),
						'two' => q({0} vata),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'few' => q({0} vati),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vatov),
						'two' => q({0} vata),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q(kvadratna {0}),
						'one' => q(kvadratno {0}),
						'other' => q(kvadratnih {0}),
						'two' => q(kvadratni {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q(kvadratna {0}),
						'one' => q(kvadratno {0}),
						'other' => q(kvadratnih {0}),
						'two' => q(kvadratni {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q(kubična {0}),
						'one' => q(kubično {0}),
						'other' => q(kubičnih {0}),
						'two' => q(kubični {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q(kubična {0}),
						'one' => q(kubično {0}),
						'other' => q(kubičnih {0}),
						'two' => q(kubični {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfer),
						'two' => q({0} atmosferi),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfer),
						'two' => q({0} atmosferi),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
						'few' => q({0} bari),
						'name' => q(bari),
						'one' => q({0} bar),
						'other' => q({0} barov),
						'two' => q({0} bara),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
						'few' => q({0} bari),
						'name' => q(bari),
						'one' => q({0} bar),
						'other' => q({0} barov),
						'two' => q({0} bara),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(masculine),
						'few' => q({0} hektopaskali),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskalov),
						'two' => q({0} hektopaskala),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'few' => q({0} hektopaskali),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskalov),
						'two' => q({0} hektopaskala),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} palci živega srebra),
						'name' => q(palci živega srebra),
						'one' => q({0} palec živega srebra),
						'other' => q({0} palcev živega srebra),
						'two' => q({0} palca živega srebra),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} palci živega srebra),
						'name' => q(palci živega srebra),
						'one' => q({0} palec živega srebra),
						'other' => q({0} palcev živega srebra),
						'two' => q({0} palca živega srebra),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'few' => q({0} kilopaskali),
						'name' => q(kilopaskali),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskalov),
						'two' => q({0} kilopaskala),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'few' => q({0} kilopaskali),
						'name' => q(kilopaskali),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskalov),
						'two' => q({0} kilopaskala),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'few' => q({0} megapaskali),
						'name' => q(megapaskali),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskalov),
						'two' => q({0} megapaskala),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'few' => q({0} megapaskali),
						'name' => q(megapaskali),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskalov),
						'two' => q({0} megapaskala),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'few' => q({0} milibari),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibarov),
						'two' => q({0} milibara),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'few' => q({0} milibari),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibarov),
						'two' => q({0} milibara),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'1' => q(masculine),
						'few' => q({0} milimetri živega srebra),
						'name' => q(milimetri živega srebra),
						'one' => q({0} milimeter živega srebra),
						'other' => q({0} milimetrov živega srebra),
						'two' => q({0} milimetra živega srebra),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(masculine),
						'few' => q({0} milimetri živega srebra),
						'name' => q(milimetri živega srebra),
						'one' => q({0} milimeter živega srebra),
						'other' => q({0} milimetrov živega srebra),
						'two' => q({0} milimetra živega srebra),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'few' => q({0} paskali),
						'name' => q(paskali),
						'one' => q({0} paskal),
						'other' => q({0} paskalov),
						'two' => q({0} paskala),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'few' => q({0} paskali),
						'name' => q(paskali),
						'one' => q({0} paskal),
						'other' => q({0} paskalov),
						'two' => q({0} paskala),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} funti na kvadratni palec),
						'name' => q(funti na kvadratni palec),
						'one' => q({0} funt na kvadratni palec),
						'other' => q({0} funtov na kvadratni palec),
						'two' => q({0} funta na kvadratni palec),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} funti na kvadratni palec),
						'name' => q(funti na kvadratni palec),
						'one' => q({0} funt na kvadratni palec),
						'other' => q({0} funtov na kvadratni palec),
						'two' => q({0} funta na kvadratni palec),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0} bofori),
						'name' => q(bofor),
						'one' => q({0} bofor),
						'other' => q({0} boforov),
						'two' => q({0} bofora),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0} bofori),
						'name' => q(bofor),
						'one' => q({0} bofor),
						'other' => q({0} boforov),
						'two' => q({0} bofora),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'few' => q({0} kilometri na uro),
						'name' => q(kilometri na uro),
						'one' => q({0} kilometer na uro),
						'other' => q({0} kilometrov na uro),
						'two' => q({0} kilometra na uro),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'few' => q({0} kilometri na uro),
						'name' => q(kilometri na uro),
						'one' => q({0} kilometer na uro),
						'other' => q({0} kilometrov na uro),
						'two' => q({0} kilometra na uro),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} vozli),
						'name' => q(vozel),
						'one' => q({0} vozel),
						'other' => q({0} vozlov),
						'two' => q({0} vozla),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} vozli),
						'name' => q(vozel),
						'one' => q({0} vozel),
						'other' => q({0} vozlov),
						'two' => q({0} vozla),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'1' => q(feminine),
						'few' => q({0} svetlobe),
						'name' => q(svetloba),
						'one' => q({0} svetloba),
						'other' => q({0} svetlob),
						'two' => q({0} svetlobi),
					},
					# Core Unit Identifier
					'light-speed' => {
						'1' => q(feminine),
						'few' => q({0} svetlobe),
						'name' => q(svetloba),
						'one' => q({0} svetloba),
						'other' => q({0} svetlob),
						'two' => q({0} svetlobi),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'few' => q({0} metri na sekundo),
						'name' => q(metri na sekundo),
						'one' => q({0} meter na sekundo),
						'other' => q({0} metrov na sekundo),
						'two' => q({0} metra na sekundo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'few' => q({0} metri na sekundo),
						'name' => q(metri na sekundo),
						'one' => q({0} meter na sekundo),
						'other' => q({0} metrov na sekundo),
						'two' => q({0} metra na sekundo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} milje na uro),
						'name' => q(milje na uro),
						'one' => q({0} milja na uro),
						'other' => q({0} milj na uro),
						'two' => q({0} milji na uro),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} milje na uro),
						'name' => q(milje na uro),
						'one' => q({0} milja na uro),
						'other' => q({0} milj na uro),
						'two' => q({0} milji na uro),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(feminine),
						'few' => q({0} stopinje Celzija),
						'name' => q(stopinje Celzija),
						'one' => q({0} stopinja Celzija),
						'other' => q({0} stopinj Celzija),
						'two' => q({0} stopinji Celzija),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(feminine),
						'few' => q({0} stopinje Celzija),
						'name' => q(stopinje Celzija),
						'one' => q({0} stopinja Celzija),
						'other' => q({0} stopinj Celzija),
						'two' => q({0} stopinji Celzija),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stopinje Farenheita),
						'name' => q(stopinje Farenheita),
						'one' => q({0} stopinja Farenheita),
						'other' => q({0} stopinj Farenheita),
						'two' => q({0} stopinji Farenheita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stopinje Farenheita),
						'name' => q(stopinje Farenheita),
						'one' => q({0} stopinja Farenheita),
						'other' => q({0} stopinj Farenheita),
						'two' => q({0} stopinji Farenheita),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(feminine),
						'few' => q({0} stopinje),
						'one' => q({0} stopinja),
						'other' => q({0} stopinj),
						'two' => q({0} stopinji),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(feminine),
						'few' => q({0} stopinje),
						'one' => q({0} stopinja),
						'other' => q({0} stopinj),
						'two' => q({0} stopinji),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'few' => q({0} kelvini),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinov),
						'two' => q({0} kelvina),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'few' => q({0} kelvini),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinov),
						'two' => q({0} kelvina),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'few' => q({0} newton metri),
						'name' => q(newton metri),
						'one' => q({0} newton meter),
						'other' => q({0} newton metrov),
						'two' => q({0} newton metra),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'few' => q({0} newton metri),
						'name' => q(newton metri),
						'one' => q({0} newton meter),
						'other' => q({0} newton metrov),
						'two' => q({0} newton metra),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} funt-čevlji),
						'name' => q(funt-čevelj),
						'one' => q({0} funt-čevelj),
						'other' => q({0} funt-čevljev),
						'two' => q({0} funt-čevlja),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} funt-čevlji),
						'name' => q(funt-čevelj),
						'one' => q({0} funt-čevelj),
						'other' => q({0} funt-čevljev),
						'two' => q({0} funt-čevlja),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} aker-čevlji),
						'name' => q(aker-čevelj),
						'one' => q({0} aker-čevelj),
						'other' => q({0} aker-čevljev),
						'two' => q({0} aker-čevlja),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} aker-čevlji),
						'name' => q(aker-čevelj),
						'one' => q({0} aker-čevelj),
						'other' => q({0} aker-čevljev),
						'two' => q({0} aker-čevlja),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} sodčki),
						'name' => q(sodčki),
						'one' => q({0} sodček),
						'other' => q({0} sodčkov),
						'two' => q({0} sodčka),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} sodčki),
						'name' => q(sodčki),
						'one' => q({0} sodček),
						'other' => q({0} sodčkov),
						'two' => q({0} sodčka),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušli),
						'one' => q({0} bušel),
						'other' => q({0} bušlov),
						'two' => q({0} bušla),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušli),
						'one' => q({0} bušel),
						'other' => q({0} bušlov),
						'two' => q({0} bušla),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'few' => q({0} centilitri),
						'name' => q(centilitri),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrov),
						'two' => q({0} centilitra),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'few' => q({0} centilitri),
						'name' => q(centilitri),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrov),
						'two' => q({0} centilitra),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} kubični centimetri),
						'name' => q(kubični centimeter),
						'one' => q({0} kubični centimeter),
						'other' => q({0} kubičnih centimetrov),
						'per' => q({0} na kubični centimeter),
						'two' => q({0} kubična centimetra),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} kubični centimetri),
						'name' => q(kubični centimeter),
						'one' => q({0} kubični centimeter),
						'other' => q({0} kubičnih centimetrov),
						'per' => q({0} na kubični centimeter),
						'two' => q({0} kubična centimetra),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} kubični čevlji),
						'name' => q(kubični čevlji),
						'one' => q({0} kubični čevelj),
						'other' => q({0} kubičnih čevljev),
						'two' => q({0} kubična čevlja),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} kubični čevlji),
						'name' => q(kubični čevlji),
						'one' => q({0} kubični čevelj),
						'other' => q({0} kubičnih čevljev),
						'two' => q({0} kubična čevlja),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} kubični palci),
						'name' => q(kubični palci),
						'one' => q({0} kubični palec),
						'other' => q({0} kubičnih palcev),
						'two' => q({0} kubična palca),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} kubični palci),
						'name' => q(kubični palci),
						'one' => q({0} kubični palec),
						'other' => q({0} kubičnih palcev),
						'two' => q({0} kubična palca),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kubični kilometri),
						'name' => q(kubični kilometri),
						'one' => q({0} kubični kilometer),
						'other' => q({0} kubičnih kilometrov),
						'two' => q({0} kubična kilometra),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kubični kilometri),
						'name' => q(kubični kilometri),
						'one' => q({0} kubični kilometer),
						'other' => q({0} kubičnih kilometrov),
						'two' => q({0} kubična kilometra),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'few' => q({0} kubični metri),
						'name' => q(kubični metri),
						'one' => q({0} kubični meter),
						'other' => q({0} kubičnih metrov),
						'per' => q({0} na kubični meter),
						'two' => q({0} kubična metra),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'few' => q({0} kubični metri),
						'name' => q(kubični metri),
						'one' => q({0} kubični meter),
						'other' => q({0} kubičnih metrov),
						'per' => q({0} na kubični meter),
						'two' => q({0} kubična metra),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} kubične milje),
						'name' => q(kubične milje),
						'one' => q({0} kubična milja),
						'other' => q({0} kubičnih milj),
						'two' => q({0} kubični milji),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} kubične milje),
						'name' => q(kubične milje),
						'one' => q({0} kubična milja),
						'other' => q({0} kubičnih milj),
						'two' => q({0} kubični milji),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} kubični jardi),
						'name' => q(kubični jard),
						'one' => q({0} kubični jard),
						'other' => q({0} kubičnih jardov),
						'two' => q({0} kubična jarda),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} kubični jardi),
						'name' => q(kubični jard),
						'one' => q({0} kubični jard),
						'other' => q({0} kubičnih jardov),
						'two' => q({0} kubična jarda),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} skodelice),
						'name' => q(skodelice),
						'one' => q({0} skodelica),
						'other' => q({0} skodelic),
						'two' => q({0} skodelici),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} skodelice),
						'name' => q(skodelice),
						'one' => q({0} skodelica),
						'other' => q({0} skodelic),
						'two' => q({0} skodelici),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrične skodelice),
						'name' => q(metrične skodelice),
						'one' => q({0} metrična skodelica),
						'other' => q({0} metričnih skodelic),
						'two' => q({0} metrični skodelici),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrične skodelice),
						'name' => q(metrične skodelice),
						'one' => q({0} metrična skodelica),
						'other' => q({0} metričnih skodelic),
						'two' => q({0} metrični skodelici),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'few' => q({0} decilitri),
						'name' => q(decilitri),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrov),
						'two' => q({0} decilitra),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'few' => q({0} decilitri),
						'name' => q(decilitri),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrov),
						'two' => q({0} decilitra),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} drahme),
						'name' => q(drahma),
						'one' => q({0} drahma),
						'other' => q({0} drahm),
						'two' => q({0} drahmi),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} drahme),
						'name' => q(drahma),
						'one' => q({0} drahma),
						'other' => q({0} drahm),
						'two' => q({0} drahmi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} tekoče unče),
						'name' => q(tekoče unče),
						'one' => q({0} tekoča unča),
						'other' => q({0} tekočih unč),
						'two' => q({0} tekoči unči),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} tekoče unče),
						'name' => q(tekoče unče),
						'one' => q({0} tekoča unča),
						'other' => q({0} tekočih unč),
						'two' => q({0} tekoči unči),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} imperialne tekočinske unče),
						'name' => q(imperialne tekočinske unče),
						'one' => q({0} imperialna tekočinska unča),
						'other' => q({0} imperialnih tekočinskih unč),
						'two' => q({0} imperialni tekočinski unči),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} imperialne tekočinske unče),
						'name' => q(imperialne tekočinske unče),
						'one' => q({0} imperialna tekočinska unča),
						'other' => q({0} imperialnih tekočinskih unč),
						'two' => q({0} imperialni tekočinski unči),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galone),
						'name' => q(galone),
						'one' => q({0} galona),
						'other' => q({0} galon),
						'per' => q({0} na galono),
						'two' => q({0} galoni),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galone),
						'name' => q(galone),
						'one' => q({0} galona),
						'other' => q({0} galon),
						'per' => q({0} na galono),
						'two' => q({0} galoni),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} imperialne galone),
						'name' => q(imperialna galona),
						'one' => q({0} imperialna galona),
						'other' => q({0} imperialnih galon),
						'per' => q({0} na imp. gal),
						'two' => q({0} imperialni galoni),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} imperialne galone),
						'name' => q(imperialna galona),
						'one' => q({0} imperialna galona),
						'other' => q({0} imperialnih galon),
						'per' => q({0} na imp. gal),
						'two' => q({0} imperialni galoni),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'few' => q({0} hektolitri),
						'name' => q(hektolitri),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrov),
						'two' => q({0} hektolitra),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'few' => q({0} hektolitri),
						'name' => q(hektolitri),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrov),
						'two' => q({0} hektolitra),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'few' => q({0} litri),
						'name' => q(litri),
						'one' => q({0} liter),
						'other' => q({0} litrov),
						'per' => q({0} na liter),
						'two' => q({0} litra),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'few' => q({0} litri),
						'name' => q(litri),
						'one' => q({0} liter),
						'other' => q({0} litrov),
						'per' => q({0} na liter),
						'two' => q({0} litra),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'few' => q({0} megalitri),
						'name' => q(megalitri),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrov),
						'two' => q({0} megalitra),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'few' => q({0} megalitri),
						'name' => q(megalitri),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrov),
						'two' => q({0} megalitra),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'few' => q({0} mililitri),
						'name' => q(mililitri),
						'one' => q({0} mililiter),
						'other' => q({0} militrov),
						'two' => q({0} mililitra),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'few' => q({0} mililitri),
						'name' => q(mililitri),
						'one' => q({0} mililiter),
						'other' => q({0} militrov),
						'two' => q({0} mililitra),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pint),
						'two' => q({0} pinti),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pint),
						'two' => q({0} pinti),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrične pinte),
						'name' => q(metrične pinte),
						'one' => q({0} metrična pinta),
						'other' => q({0} metričnih pint),
						'two' => q({0} metrični pinti),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrične pinte),
						'name' => q(metrične pinte),
						'one' => q({0} metrična pinta),
						'other' => q({0} metričnih pint),
						'two' => q({0} metrični pinti),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} četrtine),
						'name' => q(četrtine),
						'one' => q({0} četrtina),
						'other' => q({0} četrtin),
						'two' => q({0} četrtini),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} četrtine),
						'name' => q(četrtine),
						'one' => q({0} četrtina),
						'other' => q({0} četrtin),
						'two' => q({0} četrtini),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} imp. kvarti),
						'name' => q(Imp. kvart),
						'one' => q({0} imp. kvart),
						'other' => q({0} imp. kvartov),
						'two' => q({0} imp. kvarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} imp. kvarti),
						'name' => q(Imp. kvart),
						'one' => q({0} imp. kvart),
						'other' => q({0} imp. kvartov),
						'two' => q({0} imp. kvarta),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} jedilne žlice),
						'name' => q(jedilne žlice),
						'one' => q({0} jedilna žlica),
						'other' => q({0} jedilnih žlic),
						'two' => q({0} jedilni žlici),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} jedilne žlice),
						'name' => q(jedilne žlice),
						'one' => q({0} jedilna žlica),
						'other' => q({0} jedilnih žlic),
						'two' => q({0} jedilni žlici),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} čajne žličke),
						'name' => q(čajne žličke),
						'one' => q({0} čajna žlička),
						'other' => q({0} čajnih žličk),
						'two' => q({0} čajni žlički),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} čajne žličke),
						'name' => q(čajne žličke),
						'one' => q({0} čajna žlička),
						'other' => q({0} čajnih žličk),
						'two' => q({0} čajni žlički),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunum),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunum),
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
					'digital-byte' => {
						'few' => q({0} bajti),
						'one' => q({0} bajt),
						'other' => q({0} B),
						'two' => q({0} bajta),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bajti),
						'one' => q({0} bajt),
						'other' => q({0} B),
						'two' => q({0} bajta),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} st),
						'name' => q(st.),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} st),
						'name' => q(st.),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0}/dan.),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0}/dan.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ura),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ura),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mesec),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mesec),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} n),
						'name' => q(noči),
						'one' => q({0} n),
						'other' => q({0} n),
						'per' => q({0}/noč),
						'two' => q({0} n),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} n),
						'name' => q(noči),
						'one' => q({0} n),
						'other' => q({0} n),
						'per' => q({0}/noč),
						'two' => q({0} n),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} čl.),
						'one' => q({0} čl.),
						'other' => q({0} čl.),
						'two' => q({0} čl.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} čl.),
						'one' => q({0} čl.),
						'other' => q({0} čl.),
						'two' => q({0} čl.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(t),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(t),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(let),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(let),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pika),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pika),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} emi),
						'one' => q({0} emov),
						'other' => q({0} emov),
						'two' => q({0} ema),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} emi),
						'one' => q({0} emov),
						'other' => q({0} emov),
						'two' => q({0} ema),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sv. l.),
						'one' => q({0} sv. l.),
						'other' => q({0} sv. l.),
						'two' => q({0} sv. l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sv. l.),
						'one' => q({0} sv. l.),
						'other' => q({0} sv. l.),
						'two' => q({0} sv. l.),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} svetlobe),
						'name' => q(svetloba),
						'one' => q({0} svetloba),
						'other' => q({0} svetlob),
						'two' => q({0} svetlobi),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} svetlobe),
						'name' => q(svetloba),
						'one' => q({0} svetloba),
						'other' => q({0} svetlob),
						'two' => q({0} svetlobi),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} °),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} °),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} m. sk.),
						'one' => q({0} m. sk.),
						'other' => q({0} m. sk.),
						'two' => q({0} m. sk.),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} m. sk.),
						'one' => q({0} m. sk.),
						'other' => q({0} m. sk.),
						'two' => q({0} m. sk.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} des. žl.),
						'name' => q(des. žl.),
						'one' => q({0} des. žl.),
						'other' => q({0} des. žl.),
						'two' => q({0} des. žl.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} des. žl.),
						'name' => q(des. žl.),
						'one' => q({0} des. žl.),
						'other' => q({0} des. žl.),
						'two' => q({0} des. žl.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imp. des. žl.),
						'name' => q(imp. des. žl.),
						'one' => q({0} imp. des. žl.),
						'other' => q({0} imp. des. žl.),
						'two' => q({0} imp. des. žl.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imp. des. žl.),
						'name' => q(imp. des. žl.),
						'one' => q({0} imp. des. žl.),
						'other' => q({0} imp. des. žl.),
						'two' => q({0} imp. des. žl.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(smer),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(smer),
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
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} vrt),
						'name' => q(vrt),
						'one' => q({0} vrt),
						'other' => q({0} vrt),
						'two' => q({0} vrt),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} vrt),
						'name' => q(vrt),
						'one' => q({0} vrt),
						'other' => q({0} vrt),
						'two' => q({0} vrt),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(aker),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(aker),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunumi),
						'name' => q(dunumi),
						'one' => q({0} dunum),
						'other' => q({0} dunumi),
						'two' => q({0} dunuma),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunumi),
						'name' => q(dunumi),
						'one' => q({0} dunum),
						'other' => q({0} dunumi),
						'two' => q({0} dunuma),
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
						'few' => q({0} elementi),
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} elementov),
						'two' => q({0} elementa),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} elementi),
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} elementov),
						'two' => q({0} elementa),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} %),
						'name' => q(odstotek),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} %),
						'name' => q(odstotek),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'name' => q(promile),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'name' => q(promile),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
						'two' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
						'two' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} V),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} V),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} biti),
						'one' => q({0} bit),
						'other' => q({0} bitov),
						'two' => q({0} bita),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} biti),
						'one' => q({0} bit),
						'other' => q({0} bitov),
						'two' => q({0} bita),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} bajti),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
						'two' => q({0} bajta),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bajti),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
						'two' => q({0} bajta),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
						'two' => q({0} stol.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
						'two' => q({0} stol.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dni),
						'per' => q({0} na dan),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dni),
						'per' => q({0} na dan),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dek.),
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
						'two' => q({0} dek.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dek.),
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
						'two' => q({0} dek.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ure),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ure),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meseci),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meseci),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} noči),
						'name' => q(noči),
						'one' => q({0} noč),
						'other' => q({0} noči),
						'per' => q({0}/noč),
						'two' => q({0} noči),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} noči),
						'name' => q(noči),
						'one' => q({0} noč),
						'other' => q({0} noči),
						'per' => q({0}/noč),
						'two' => q({0} noči),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} četrtl.),
						'name' => q(četrt),
						'one' => q({0} četrtl.),
						'other' => q({0} četrtl.),
						'per' => q({0}/četrt),
						'two' => q({0} četrtl.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} četrtl.),
						'name' => q(četrt),
						'one' => q({0} četrtl.),
						'other' => q({0} četrtl.),
						'per' => q({0}/četrt),
						'two' => q({0} četrtl.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'two' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'two' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} t),
						'name' => q(tedni),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
						'two' => q({0} t),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} t),
						'name' => q(tedni),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
						'two' => q({0} t),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} l),
						'name' => q(leta),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} l),
						'name' => q(leta),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
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
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'two' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'two' => q({0} kcal),
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
					'graphics-dot' => {
						'few' => q({0} pike),
						'name' => q(pike),
						'one' => q({0} pika),
						'other' => q({0} pik),
						'two' => q({0} piki),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} pike),
						'name' => q(pike),
						'one' => q({0} pika),
						'other' => q({0} pik),
						'two' => q({0} piki),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
						'two' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
						'two' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
						'two' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
						'two' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} emi),
						'one' => q({0} emov),
						'other' => q({0} emov),
						'two' => q({0} ema),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} emi),
						'one' => q({0} emov),
						'other' => q({0} emov),
						'two' => q({0} ema),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} ae),
						'name' => q(ae),
						'one' => q({0} ae),
						'other' => q({0} ae),
						'two' => q({0} ae),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} ae),
						'name' => q(ae),
						'one' => q({0} ae),
						'other' => q({0} ae),
						'two' => q({0} ae),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(sežnji),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(sežnji),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongi),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongi),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sv. leta),
						'name' => q(sv. let),
						'one' => q({0} sv. let),
						'other' => q({0} sv. let),
						'two' => q({0} sv. leti),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sv. leta),
						'name' => q(sv. let),
						'one' => q({0} sv. let),
						'other' => q({0} sv. let),
						'two' => q({0} sv. leti),
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
					'length-point' => {
						'name' => q(točke),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(točke),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grani),
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granov),
						'two' => q({0} grana),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grani),
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granov),
						'two' => q({0} grana),
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
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} sh tn),
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
						'two' => q({0} sh tn),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} sh tn),
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
						'two' => q({0} sh tn),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} KM),
						'name' => q(KM),
						'one' => q({0} KM),
						'other' => q({0} KM),
						'two' => q({0} KM),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} KM),
						'name' => q(KM),
						'one' => q({0} KM),
						'other' => q({0} KM),
						'two' => q({0} KM),
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
						'few' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'two' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'two' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0} Bf),
						'name' => q(Bf),
						'one' => q({0} Bf),
						'other' => q({0} Bf),
						'two' => q({0} Bf),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0} Bf),
						'name' => q(Bf),
						'one' => q({0} Bf),
						'other' => q({0} Bf),
						'two' => q({0} Bf),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} svetlobe),
						'name' => q(svetloba),
						'one' => q({0} svetloba),
						'other' => q({0} svetlob),
						'two' => q({0} svetlobi),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} svetlobe),
						'name' => q(svetloba),
						'one' => q({0} svetloba),
						'other' => q({0} svetlob),
						'two' => q({0} svetlobi),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
						'two' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
						'two' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
						'two' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
						'two' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bušel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bušel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} m. skod.),
						'name' => q(m. skod.),
						'one' => q({0} m. skod.),
						'other' => q({0} m. skod.),
						'two' => q({0} m. skod.),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} m. skod.),
						'name' => q(m. skod.),
						'one' => q({0} m. skod.),
						'other' => q({0} m. skod.),
						'two' => q({0} m. skod.),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} desertne žličke),
						'name' => q(desertna žlička),
						'one' => q({0} desertna žlička),
						'other' => q({0} desertnih žličk),
						'two' => q({0} desertni žlički),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} desertne žličke),
						'name' => q(desertna žlička),
						'one' => q({0} desertna žlička),
						'other' => q({0} desertnih žličk),
						'two' => q({0} desertni žlički),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imp. desertne žličke),
						'name' => q(Imp. desertna žlička),
						'one' => q({0} imp. desertna žlička),
						'other' => q({0} imp. desertnih žličk),
						'two' => q({0} imp. desertni žlički),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imp. desertne žličke),
						'name' => q(Imp. desertna žlička),
						'one' => q({0} imp. desertna žlička),
						'other' => q({0} imp. desertnih žličk),
						'two' => q({0} imp. desertni žlički),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} tekoče drahme),
						'name' => q(tekoča drahma),
						'one' => q({0} tekoča drahma),
						'other' => q({0} tekočih drahm),
						'two' => q({0} tekoči drahmi),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} tekoče drahme),
						'name' => q(tekoča drahma),
						'one' => q({0} tekoča drahma),
						'other' => q({0} tekočih drahm),
						'two' => q({0} tekoči drahmi),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kapljice),
						'name' => q(kapljica),
						'one' => q({0} kapljica),
						'other' => q({0} kapljic),
						'two' => q({0} kapljici),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kapljice),
						'name' => q(kapljica),
						'one' => q({0} kapljica),
						'other' => q({0} kapljic),
						'two' => q({0} kapljici),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} imp. fl. oz.),
						'name' => q(imp. fl. oz.),
						'one' => q({0} imp. fl. oz.),
						'other' => q({0} imp. fl. oz.),
						'two' => q({0} imp. fl. oz.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} imp. fl. oz.),
						'name' => q(imp. fl. oz.),
						'one' => q({0} imp. fl. oz.),
						'other' => q({0} imp. fl. oz.),
						'two' => q({0} imp. fl. oz.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} imp. gal),
						'name' => q(imp. gal),
						'one' => q({0} imp. gal),
						'other' => q({0} imp. gal),
						'per' => q({0}/imp. gal),
						'two' => q({0} imp. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} imp. gal),
						'name' => q(imp. gal),
						'one' => q({0} imp. gal),
						'other' => q({0} imp. gal),
						'per' => q({0}/imp. gal),
						'two' => q({0} imp. gal),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} šilci),
						'name' => q(šilce),
						'one' => q({0} šilce),
						'other' => q({0} šilcev),
						'two' => q({0} šilca),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} šilci),
						'name' => q(šilce),
						'one' => q({0} šilce),
						'other' => q({0} šilcev),
						'two' => q({0} šilca),
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
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} ščepci),
						'name' => q(ščepec),
						'one' => q({0} ščepec),
						'other' => q({0} ščepcev),
						'two' => q({0} ščepca),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} ščepci),
						'name' => q(ščepec),
						'one' => q({0} ščepec),
						'other' => q({0} ščepcev),
						'two' => q({0} ščepca),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} imp. qt),
						'name' => q(Imp. qt),
						'one' => q({0} imp. qt),
						'other' => q({0} imp. qt),
						'two' => q({0} imp. qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} imp. qt),
						'name' => q(Imp. qt),
						'one' => q({0} imp. qt),
						'other' => q({0} imp. qt),
						'two' => q({0} imp. qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} žlice),
						'name' => q(žlica),
						'one' => q({0} žlica),
						'other' => q({0} žlic),
						'two' => q({0} žlici),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} žlice),
						'name' => q(žlica),
						'one' => q({0} žlica),
						'other' => q({0} žlic),
						'two' => q({0} žlici),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} žličke),
						'name' => q(žlička),
						'one' => q({0} žlička),
						'other' => q({0} žličk),
						'two' => q({0} žlički),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} žličke),
						'name' => q(žlička),
						'one' => q({0} žlička),
						'other' => q({0} žličk),
						'two' => q({0} žlički),
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
				end => q({0} in {1}),
				2 => q({0} in {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 2,
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
			'minusSign' => q(−),
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
					'few' => '0 tisoč',
					'one' => '0 tisoč',
					'other' => '0 tisoč',
					'two' => '0 tisoč',
				},
				'10000' => {
					'few' => '00 tisoč',
					'one' => '00 tisoč',
					'other' => '00 tisoč',
					'two' => '00 tisoč',
				},
				'100000' => {
					'few' => '000 tisoč',
					'one' => '000 tisoč',
					'other' => '000 tisoč',
					'two' => '000 tisoč',
				},
				'1000000' => {
					'few' => '0 milijone',
					'one' => '0 milijon',
					'other' => '0 milijonov',
					'two' => '0 milijona',
				},
				'10000000' => {
					'few' => '00 milijoni',
					'one' => '00 milijon',
					'other' => '00 milijonov',
					'two' => '00 milijona',
				},
				'100000000' => {
					'few' => '000 milijoni',
					'one' => '000 milijon',
					'other' => '000 milijonov',
					'two' => '000 milijona',
				},
				'1000000000' => {
					'few' => '0 milijarde',
					'one' => '0 milijarda',
					'other' => '0 milijard',
					'two' => '0 milijardi',
				},
				'10000000000' => {
					'few' => '00 milijarde',
					'one' => '00 milijarda',
					'other' => '00 milijard',
					'two' => '00 milijardi',
				},
				'100000000000' => {
					'few' => '000 milijarde',
					'one' => '000 milijarda',
					'other' => '000 milijard',
					'two' => '000 milijardi',
				},
				'1000000000000' => {
					'few' => '0 bilijoni',
					'one' => '0 bilijon',
					'other' => '0 bilijonov',
					'two' => '0 bilijona',
				},
				'10000000000000' => {
					'few' => '00 bilijoni',
					'one' => '00 bilijon',
					'other' => '00 bilijonov',
					'two' => '00 bilijona',
				},
				'100000000000000' => {
					'few' => '000 bilijoni',
					'one' => '000 bilijon',
					'other' => '000 bilijonov',
					'two' => '000 bilijona',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
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
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
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
					'accounting' => {
						'negative' => '(#,##0.00 ¤)',
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
				'currency' => q(andorska peseta),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham Združenih arabskih emiratov),
				'few' => q(dirhami Združenih arabskih emiratov),
				'one' => q(dirham Združenih arabskih emiratov),
				'other' => q(dirhamov Združenih arabskih emiratov),
				'two' => q(dirhama Združenih arabskih emiratov),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(stari afganistanski afgani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani),
				'few' => q(afganiji),
				'one' => q(afgani),
				'other' => q(afganijev),
				'two' => q(afganija),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albanski lek),
				'few' => q(albanski leki),
				'one' => q(albanski lek),
				'other' => q(albanskih lekov),
				'two' => q(albanska leka),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armenski dram),
				'few' => q(armenski drami),
				'one' => q(armenski dram),
				'other' => q(armenskih dramov),
				'two' => q(armenska drama),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nizozemsko-antilski gulden),
				'few' => q(nizozemsko-antilski guldni),
				'one' => q(nizozemsko-antilski gulden),
				'other' => q(nizozemsko-antilskih guldnov),
				'two' => q(nizozemsko-antilska guldna),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolska kvanza),
				'few' => q(angolske kvanze),
				'one' => q(angolska kvanza),
				'other' => q(angolskih kvanz),
				'two' => q(angolski kvanzi),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(stara angolska kvanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolska nova kvanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(konvertibilna angolska kvanza \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinski avstral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinski peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinski peso),
				'few' => q(argentinski pesi),
				'one' => q(argentinski peso),
				'other' => q(argentinskih pesov),
				'two' => q(argentinska pesa),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(avstrijski šiling),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(avstralski dolar),
				'few' => q(avstralski dolarji),
				'one' => q(avstralski dolar),
				'other' => q(avstralskih dolarjev),
				'two' => q(avstralska dolarja),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubski florin),
				'few' => q(arubski florini),
				'one' => q(arubski florin),
				'other' => q(arubskih florinov),
				'two' => q(arubska florina),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(stari azerbajdžanski manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdžanski manat),
				'few' => q(azerbajdžanski manati),
				'one' => q(azerbajdžanski manat),
				'other' => q(azerbajdžanskih manatov),
				'two' => q(azerbajdžanska manata),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosansko-hercegovski dinar),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosansko-hercegovska konvertibilna marka),
				'few' => q(bosansko-hercegovske konvertibilne marke),
				'one' => q(bosansko-hercegovska konvertibilna marka),
				'other' => q(bosansko-hercegovskih konvertibilnih mark),
				'two' => q(bosansko-hercegovski konvertibilni marki),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoški dolar),
				'few' => q(barbadoški dolarji),
				'one' => q(barbadoški dolar),
				'other' => q(barbadoških dolarjev),
				'two' => q(barbadoška dolarja),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeška taka),
				'few' => q(bangladeške take),
				'one' => q(bangladeška taka),
				'other' => q(bangladeških tak),
				'two' => q(bangladeški taki),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgijski konvertibilni frank),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgijski frank),
				'few' => q(belgijski franki),
				'one' => q(belgijski frank),
				'other' => q(belgijskih frankov),
				'two' => q(belgijska franka),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgijski finančni frank),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(stari bolgarski lev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bolgarski lev),
				'few' => q(bolgarski levi),
				'one' => q(bolgarski lev),
				'other' => q(bolgarskih levov),
				'two' => q(bolgarska leva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrajnski dinar),
				'few' => q(bahrajnski dinarji),
				'one' => q(bahrajnski dinar),
				'other' => q(bahrajnskih dinarjev),
				'two' => q(bahrajnska dinarja),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundski frank),
				'few' => q(burundski franki),
				'one' => q(burundski frank),
				'other' => q(burundskih frankov),
				'two' => q(burundska franka),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudski dolar),
				'few' => q(bermudski dolarji),
				'one' => q(bermudski dolar),
				'other' => q(bermudskih dolarjev),
				'two' => q(bermudska dolarja),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brunejski dolar),
				'few' => q(brunejski dolarji),
				'one' => q(brunejski dolar),
				'other' => q(brunejskih dolarjev),
				'two' => q(brunejska dolarja),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivijski boliviano),
				'few' => q(bolivijski boliviani),
				'one' => q(bolivijski boliviano),
				'other' => q(bolivijskih bolivianov),
				'two' => q(bolivijska boliviana),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(bolivijski peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(bolivijski mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazilski novi kruzeiro \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilski kruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(stari brazilski kruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brazilski real),
				'few' => q(brazilski reali),
				'one' => q(brazilski real),
				'other' => q(brazilskih realov),
				'two' => q(brazilska reala),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(novi brazilski kruzado),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brazilski kruzeiro),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamski dolar),
				'few' => q(bahamski dolarji),
				'one' => q(bahamski dolar),
				'other' => q(bahamskih dolarjev),
				'two' => q(bahamska dolarja),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(butanski ngultrum),
				'few' => q(butanski ngultrumi),
				'one' => q(butanski ngultrum),
				'other' => q(butanskih ngultrumov),
				'two' => q(butanska ngultruma),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmanski kjat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(bocvanska pula),
				'few' => q(bocvanske pule),
				'one' => q(bocvanska pula),
				'other' => q(bocvanskih pul),
				'two' => q(bocvanski puli),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(beloruski novi rubelj \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(beloruski rubelj),
				'few' => q(beloruski rublji),
				'one' => q(beloruski rubelj),
				'other' => q(beloruskih rubljev),
				'two' => q(beloruska rublja),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(beloruski rubelj \(2000–2016\)),
				'few' => q(beloruski rublji \(2000–2016\)),
				'one' => q(beloruski rubelj \(2000–2016\)),
				'other' => q(beloruskih rubljev \(2000–2016\)),
				'two' => q(beloruska rublja \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizejski dolar),
				'few' => q(belizejski dolarji),
				'one' => q(belizejski dolar),
				'other' => q(belizejskih dolarjev),
				'two' => q(belizejska dolarja),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadski dolar),
				'few' => q(kanadski dolarji),
				'one' => q(kanadski dolar),
				'other' => q(kanadskih dolarjev),
				'two' => q(kanadska dolarja),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongovski frank),
				'few' => q(kongovski franki),
				'one' => q(kongovski frank),
				'other' => q(kongovskih frankov),
				'two' => q(kongovska franka),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(evro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(švicarski frank),
				'few' => q(švicarski franki),
				'one' => q(švicarski frank),
				'other' => q(švicarskih frankov),
				'two' => q(švicarska franka),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(frank WIR),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(čilski unidades de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(čilski peso),
				'few' => q(čilski pesi),
				'one' => q(čilski peso),
				'other' => q(čilskih pesov),
				'two' => q(čilska pesa),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kitajski juan \(offshore\)),
				'few' => q(kitajski juani renminbi \(offshore\)),
				'one' => q(kitajski juan renminbi \(offshore\)),
				'other' => q(kitajskih juanov renminbi \(offshore\)),
				'two' => q(kitajska juana renminbi \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kitajski juan),
				'few' => q(kitajski juani renminbi),
				'one' => q(kitajski juan renminbi),
				'other' => q(kitajskih juanov renminbi),
				'two' => q(kitajska juana renmibi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbijski peso),
				'few' => q(kolumbijski pesi),
				'one' => q(kolumbijski peso),
				'other' => q(kolumbijskih pesov),
				'two' => q(kolumbijska pesa),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(kolumbijska enota realne vrednosti),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostariški kolon),
				'few' => q(kostariški koloni),
				'one' => q(kostariški kolon),
				'other' => q(kostariških kolonov),
				'two' => q(kostariška kolona),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(stari srbski dinar),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(češkoslovaška krona),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubanski konvertibilni peso),
				'few' => q(kubanski konvertibilni pesi),
				'one' => q(kubanski konvertibilni peso),
				'other' => q(kubanskih konvertibilnih pesov),
				'two' => q(kubanska konvertibilna pesa),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubanski peso),
				'few' => q(kubanski pesi),
				'one' => q(kubanski peso),
				'other' => q(kubanskih pesov),
				'two' => q(kubanska pesa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(zelenortski eskudo),
				'few' => q(zelenortski eskudi),
				'one' => q(zelenortski eskudo),
				'other' => q(zelenortskih eskudov),
				'two' => q(zelenortska eskuda),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(ciprski funt),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(češka krona),
				'few' => q(češke krone),
				'one' => q(češka krona),
				'other' => q(čeških kron),
				'two' => q(češki kroni),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(vzhodnonemška marka),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(nemška marka),
				'few' => q(nemške marke),
				'one' => q(nemška marka),
				'other' => q(nemških mark),
				'two' => q(nemški marki),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(džibutski frank),
				'few' => q(džibutski franki),
				'one' => q(džibutski frank),
				'other' => q(džibutskih frankov),
				'two' => q(džibutska franka),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(danska krona),
				'few' => q(danske krone),
				'one' => q(danska krona),
				'other' => q(danskih kron),
				'two' => q(danski kroni),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikanski peso),
				'few' => q(dominikanski pesi),
				'one' => q(dominikanski peso),
				'other' => q(dominikanskih pesov),
				'two' => q(dominikanska pesa),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alžirski dinar),
				'few' => q(alžirski dinarji),
				'one' => q(alžirski dinar),
				'other' => q(alžirskih dinarjev),
				'two' => q(alžirska dinarja),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ekvadorski sukre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ekvadorska enota realne vrednosti \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estonska krona),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egiptovski funt),
				'few' => q(egiptovski funti),
				'one' => q(egiptovski funt),
				'other' => q(egiptovskih funtov),
				'two' => q(egiptovska funta),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrejska nakfa),
				'few' => q(eritrejske nakfe),
				'one' => q(eritrejska nakfa),
				'other' => q(eritrejskih nakf),
				'two' => q(eritrejski nakfi),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(španska pezeta \(račun A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(španska pezeta \(račun B\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(španska pezeta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopski bir),
				'few' => q(etiopski biri),
				'one' => q(etiopski bir),
				'other' => q(etiopskih birov),
				'two' => q(etiopska bira),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(evro),
				'few' => q(evri),
				'one' => q(evro),
				'other' => q(evrov),
				'two' => q(evra),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finska marka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidžijski dolar),
				'few' => q(fidžijski dolarji),
				'one' => q(fidžijski dolar),
				'other' => q(fidžijskih dolarjev),
				'two' => q(fidžijska dolarja),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandski funt),
				'few' => q(falklandski funti),
				'one' => q(falklandski funt),
				'other' => q(falklandskih funtov),
				'two' => q(falklandska funta),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(francoski frank),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(britanski funt),
				'few' => q(britanski funti),
				'one' => q(britanski funt),
				'other' => q(britanskih funtov),
				'two' => q(britanska funta),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(gruzijski bon lari),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(gruzijski lari),
				'few' => q(gruzijski lariji),
				'one' => q(gruzijski lari),
				'other' => q(gruzijskih larijev),
				'two' => q(gruzijska larija),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(stari ganski cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ganski cedi),
				'few' => q(ganski cedi),
				'one' => q(ganski cedi),
				'other' => q(ganskih cedov),
				'two' => q(ganska ceda),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarski funt),
				'few' => q(gibraltarski funti),
				'one' => q(gibraltarski funt),
				'other' => q(gibraltarskih funtov),
				'two' => q(gibraltarska funta),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambijski dalasi),
				'few' => q(gambijski dalasi),
				'one' => q(gambijski dalasi),
				'other' => q(gambijskih dalasov),
				'two' => q(gambijska dalasa),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(gvinejski frank),
				'few' => q(gvinejski franki),
				'one' => q(gvinejski frank),
				'other' => q(gvinejskih frankov),
				'two' => q(gvinejska franka),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(gvinejski sili),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele Ekvatorialne Gvineje),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(grška drahma),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(gvatemalski kecal),
				'few' => q(gvatemalski kecali),
				'one' => q(gvatemalski kecal),
				'other' => q(gvatemalskih kecalov),
				'two' => q(gvatemalska kecala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(eskudo Portugalske Gvineje),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso Gvineje Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(gvajanski dolar),
				'few' => q(gvajanski dolarji),
				'one' => q(gvajanski dolar),
				'other' => q(gvajanskih dolarjev),
				'two' => q(gvajanska dolarja),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(hongkonški dolar),
				'few' => q(hongkonški dolarji),
				'one' => q(hongkonški dolar),
				'other' => q(hongkonških dolarjev),
				'two' => q(hongkonška dolarja),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraška lempira),
				'few' => q(honduraške lempire),
				'one' => q(honduraška lempira),
				'other' => q(honduraških lempir),
				'two' => q(honduraški lempiri),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(hrvaški dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(hrvaška kuna),
				'few' => q(hrvaške kune),
				'one' => q(hrvaška kuna),
				'other' => q(hrvaških kun),
				'two' => q(hrvaški kuni),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitijski gurd),
				'few' => q(haitijski gurdi),
				'one' => q(haitijski gurd),
				'other' => q(haitijskih gurdov),
				'two' => q(haitijska gurda),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(madžarski forint),
				'few' => q(madžarski forinti),
				'one' => q(madžarski forint),
				'other' => q(madžarskih forintov),
				'two' => q(madžarska forinta),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonezijska rupija),
				'few' => q(indonezijske rupije),
				'one' => q(indonezijska rupija),
				'other' => q(indonezijskih rupij),
				'two' => q(indonezijski rupiji),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(irski funt),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(izraelski funt),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(izraelski šekel),
				'few' => q(izraelski šekli),
				'one' => q(izraelski šekel),
				'other' => q(izraelskih šeklov),
				'two' => q(izraelska šekla),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indijska rupija),
				'few' => q(indijske rupije),
				'one' => q(indijska rupija),
				'other' => q(indijskih rupij),
				'two' => q(indijski rupiji),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(iraški dinar),
				'few' => q(iraški dinarji),
				'one' => q(iraški dinar),
				'other' => q(iraških dinarjev),
				'two' => q(iraška dinarja),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranski rial),
				'few' => q(iranski riali),
				'one' => q(iranski rial),
				'other' => q(iranskih rialov),
				'two' => q(iranska riala),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandska krona),
				'few' => q(islandske krone),
				'one' => q(islandska krona),
				'other' => q(islandskih kron),
				'two' => q(islandski kroni),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italijanska lira),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamajški dolar),
				'few' => q(jamajški dolarji),
				'one' => q(jamajški dolar),
				'other' => q(jamajških dolarjev),
				'two' => q(jamajška dolarja),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordanski dinar),
				'few' => q(jordanski dinarji),
				'one' => q(jordanski dinar),
				'other' => q(jordanskih dinarjev),
				'two' => q(jordanska dinarja),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japonski jen),
				'few' => q(japonski jeni),
				'one' => q(japonski jen),
				'other' => q(japonskih jenov),
				'two' => q(japonska jena),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenijski šiling),
				'few' => q(kenijski šilingi),
				'one' => q(kenijski šiling),
				'other' => q(kenijskih šilingov),
				'two' => q(kenijska šilinga),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgiški som),
				'few' => q(kirgiški somi),
				'one' => q(kirgiški som),
				'other' => q(kirgiških somov),
				'two' => q(kirgiška soma),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kamboški riel),
				'few' => q(kamboški rieli),
				'one' => q(kamboški riel),
				'other' => q(kamboških rielov),
				'two' => q(kamboška riela),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorski frank),
				'few' => q(komorski franki),
				'one' => q(komorski frank),
				'other' => q(komorskih frankov),
				'two' => q(komorska franka),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(severnokorejski von),
				'few' => q(severnokorejski voni),
				'one' => q(severnokorejski von),
				'other' => q(severnokorejskih vonov),
				'two' => q(severnokorejska vona),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(južnokorejski von),
				'few' => q(južnokorejski voni),
				'one' => q(južnokorejski von),
				'other' => q(južnokorejskih vonov),
				'two' => q(južnokorejska vona),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuvajtski dinar),
				'few' => q(kuvajtski dinarji),
				'one' => q(kuvajtski dinar),
				'other' => q(kuvajtskih dinarjev),
				'two' => q(kuvajtska dinarja),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmanski dolar),
				'few' => q(kajmanski dolarji),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanskih dolarjev),
				'two' => q(kajmanska dolarja),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazahstanski tenge),
				'few' => q(kazahstanski tenge),
				'one' => q(kazahstanski tenge),
				'other' => q(kazahstanskih tengov),
				'two' => q(kazahstanska tenga),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoški kip),
				'few' => q(laoški kipi),
				'one' => q(laoški kip),
				'other' => q(laoških kipov),
				'two' => q(laoška kipa),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanonski funt),
				'few' => q(libanonski funti),
				'one' => q(libanonski funt),
				'other' => q(libanonskih funtov),
				'two' => q(libanonska funta),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(šrilanška rupija),
				'few' => q(šrilanške rupije),
				'one' => q(šrilanška rupija),
				'other' => q(šrilanških rupij),
				'two' => q(šrilanški rupiji),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberijski dolar),
				'few' => q(liberijski dolarji),
				'one' => q(liberijski dolar),
				'other' => q(liberijskih dolarjev),
				'two' => q(liberijska dolarja),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesotski loti),
				'few' => q(lesotski loti),
				'one' => q(lesotski loti),
				'other' => q(lesotskih lotov),
				'two' => q(lesotska lota),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litovski litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litvanski litas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luksemburški konvertibilni frank),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(luksemburški frank),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luksemburški finančni frank),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latvijski lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latvijski rubelj),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libijski dinar),
				'few' => q(libijski dinarji),
				'one' => q(libijski dinar),
				'other' => q(libijskih dinarjev),
				'two' => q(libijska dinarja),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(maroški dirham),
				'few' => q(maroški dirhami),
				'one' => q(maroški dirham),
				'other' => q(maroških dirhamov),
				'two' => q(maroška dirhama),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(maroški frank),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldavski lev),
				'few' => q(moldavski levi),
				'one' => q(moldavski lev),
				'other' => q(moldavskih levov),
				'two' => q(moldavska leva),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskarski ariari),
				'few' => q(madagaskarski ariariji),
				'one' => q(madagaskarski ariari),
				'other' => q(madagaskarskih ariarijev),
				'two' => q(madagaskarska ariarija),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(malgaški frank),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonski denar),
				'few' => q(makedonski denarji),
				'one' => q(makedonski denar),
				'other' => q(makedonskih denarjev),
				'two' => q(makedonska denarja),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(malijski frank),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(mjanmarski kjat),
				'few' => q(mjanmarski kjati),
				'one' => q(mjanmarski kjat),
				'other' => q(mjanmarskih kjatov),
				'two' => q(mjanmarska kjata),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolski tugriki),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskih tugrikov),
				'two' => q(mongolska tugrika),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macajska pataka),
				'few' => q(macajske patake),
				'one' => q(macajska pataka),
				'other' => q(macajskih patak),
				'two' => q(macajski pataki),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mavretanska uguija \(1973–2017\)),
				'few' => q(mavretanske uguije \(1973–2017\)),
				'one' => q(mavretanska uguija \(1973–2017\)),
				'other' => q(mavretanskih uguij \(1973–2017\)),
				'two' => q(mavretanski uguiji \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mavretanska uguija),
				'few' => q(mavretanske uguije),
				'one' => q(mavretanska uguija),
				'other' => q(mavretanskih uguij),
				'two' => q(mavretanski uguiji),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(malteška lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(malteški funt),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mavricijska rupija),
				'few' => q(mavricijske rupije),
				'one' => q(mavricijska rupija),
				'other' => q(mavricijskih rupij),
				'two' => q(mavricijski rupiji),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivska rufija),
				'few' => q(maldivske rufije),
				'one' => q(maldivska rufija),
				'other' => q(maldivskih rufij),
				'two' => q(maldivski rufiji),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malavijska kvača),
				'few' => q(malavijske kvače),
				'one' => q(malavijska kvača),
				'other' => q(malavijskih kvač),
				'two' => q(malavijski kvači),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(mehiški peso),
				'few' => q(mehiški pesi),
				'one' => q(mehiški peso),
				'other' => q(mehiških pesov),
				'two' => q(mehiška pesa),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(mehiški srebrni peso \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(mehiška inverzna enota \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malezijski ringit),
				'few' => q(malezijski ringiti),
				'one' => q(malezijski ringit),
				'other' => q(malezijskih ringitov),
				'two' => q(malezijska ringita),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mozambiški eskudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(stari mozambiški metikal),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambiški metikal),
				'few' => q(mozambiški metikali),
				'one' => q(mozambiški metikal),
				'other' => q(mozambiških metikalov),
				'two' => q(mozambiška metikala),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibijski dolar),
				'few' => q(namibijski dolarji),
				'one' => q(namibijski dolar),
				'other' => q(namibijskih dolarjev),
				'two' => q(namibijska dolarja),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigerijska naira),
				'few' => q(nigerijske naire),
				'one' => q(nigerijska naira),
				'other' => q(nigerijskih nair),
				'two' => q(nigerijski nairi),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nikaraška kordova),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaragovska kordova),
				'few' => q(nikaragovske kordove),
				'one' => q(nikaragovska kordova),
				'other' => q(nikaragovskih kordov),
				'two' => q(nikaragovski kordovi),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nizozemski gulden),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norveška krona),
				'few' => q(norveške krone),
				'one' => q(norveška krona),
				'other' => q(norveških kron),
				'two' => q(norveški kroni),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalska rupija),
				'few' => q(nepalske rupije),
				'one' => q(nepalska rupija),
				'other' => q(nepalskih rupij),
				'two' => q(nepalski rupiji),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(novozelandski dolar),
				'few' => q(novozelandski dolarji),
				'one' => q(novozelandski dolar),
				'other' => q(novozelandskih dolarjev),
				'two' => q(novozelandska dolarja),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanski rial),
				'few' => q(omanski riali),
				'one' => q(omanski rial),
				'other' => q(omanskih rialov),
				'two' => q(omanska riala),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamska balboa),
				'few' => q(panamske balboe),
				'one' => q(panamska balboa),
				'other' => q(panamskih balbov),
				'two' => q(panamski balboi),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(perujski inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(perujski sol),
				'few' => q(perujski soli),
				'one' => q(perujski sol),
				'other' => q(perujskih solov),
				'two' => q(perujska sola),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(perujski sol \(1863–1965\)),
				'few' => q(perujski soli \(1863–1965\)),
				'one' => q(perujski sol \(1863–1965\)),
				'other' => q(perujskih solov \(1863–1965\)),
				'two' => q(perujska sola \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina Papue Nove Gvineje),
				'few' => q(kine Papue Nove Gvineje),
				'one' => q(kina Papue Nove Gvineje),
				'other' => q(kin Papue Nove Gvineje),
				'two' => q(kini Papue Nove Gvineje),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filipinski peso),
				'few' => q(filipinski pesi),
				'one' => q(filipinski peso),
				'other' => q(filipinskih pesov),
				'two' => q(filipinska pesa),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskih rupij),
				'two' => q(pakistanski rupiji),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(poljski zlot),
				'few' => q(poljski zloti),
				'one' => q(poljski zlot),
				'other' => q(poljskih zlotov),
				'two' => q(poljska zlota),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(stari poljski zlot \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugalski eskudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paragvajski gvarani),
				'few' => q(paragvajski gvarani),
				'one' => q(paragvajski gvarani),
				'other' => q(paragvajskih gvaranijev),
				'two' => q(paragvajska gvaranija),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarski rial),
				'few' => q(katarski riali),
				'one' => q(katarski rial),
				'other' => q(katarskih rialov),
				'two' => q(katarska riala),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rodezijski dolar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(stari romunski leu),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(romunski lev),
				'few' => q(romunski levi),
				'one' => q(romunski lev),
				'other' => q(romunskih levov),
				'two' => q(romunska leva),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(srbski dinar),
				'few' => q(srbski dinarji),
				'one' => q(srbski dinar),
				'other' => q(srbskih dinarjev),
				'two' => q(srbska dinarja),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruski rubelj),
				'few' => q(ruski rublji),
				'one' => q(ruski rubelj),
				'other' => q(ruskih rubljev),
				'two' => q(ruska rublja),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(ruski rubelj \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandski frank),
				'few' => q(ruandski franki),
				'one' => q(ruandski frank),
				'other' => q(ruandskih frankov),
				'two' => q(ruandska franka),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudski rial),
				'few' => q(saudski riali),
				'one' => q(saudski rial),
				'other' => q(saudskih rialov),
				'two' => q(saudska riala),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(solomonski dolar),
				'few' => q(solomonski dolarji),
				'one' => q(solomonski dolar),
				'other' => q(solomonskih dolarjev),
				'two' => q(solomonska dolarja),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(sejšelska rupija),
				'few' => q(sejšelske rupije),
				'one' => q(sejšelska rupija),
				'other' => q(sejšelskih rupij),
				'two' => q(sejšelski rupiji),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(stari sudanski dinar),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanski funt),
				'few' => q(sudanski funti),
				'one' => q(sudanski funt),
				'other' => q(sudanskih funtov),
				'two' => q(sudanska funta),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(stari sudanski funt),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(švedska krona),
				'few' => q(švedske krone),
				'one' => q(švedska krona),
				'other' => q(švedskih kron),
				'two' => q(švedski kroni),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurski dolarji),
				'one' => q(singapurski dolar),
				'other' => q(singapurskih dolarjev),
				'two' => q(singapurska dolarja),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(funt Sv. Helene),
				'few' => q(funti Sv. Helene),
				'one' => q(funt Sv. Helene),
				'other' => q(funtov Sv. Helene),
				'two' => q(funta Sv. Helene),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovenski tolar),
				'few' => q(slovenski tolarji),
				'one' => q(slovenski tolar),
				'other' => q(slovenskih tolarjev),
				'two' => q(slovenska tolarja),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovaška krona),
				'few' => q(slovaške krone),
				'one' => q(slovaška krona),
				'other' => q(slovaških kron),
				'two' => q(slovaški kroni),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierraleonski leone),
				'few' => q(sierraleonski leoni),
				'one' => q(sierraleonski leone),
				'other' => q(sierraleonskih leonov),
				'two' => q(sierraleonska leona),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonski leone \(1964—2022\)),
				'few' => q(sierraleonski leoni \(1964—2022\)),
				'one' => q(sierraleonski leone \(1964—2022\)),
				'other' => q(sierraleonskih leonov \(1964—2022\)),
				'two' => q(sierraleonska leona \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somalski šiling),
				'few' => q(somalski šilingi),
				'one' => q(somalski šiling),
				'other' => q(somalskih šilingov),
				'two' => q(somalska šilinga),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamski dolar),
				'few' => q(surinamski dolarji),
				'one' => q(surinamski dolar),
				'other' => q(surinamskih dolarjev),
				'two' => q(surinamska dolarja),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamski gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(južnosudanski funt),
				'few' => q(južnosudanski funti),
				'one' => q(južnosudanski funt),
				'other' => q(južnosudanskih funtov),
				'two' => q(južnosudanska funta),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(saotomejska dobra \(1977–2017\)),
				'few' => q(saotomejske dobre \(1977–2017\)),
				'one' => q(saotomejska dobra \(1977–2017\)),
				'other' => q(saotomejskih dober \(1977–2017\)),
				'two' => q(saotomejski dobri \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra Svetega Tomaža in Princa),
				'few' => q(dobre Svetega Tomaža in Princa),
				'one' => q(dobra Svetega Tomaža in Princa),
				'other' => q(dober Svetega Tomaža in Princa),
				'two' => q(dobri Svetega Tomaža in Princa),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovjetski rubelj),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadorski kolon),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sirijski funt),
				'few' => q(sirijski funti),
				'one' => q(sirijski funt),
				'other' => q(sirijskih funtov),
				'two' => q(sirijska funta),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(esvatinski lilangeni),
				'few' => q(esvatinski lilangeni),
				'one' => q(esvatinski lilangeni),
				'other' => q(esvatinskih lilangenijev),
				'two' => q(esvatinska lilangenija),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(tajski baht),
				'few' => q(tajski bahti),
				'one' => q(tajski baht),
				'other' => q(tajskih bahtov),
				'two' => q(tajska bahta),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadžikistanski rubelj),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadžikistanski somoni),
				'few' => q(tadžikistanski somoni),
				'one' => q(tadžikistanski somoni),
				'other' => q(tadžikistanskih somonov),
				'two' => q(tadžikistanska somona),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenski manat),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenistanski manat),
				'few' => q(turkmenistanski manati),
				'one' => q(turkmenistanski manat),
				'other' => q(turkmenistanskih manatov),
				'two' => q(turkmenistanska manata),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunizijski dinar),
				'few' => q(tunizijski dinarji),
				'one' => q(tunizijski dinar),
				'other' => q(tunizijskih dinarjev),
				'two' => q(tunizijska dinarja),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongovska paanga),
				'few' => q(tongovske paange),
				'one' => q(tongovska paanga),
				'other' => q(tongovskih paang),
				'two' => q(tongovski paangi),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timorski eskudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(stara turška lira),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turška lira),
				'few' => q(turške lire),
				'one' => q(turška lira),
				'other' => q(turških lir),
				'two' => q(turški liri),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dolar Trinidada in Tobaga),
				'few' => q(dolarji Trinidada in Tobaga),
				'one' => q(dolar Trinidada in Tobaga),
				'other' => q(dolarjev Trinidada in Tobaga),
				'two' => q(dolarja Trinidada in Tobaga),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(novi tajvanski dolar),
				'few' => q(novi tajvanski dolarji),
				'one' => q(novi tajvanski dolar),
				'other' => q(novih tajvanskih dolarjev),
				'two' => q(nova tajvanska dolarja),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanijski šiling),
				'few' => q(tanzanijski šilingi),
				'one' => q(tanzanijski šiling),
				'other' => q(tanzanijskih šilingov),
				'two' => q(tanzanijska šilinga),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrajinska grivna),
				'few' => q(ukrajinske grivne),
				'one' => q(ukrajinska grivna),
				'other' => q(ukrajinskih grivn),
				'two' => q(ukrajinski grivni),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrajinski karbovanci),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(stari ugandski šiling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandski šiling),
				'few' => q(ugandski šilingi),
				'one' => q(ugandski šiling),
				'other' => q(ugandskih šilingov),
				'two' => q(ugandska šilinga),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ameriški dolar),
				'few' => q(ameriški dolarji),
				'one' => q(ameriški dolar),
				'other' => q(ameriških dolarjev),
				'two' => q(ameriška dolarja),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(ameriški dolar, naslednji dan),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(ameriški dolar, isti dan),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(stari urugvajski peso \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(urugvajski peso),
				'few' => q(urugvajski pesi),
				'one' => q(urugvajski peso),
				'other' => q(urugvajskih pesov),
				'two' => q(urugvajska pesa),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbeški sum),
				'few' => q(uzbeški sumi),
				'one' => q(uzbeški sum),
				'other' => q(uzbeških sumov),
				'two' => q(uzbeška suma),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelski bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelski bolivar \(2008–2018\)),
				'few' => q(venezuelski bolivarji \(2008–2018\)),
				'one' => q(venezuelski bolivar \(2008–2018\)),
				'other' => q(venezuelskih bolivarjev \(2008–2018\)),
				'two' => q(venezuelska bolivarja \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelski bolivar),
				'few' => q(venezuelski bolivarji),
				'one' => q(venezuelski bolivar),
				'other' => q(venezuelskih bolivarjev),
				'two' => q(venezuelska bolivarja),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vientnamski dong),
				'few' => q(vietnamski dongi),
				'one' => q(vientnamski dong),
				'other' => q(vietnamskih dongov),
				'two' => q(vietnamska donga),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatujski vatu),
				'few' => q(vanuatujski vati),
				'one' => q(vanuatujski vatu),
				'other' => q(vanuatujskih vatujev),
				'two' => q(vanuatujska vatuja),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoanska tala),
				'few' => q(samoanske tale),
				'one' => q(samoanska tala),
				'other' => q(samoanskih tal),
				'two' => q(samoanski tali),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(srednjeafriški frank CFA),
				'few' => q(srednjeafriški franki CFA),
				'one' => q(srednjeafriški frank CFA),
				'other' => q(srednjeafriških frankov CFA),
				'two' => q(srednjeafriška franka CFA),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(srebro),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(zlato),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(evropska sestavljena enota),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(evropska monetarna enota),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(evropska obračunska enota \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(evropska obračunska enota \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(vzhodnokaribski dolar),
				'few' => q(vzhodnokaribski dolarji),
				'one' => q(vzhodnokaribski dolar),
				'other' => q(vzhodnokaribskih dolarjev),
				'two' => q(vzhodnokaribska dolarja),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(posebne pravice črpanja),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(evropska denarna enota),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(zlati frank),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(frank UIC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(zahodnoafriški frank CFA),
				'few' => q(zahodnoafriški franki CFA),
				'one' => q(zahodnoafriški frank CFA),
				'other' => q(zahodnoafriških frankov CFA),
				'two' => q(zahodnoafriška franka CFA),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladij),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(frank CFP),
				'few' => q(franki CFP),
				'one' => q(frank CFP),
				'other' => q(frankov CFP),
				'two' => q(franka CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(koda za potrebe testiranja),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(neznana valuta),
				'few' => q(\(neznana valuta\)),
				'one' => q(\(neznana enota valute\)),
				'other' => q(\(neznana valuta\)),
				'two' => q(\(neznana valuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenski dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenski rial),
				'few' => q(jemenski riali),
				'one' => q(jemenski rial),
				'other' => q(jemenskih rialov),
				'two' => q(jemenska riala),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(stari jugoslovanski dinar),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(novi jugoslovanski dinar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslovanski konvertibilni dinar),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(južnoafriški finančni rand),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(južnoafriški rand),
				'few' => q(južnoafriški randi),
				'one' => q(južnoafriški rand),
				'other' => q(južnoafriških randov),
				'two' => q(južnoafriška randa),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambijska kvača \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambijska kvača),
				'few' => q(zambijske kvače),
				'one' => q(zambijska kvača),
				'other' => q(zambijskih kvač),
				'two' => q(zambijski kvači),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairski novi zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairski zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabvejski dolar),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(zimbabvejski dolar \(2009\)),
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
							'jan.',
							'feb.',
							'mar.',
							'apr.',
							'maj',
							'jun.',
							'jul.',
							'avg.',
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
							'marec',
							'april',
							'maj',
							'junij',
							'julij',
							'avgust',
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
							'j',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
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
						mon => 'pon.',
						tue => 'tor.',
						wed => 'sre.',
						thu => 'čet.',
						fri => 'pet.',
						sat => 'sob.',
						sun => 'ned.'
					},
					wide => {
						mon => 'ponedeljek',
						tue => 'torek',
						wed => 'sreda',
						thu => 'četrtek',
						fri => 'petek',
						sat => 'sobota',
						sun => 'nedelja'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'p',
						tue => 't',
						wed => 's',
						thu => 'č',
						fri => 'p',
						sat => 's',
						sun => 'n'
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
					abbreviated => {0 => '1. čet.',
						1 => '2. čet.',
						2 => '3. čet.',
						3 => '4. čet.'
					},
					wide => {0 => '1. četrtletje',
						1 => '2. četrtletje',
						2 => '3. četrtletje',
						3 => '4. četrtletje'
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
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
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
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
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
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
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
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
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
					'afternoon1' => q{pop.},
					'am' => q{dop.},
					'evening1' => q{zveč.},
					'midnight' => q{opoln.},
					'morning1' => q{zjut.},
					'morning2' => q{dop.},
					'night1' => q{ponoči},
					'noon' => q{opold.},
					'pm' => q{pop.},
				},
				'narrow' => {
					'afternoon1' => q{p},
					'am' => q{d},
					'evening1' => q{zv},
					'midnight' => q{24.00},
					'morning1' => q{zj},
					'morning2' => q{d},
					'night1' => q{po},
					'noon' => q{12.00},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{popoldan},
					'evening1' => q{zvečer},
					'midnight' => q{opolnoči},
					'morning1' => q{zjutraj},
					'morning2' => q{dopoldan},
					'night1' => q{ponoči},
					'noon' => q{opoldne},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pop.},
					'evening1' => q{zveč.},
					'midnight' => q{poln.},
					'morning1' => q{jut.},
					'morning2' => q{dop.},
					'night1' => q{noč},
					'noon' => q{pold.},
				},
				'narrow' => {
					'afternoon1' => q{p},
					'am' => q{d},
					'evening1' => q{v},
					'midnight' => q{24.00},
					'morning1' => q{j},
					'morning2' => q{d},
					'night1' => q{n},
					'noon' => q{12.00},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{popoldne},
					'am' => q{dopoldne},
					'evening1' => q{večer},
					'midnight' => q{polnoč},
					'morning1' => q{jutro},
					'morning2' => q{dopoldne},
					'night1' => q{noč},
					'noon' => q{poldne},
					'pm' => q{popoldne},
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
				'0' => 'bud. kol.'
			},
			narrow => {
				'0' => 'BK'
			},
			wide => {
				'0' => 'budistični koledar'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'pr. Kr.',
				'1' => 'po Kr.'
			},
			wide => {
				'0' => 'pred Kristusom',
				'1' => 'po Kristusu'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'pred RK',
				'1' => 'Minguo koledar'
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
			'full' => q{EEEE, dd. MMMM y G},
			'long' => q{dd. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d. MM. yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{d. M. yy},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyM => q{M/y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d. M. y GGGGG},
			MEd => q{E, d. M.},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, d. M. y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d. M. y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyM => q{MMM y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d. M. y GGGGG},
			H => q{HH'h'},
			MEd => q{E, d. M.},
			MMMEd => q{E, d. MMM},
			MMMMW => q{MMMM: W. 'teden'},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E, d. M. y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d. M. y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'teden' 'leta' Y},
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
				B => q{h:mm B–h:mm B},
			},
			Gy => {
				G => q{y G–y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M y GGGGG–M y GGGGG},
				M => q{M y–M y GGGGG},
				y => q{M y–M y GGGGG},
			},
			GyMEd => {
				G => q{E, d. M y GGGGG–E, d. M y GGGGG},
				M => q{E, d. M y–E, d. M y GGGGG},
				d => q{E, d. M y–E, d. M y GGGGG},
				y => q{E, d. M y–E, d. M y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G–E, d. MMM y G},
				M => q{E, d. MMM–E, d. MMM y G},
				d => q{E, d. MMM–E, d. MMM y G},
				y => q{E, d. MMM y–E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G–d. MMM y G},
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			GyMd => {
				G => q{d. M y GGGGG–d. M y GGGGG},
				M => q{d. M y–d. M y GGGGG},
				d => q{d. M y–d. M y GGGGG},
				y => q{d. M y–d. M y GGGGG},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d. M.–E, d. M.},
				d => q{E, d.–E, d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM–E, d. MMM},
				d => q{E, d.–E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d. M.–d. M.},
				d => q{d.–d. M.},
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
				y => q{y–y},
			},
			yM => {
				M => q{M.–M. y},
				y => q{M. y–M. y},
			},
			yMEd => {
				M => q{E, d. M.–E, d. M. y},
				d => q{E, d.–E, d. M. y},
				y => q{E, d. M. y–E, d. M. y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y–MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM–E, d. MMM y},
				d => q{E, d. MMM–E, d. MMM y},
				y => q{E, d. MMM y–E, d. MMM y},
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
				M => q{d. M.–d. M. y},
				d => q{d. M. y–d. M. y},
				y => q{d. M. y–d. M. y},
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
				G => q{MM. y GGGGG–MM. y GGGGG},
				M => q{MM. y–MM. y GGGGG},
				y => q{MM. y–MM. y GGGGG},
			},
			GyMEd => {
				G => q{E, d. MM. y GGGGG–E, d. MM. y GGGGG},
				M => q{E, d. MM. y–E, d. MM. y GGGGG},
				d => q{E, d. MM. y–E, d. MM. y GGGGG},
				y => q{E, d. MM. y–E, d. MM. y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G–E, d. MMM y G},
				M => q{E, d. MMM–E, d. MMM y G},
				d => q{E, d. MMM–E, d. MMM y G},
				y => q{E, d. MMM y–E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G–d. MMM y G},
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			GyMd => {
				G => q{d. MM. y GGGGG–d. MM. y GGGGG},
				M => q{d. MM. y–d. MM. y GGGGG},
				d => q{d. MM. y–d. MM. y GGGGG},
				y => q{d. MM. y–d. MM. y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d. M.–E, d. M.},
				d => q{E, d.–E, d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM–E, d. MMM},
				d => q{E, d.–E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d. M.–d. M.},
				d => q{d.–d. M.},
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
			yM => {
				M => q{M.–M. y},
				y => q{M. y–M. y},
			},
			yMEd => {
				M => q{E, d. M.–E, d. M. y},
				d => q{E, d.–E, d. M. y},
				y => q{E, d. M. y–E, d. M. y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y–MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM–E, d. MMM y},
				d => q{E, d. MMM–E, d. MMM y},
				y => q{E, d. MMM y–E, d. MMM y},
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
				M => q{d. M.–d. M. y},
				d => q{d. M. y–d. M. y},
				y => q{d. M. y–d. M. y},
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
		gmtFormat => q(GMT {0}),
		regionFormat => q({0} čas),
		regionFormat => q({0} poletni čas),
		regionFormat => q({0} standardni čas),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistanski čas#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidžan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžir#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartum#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinšasa#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaši#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadišu#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Centralnoafriški čas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Vzhodnoafriški čas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Južnoafriški čas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Zahodnoafriški poletni čas#,
				'generic' => q#Zahodnoafriški čas#,
				'standard' => q#Zahodnoafriški standardni čas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aljaški poletni čas#,
				'generic' => q#Aljaški čas#,
				'standard' => q#Aljaški standardni čas#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonski poletni čas#,
				'generic' => q#Amazonski čas#,
				'standard' => q#Amazonski standardni čas#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Angvila#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajman#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gvajana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de Mexico#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Severna Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Severna Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Severna Dakota#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoriko#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sv. Bartolomej#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sv. Krištof#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sv. Lucija#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sv. Tomaž#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sv. Vincencij#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Centralni poletni čas#,
				'generic' => q#Centralni čas#,
				'standard' => q#Centralni standardni čas#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Vzhodni poletni čas#,
				'generic' => q#Vzhodni čas#,
				'standard' => q#Vzhodni standardni čas#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Gorski poletni čas#,
				'generic' => q#Gorski čas#,
				'standard' => q#Gorski standardni čas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacifiški poletni čas#,
				'generic' => q#Pacifiški čas#,
				'standard' => q#Pacifiški standardni čas#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadirski poletni čas#,
				'generic' => q#Anadirski čas#,
				'standard' => q#Anadirski standardni čas#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Poletni čas: Apia#,
				'generic' => q#Čas: Apia#,
				'standard' => q#Standardni čas: Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabski poletni čas#,
				'generic' => q#Arabski čas#,
				'standard' => q#Arabski standardni čas#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinski poletni čas#,
				'generic' => q#Argentinski čas#,
				'standard' => q#Argentinski standardni čas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Argentinski zahodni poletni čas#,
				'generic' => q#Argentinski zahodni čas#,
				'standard' => q#Argentinski zahodni standardni čas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenski poletni čas#,
				'generic' => q#Armenski čas#,
				'standard' => q#Armenski standardni čas#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
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
			exemplarCity => q#Ašhabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrajn#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunej#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damask#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Džakarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karači#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muškat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikozija#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizlorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hošiminh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šanghaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timpu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantski poletni čas#,
				'generic' => q#Atlantski čas#,
				'standard' => q#Atlantski standardni čas#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azori#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudi#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarski otoki#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Zelenortski otoki#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ferski otoki#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Južna Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sv. Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Avstralski centralni poletni čas#,
				'generic' => q#Avstralski centralni čas#,
				'standard' => q#Avstralski centralni standardni čas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Avstralski centralni zahodni poletni čas#,
				'generic' => q#Avstralski centralni zahodni čas#,
				'standard' => q#Avstralski centralni zahodni standardni čas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Avstralski vzhodni poletni čas#,
				'generic' => q#Avstralski vzhodni čas#,
				'standard' => q#Avstralski vzhodni standardni čas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Avstralski zahodni poletni čas#,
				'generic' => q#Avstralski zahodni čas#,
				'standard' => q#Avstralski zahodni standardni čas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbajdžanski poletni čas#,
				'generic' => q#Azerbajdžanski čas#,
				'standard' => q#Azerbajdžanski standardni čas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorski poletni čas#,
				'generic' => q#Azorski čas#,
				'standard' => q#Azorski standardni čas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeški poletni čas#,
				'generic' => q#Bangladeški čas#,
				'standard' => q#Bangladeški standardni čas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butanski čas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivijski čas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilski poletni čas#,
				'generic' => q#Brasilski čas#,
				'standard' => q#Brasilski standardni čas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunejski čas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapverdski poletni čas#,
				'generic' => q#Kapverdski čas#,
				'standard' => q#Kapverdski standardni čas#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Čamorski standardni čas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Čatamski poletni čas#,
				'generic' => q#Čatamski čas#,
				'standard' => q#Čatamski standardni čas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Čilski poletni čas#,
				'generic' => q#Čilski čas#,
				'standard' => q#Čilski standardni čas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kitajski poletni čas#,
				'generic' => q#Kitajski čas#,
				'standard' => q#Kitajski standardni čas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Božičnootoški čas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Čas: Kokosovi otoki#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbijski poletni čas#,
				'generic' => q#Kolumbijski čas#,
				'standard' => q#Kolumbijski standardni čas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookovootoški srednjepoletni čas#,
				'generic' => q#Cookovootoški čas#,
				'standard' => q#Cookovootoški standardni čas#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubanski poletni čas#,
				'generic' => q#Kubanski čas#,
				'standard' => q#Kubanski standardni čas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Čas: Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Čas: Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Vzhodnotimorski čas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Poletni čas: Velikonočni otok#,
				'generic' => q#Čas: Velikonočni otok#,
				'standard' => q#Standardni čas: Velikonočni otok#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvadorski čas#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#univerzalni koordinirani čas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#neznano mesto#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruselj#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarešta#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budimpešta#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišinjev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Köbenhavn#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irski standardni čas#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Otok Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lizbona#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britanski poletni čas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariz#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Dunaj#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilna#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Srednjeevropski poletni čas#,
				'generic' => q#Srednjeevropski čas#,
				'standard' => q#Srednjeevropski standardni čas#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Vzhodnoevropski poletni čas#,
				'generic' => q#Vzhodnoevropski čas#,
				'standard' => q#Vzhodnoevropski standardni čas#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Dodatni vzhodnoevropski čas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Zahodnoevropski poletni čas#,
				'generic' => q#Zahodnoevropski čas#,
				'standard' => q#Zahodnoevropski standardni čas#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Poletni čas: Falklandsko otočje#,
				'generic' => q#Čas: Falklandsko otočje#,
				'standard' => q#Standardni čas: Falklandsko otočje#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidžijski poletni čas#,
				'generic' => q#Fidžijski čas#,
				'standard' => q#Fidžijski standardni čas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Čas: Francoska Gvajana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Francoski južni in antarktični čas#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwiški srednji čas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapaški čas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambierski čas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzijski poletni čas#,
				'generic' => q#Gruzijski čas#,
				'standard' => q#Gruzijski standardni čas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Čas: Gilbertovi otoki#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Vzhodnogrenlandski poletni čas#,
				'generic' => q#Vzhodnogrenlandski čas#,
				'standard' => q#Vzhodnogrenlandski standardni čas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Zahodnogrenlandski poletni čas#,
				'generic' => q#Zahodnogrenlandski čas#,
				'standard' => q#Zahodnogrenlandski standardni čas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Zalivski standardni čas#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gvajanski čas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havajski aleutski poletni čas#,
				'generic' => q#Havajski aleutski čas#,
				'standard' => q#Havajski aleutski standardni čas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkonški poletni čas#,
				'generic' => q#Hongkonški čas#,
				'standard' => q#Hongkonški standardni čas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovdski poletni čas#,
				'generic' => q#Hovdski čas#,
				'standard' => q#Hovdski standardni čas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indijski standardni čas#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Božični otok#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosovi otoki#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komori#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivi#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indijskooceanski čas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokitajski čas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Indonezijski osrednji čas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Indonezijski vzhodni čas#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Indonezijski zahodni čas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iranski poletni čas#,
				'generic' => q#Iranski čas#,
				'standard' => q#Iranski standardni čas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutski poletni čas#,
				'generic' => q#Irkutski čas#,
				'standard' => q#Irkutski standardni čas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izraelski poletni čas#,
				'generic' => q#Izraelski čas#,
				'standard' => q#Izraelski standardni čas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japonski poletni čas#,
				'generic' => q#Japonski čas#,
				'standard' => q#Japonski standardni čas#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamčatski poletni čas#,
				'generic' => q#Petropavlovsk-Kamčatski čas#,
				'standard' => q#Petropavlovsk-Kamčatski standardni čas#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kazahstanski čas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Vzhodni kazahstanski čas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Zahodni kazahstanski čas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejski poletni čas#,
				'generic' => q#Korejski čas#,
				'standard' => q#Korejski standardni čas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrajški čas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarski poletni čas#,
				'generic' => q#Krasnojarski čas#,
				'standard' => q#Krasnojarski standardni čas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgizistanski čas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Čas: Ekvatorski otoki#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Poletni čas otoka Lord Howe#,
				'generic' => q#Čas otoka Lord Howe#,
				'standard' => q#Standardni čas otoka Lord Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadanski poletni čas#,
				'generic' => q#Magadanski čas#,
				'standard' => q#Magadanski standardni čas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malezijski čas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivski čas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Čas: Markizni otoki#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Čas: Marshallovi otoki#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauricijski poletni čas#,
				'generic' => q#Mauricijski čas#,
				'standard' => q#Mauricijski standardni čas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsonski čas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mehiški pacifiški poletni čas#,
				'generic' => q#Mehiški pacifiški čas#,
				'standard' => q#Mehiški pacifiški standardni čas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulanbatorski poletni čas#,
				'generic' => q#Ulanbatorski čas#,
				'standard' => q#Ulanbatorski standardni čas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskovski poletni čas#,
				'generic' => q#Moskovski čas#,
				'standard' => q#Moskovski standardni čas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mjanmarski čas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Naurujski čas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalski čas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Novokaledonijski poletni čas#,
				'generic' => q#Novokaledonijski čas#,
				'standard' => q#Novokaledonijski standardni čas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Novozelandski poletni čas#,
				'generic' => q#Novozelandski čas#,
				'standard' => q#Novozelandski standardni čas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Novofundlandski poletni čas#,
				'generic' => q#Novofundlandski čas#,
				'standard' => q#Novofundlandski standardni čas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuejski čas#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Poletni čas: Norfolški otoki#,
				'generic' => q#Čas: Norfolški otoki#,
				'standard' => q#Standardni čas: Norfolški otoki#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronški poletni čas#,
				'generic' => q#Fernando de Noronški čas#,
				'standard' => q#Fernando de Noronški standardni čas#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirski poletni čas#,
				'generic' => q#Novosibirski čas#,
				'standard' => q#Novosibirski standardni čas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omski poletni čas#,
				'generic' => q#Omski čas#,
				'standard' => q#Omski standardni čas#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Velikonočni otok#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistanski poletni čas#,
				'generic' => q#Pakistanski čas#,
				'standard' => q#Pakistanski standardni čas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palavski čas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papuanski čas#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragvajski poletni čas#,
				'generic' => q#Paragvajski čas#,
				'standard' => q#Paragvajski standardni čas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Perujski poletni čas#,
				'generic' => q#Perujski čas#,
				'standard' => q#Perujski standardni čas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipinski poletni čas#,
				'generic' => q#Filipinski čas#,
				'standard' => q#Filipinski standardni čas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Čas: Otočje Feniks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Poletni čas: Saint Pierre in Miquelon#,
				'generic' => q#Čas: Saint Pierre in Miquelon#,
				'standard' => q#Standardni čas: Saint Pierre in Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairnski čas#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapski čas#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjongjanški čas#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunionski čas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotherski čas#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalinski poletni čas#,
				'generic' => q#Sahalinski čas#,
				'standard' => q#Sahalinski standardni čas#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samarski poletni čas#,
				'generic' => q#Samarski čas#,
				'standard' => q#Samarski standardni čas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoanski poletni čas#,
				'generic' => q#Samoanski čas#,
				'standard' => q#Samoanski standardni čas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Sejšelski čas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapurski standardni čas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonovootoški čas#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Južnogeorgijski čas#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamski čas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Čas: Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitijski čas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tajpejski poletni čas#,
				'generic' => q#Tajpejski čas#,
				'standard' => q#Tajpejski standardni čas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistanski čas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelavski čas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongovski poletni čas#,
				'generic' => q#Tongovski čas#,
				'standard' => q#Tongovski standardni čas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Čas: Otok Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistanski poletni čas#,
				'generic' => q#Turkmenistanski čas#,
				'standard' => q#Turkmenistanski standardni čas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalujski čas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugvajski poletni čas#,
				'generic' => q#Urugvajski čas#,
				'standard' => q#Urugvajski standardni čas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistanski poletni čas#,
				'generic' => q#Uzbekistanski čas#,
				'standard' => q#Uzbekistanski standardni čas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatujski poletni čas#,
				'generic' => q#Vanuatujski čas#,
				'standard' => q#Vanuatujski standardni čas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelski čas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostoški poletni čas#,
				'generic' => q#Vladivostoški čas#,
				'standard' => q#Vladivostoški standardni čas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograjski poletni čas#,
				'generic' => q#Volgograjski čas#,
				'standard' => q#Volgograjski standardni čas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostoški čas#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Čas: Otok Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Čas: Wallis in Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutski poletni čas#,
				'generic' => q#Jakutski čas#,
				'standard' => q#Jakutski standardni čas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburški poletni čas#,
				'generic' => q#Jekaterinburški čas#,
				'standard' => q#Jekaterinburški standardni čas#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Jukonski čas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
