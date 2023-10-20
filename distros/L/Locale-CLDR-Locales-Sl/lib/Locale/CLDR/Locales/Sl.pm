=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sl - Package for language Slovenian

=cut

package Locale::CLDR::Locales::Sl;
# This file auto generated from Data\common\main\sl.xml
#	on Fri 13 Oct  9:38:26 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
 				'anp' => 'angikaščina',
 				'ar' => 'arabščina',
 				'ar_001' => 'sodobna standardna arabščina',
 				'arc' => 'aramejščina',
 				'arn' => 'mapudungunščina',
 				'arp' => 'arapaščina',
 				'arw' => 'aravaščina',
 				'as' => 'asamščina',
 				'asa' => 'asujščina',
 				'ast' => 'asturijščina',
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
 				'bgn' => 'zahodnobalučijščina',
 				'bho' => 'bodžpuri',
 				'bi' => 'bislamščina',
 				'bik' => 'bikolski jezik',
 				'bin' => 'edo',
 				'bla' => 'siksika',
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
 				'ckb' => 'soranska kurdščina',
 				'co' => 'korziščina',
 				'cop' => 'koptščina',
 				'cr' => 'krijščina',
 				'crh' => 'krimska tatarščina',
 				'crs' => 'sejšelska francoska kreolščina',
 				'cs' => 'češčina',
 				'csb' => 'kašubščina',
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
 				'en_GB' => 'angleščina (VB)',
 				'en_GB@alt=short' => 'angleščina (ZK)',
 				'en_US' => 'angleščina (ZDA)',
 				'en_US@alt=short' => 'angleščina (ZDA)',
 				'enm' => 'srednja angleščina',
 				'eo' => 'esperanto',
 				'es' => 'španščina',
 				'es_ES' => 'evropska španščina',
 				'es_MX' => 'mehiška španščina',
 				'et' => 'estonščina',
 				'eu' => 'baskovščina',
 				'ewo' => 'evondovščina',
 				'fa' => 'perzijščina',
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
 				'he' => 'hebrejščina',
 				'hi' => 'hindujščina',
 				'hil' => 'hiligajnonščina',
 				'hit' => 'hetitščina',
 				'hmn' => 'hmonščina',
 				'ho' => 'hiri motu',
 				'hr' => 'hrvaščina',
 				'hsb' => 'gornja lužiška srbščina',
 				'ht' => 'haitijska kreolščina',
 				'hu' => 'madžarščina',
 				'hup' => 'hupa',
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
 				'lkt' => 'lakotščina',
 				'ln' => 'lingala',
 				'lo' => 'laoščina',
 				'lol' => 'mongo',
 				'lou' => 'louisianska kreolščina',
 				'loz' => 'lozi',
 				'lrc' => 'severna lurijščina',
 				'lt' => 'litovščina',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luisenščina',
 				'lun' => 'lunda',
 				'luo' => 'luo',
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
 				'mg' => 'malagaščina',
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
 				'pl' => 'poljščina',
 				'pon' => 'ponpejščina',
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
 				'rm' => 'retoromanščina',
 				'rn' => 'rundščina',
 				'ro' => 'romunščina',
 				'ro_MD' => 'moldavščina',
 				'rof' => 'rombo',
 				'rom' => 'romščina',
 				'root' => 'rootščina',
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
 				'ta' => 'tamilščina',
 				'te' => 'telugijščina',
 				'tem' => 'temnejščina',
 				'teo' => 'teso',
 				'tet' => 'tetumščina',
 				'tg' => 'tadžiščina',
 				'th' => 'tajščina',
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
 				'tpi' => 'tok pisin',
 				'tr' => 'turščina',
 				'trv' => 'taroko',
 				'ts' => 'congščina',
 				'tsi' => 'tsimščina',
 				'tt' => 'tatarščina',
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
 				'vi' => 'vietnamščina',
 				'vo' => 'volapuk',
 				'vot' => 'votjaščina',
 				'vun' => 'vunjo',
 				'wa' => 'valonščina',
 				'wae' => 'walser',
 				'wal' => 'valamščina',
 				'war' => 'varajščina',
 				'was' => 'vašajščina',
 				'wbp' => 'varlpirščina',
 				'wo' => 'volofščina',
 				'xal' => 'kalmiščina',
 				'xh' => 'koščina',
 				'xog' => 'sogščina',
 				'yao' => 'jaojščina',
 				'yap' => 'japščina',
 				'yav' => 'jangben',
 				'ybb' => 'jembajščina',
 				'yi' => 'jidiš',
 				'yo' => 'jorubščina',
 				'yue' => 'kantonščina',
 				'zap' => 'zapoteščina',
 				'zbl' => 'znakovni jezik Bliss',
 				'zen' => 'zenaščina',
 				'zgh' => 'standardni maroški tamazig',
 				'zh' => 'kitajščina',
 				'zh_Hans' => 'poenostavljena kitajščina',
 				'zh_Hant' => 'tradicionalna kitajščina',
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
			'Arab' => 'arabski',
 			'Arab@alt=variant' => 'perzijskoarabski',
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
 			'Cans' => 'poenotena zlogovna pisava kanadskih staroselcev',
 			'Cham' => 'Cham',
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
 			'Hanb' => 'Han + Bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'kanji',
 			'Hano' => 'hanunski',
 			'Hans' => 'poenostavljena pisava han',
 			'Hans@alt=stand-alone' => 'poenostavljena pisava han',
 			'Hant' => 'tradicionalna pisava han',
 			'Hant@alt=stand-alone' => 'tradicionalna pisava han',
 			'Hebr' => 'hebrejski',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahavhmonska zlogovna pisava',
 			'Hrkt' => 'japonska zlogovnica',
 			'Hung' => 'staroogrski',
 			'Inds' => 'induški',
 			'Ital' => 'staroitalski',
 			'Jamo' => 'Jamo',
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
 			'Mtei' => 'manipurski',
 			'Mymr' => 'mjanmarski',
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
 			'CF' => 'Centralnoafriška republika',
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
 			'HK' => 'Posebno administrativno območje LR Kitajske Hongkong',
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
 			'MK' => 'Makedonija',
 			'MK@alt=variant' => 'Makedonija (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Mjanmar (Burma)',
 			'MN' => 'Mongolija',
 			'MO' => 'Posebno administrativno območje LR Kitajske Macao',
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
 			'SZ' => 'Svazi',
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
 			'x' => 'Private-Use',

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
 				'coptic' => q{Koptski koledar},
 				'dangi' => q{stari korejski koledar},
 				'ethiopic' => q{etiopski koledar},
 				'ethiopic-amete-alem' => q{Etiopsko ametsko alemski koledar},
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
 				'dictionary' => q{Vrstni red razvrščanja v slovarju},
 				'ducet' => q{Privzeto razvrščanje Unicode},
 				'emoji' => q{razvrščanje čustvenčkov},
 				'eor' => q{evropska pravila razvrščanja},
 				'gb2312han' => q{razvrščanje po sistemu poenostavljene kitajščine - GB2312},
 				'phonebook' => q{razvrščanje po abecedi},
 				'phonetic' => q{Fonetično razvrščanje},
 				'pinyin' => q{razvrščanje po sistemu pinjin},
 				'reformed' => q{Reformirano razvrščanje},
 				'search' => q{Splošno iskanje},
 				'searchjl' => q{Iskanje po začetnem soglasniku hangul},
 				'standard' => q{Standardno razvrščanje},
 				'stroke' => q{razvrščanje po zaporedju pisanja pismenk},
 				'traditional' => q{razvrščanje po tradicionalnem sistemu},
 				'unihan' => q{Razvrščanje koren-poteza},
 				'zhuyin' => q{Razvrščanje po pismenkah Zhuyin},
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
 				'cakm' => q{čakma števke},
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
 				'mtei' => q{Meetei Mayek števke},
 				'mymr' => q{mjanmarske števke},
 				'mymrshan' => q{mjanmarske shan števke},
 				'mymrtlng' => q{mjanmarske števke Tai Laing},
 				'native' => q{Domače števke},
 				'nkoo' => q{N’Ko števke},
 				'olck' => q{Ol Chiki števke},
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
 				'vaii' => q{Številke vai},
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
			auxiliary => qr{[á à ă â å ä ā æ ç ć đ é è ĕ ê ë ē í ì ĭ î ï ī ñ ó ò ŏ ô ö ø ō œ q ú ù ŭ û ü ū w x y ÿ]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a b c č d e f g h i j k l m n o p r s š t u v z ž]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- – , ; \: ! ? . … ' " „ ‟ « » ( ) \[ \] \{ \} @ *]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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
					'' => {
						'name' => q(stran neba),
					},
					'acre' => {
						'few' => q({0} akri),
						'name' => q(aker),
						'one' => q({0} aker),
						'other' => q({0} akrov),
						'two' => q({0} akra),
					},
					'acre-foot' => {
						'few' => q({0} aker-čevlji),
						'name' => q(aker-čevelj),
						'one' => q({0} aker-čevelj),
						'other' => q({0} aker-čevljev),
						'two' => q({0} aker-čevlja),
					},
					'ampere' => {
						'few' => q({0} amperi),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} amperov),
						'two' => q({0} ampera),
					},
					'arc-minute' => {
						'few' => q({0} kotne minute),
						'name' => q(kotna minuta),
						'one' => q({0} kotna minuta),
						'other' => q({0} kotnih minut),
						'two' => q({0} kotni minuti),
					},
					'arc-second' => {
						'few' => q({0} kotne sekunde),
						'name' => q(kotna sekunda),
						'one' => q({0} kotna sekunda),
						'other' => q({0} kotnih sekund),
						'two' => q({0} kotni sekundi),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomske enote),
						'name' => q(astronomska enota),
						'one' => q({0} astronomska enota),
						'other' => q({0} astronomskih enot),
						'two' => q({0} astronomski enoti),
					},
					'atmosphere' => {
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfer),
						'two' => q({0} atmosferi),
					},
					'bit' => {
						'few' => q({0} bite),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bitov),
						'two' => q({0} bita),
					},
					'byte' => {
						'few' => q({0} bajti),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
						'two' => q({0} bajta),
					},
					'calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorij),
						'two' => q({0} kaloriji),
					},
					'carat' => {
						'few' => q({0} karati),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karatov),
						'two' => q({0} karata),
					},
					'celsius' => {
						'few' => q({0} stopinje Celzija),
						'name' => q(stopinje Celzija),
						'one' => q({0} stopinja Celzija),
						'other' => q({0} stopinj Celzija),
						'two' => q({0} stopinji Celzija),
					},
					'centiliter' => {
						'few' => q({0} centilitri),
						'name' => q(centilitri),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrov),
						'two' => q({0} centilitra),
					},
					'centimeter' => {
						'few' => q({0} centimetri),
						'name' => q(centimetri),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrov),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetra),
					},
					'century' => {
						'few' => q({0} stoletja),
						'name' => q(stoletja),
						'one' => q({0} stoletje),
						'other' => q({0} stoletij),
						'two' => q({0} stoletji),
					},
					'coordinate' => {
						'east' => q({0} V),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					'cubic-centimeter' => {
						'few' => q({0} kubični centimetri),
						'name' => q(kubični centimeter),
						'one' => q({0} kubični centimeter),
						'other' => q({0} kubičnih centimetrov),
						'per' => q({0} na kubični centimeter),
						'two' => q({0} kubična centimetra),
					},
					'cubic-foot' => {
						'few' => q({0} kubični čevlji),
						'name' => q(kubični čevlji),
						'one' => q({0} kubični čevelj),
						'other' => q({0} kubičnih čevljev),
						'two' => q({0} kubična čevlja),
					},
					'cubic-inch' => {
						'few' => q({0} kubični palci),
						'name' => q(kubični palci),
						'one' => q({0} kubični palec),
						'other' => q({0} kubičnih palcev),
						'two' => q({0} kubična palca),
					},
					'cubic-kilometer' => {
						'few' => q({0} kubični kilometri),
						'name' => q(kubičnih kilometrov),
						'one' => q({0} kubični kilometer),
						'other' => q({0} kubičnih kilometrov),
						'two' => q({0} kubična kilometra),
					},
					'cubic-meter' => {
						'few' => q({0} kubični metri),
						'name' => q(kubičnih metrov),
						'one' => q({0} kubični meter),
						'other' => q({0} kubičnih metrov),
						'per' => q({0} na kubični meter),
						'two' => q({0} kubična metra),
					},
					'cubic-mile' => {
						'few' => q({0} kubične milje),
						'name' => q(kubične milje),
						'one' => q({0} kubična milja),
						'other' => q({0} kubičnih milj),
						'two' => q({0} kubični milji),
					},
					'cubic-yard' => {
						'few' => q({0} kubični jardi),
						'name' => q(kubični jard),
						'one' => q({0} kubični jard),
						'other' => q({0} kubičnih jardov),
						'two' => q({0} kubična jarda),
					},
					'cup' => {
						'few' => q({0} skodelice),
						'name' => q(skodelice),
						'one' => q({0} skodelica),
						'other' => q({0} skodelic),
						'two' => q({0} skodelici),
					},
					'cup-metric' => {
						'few' => q({0} metrične skodelice),
						'name' => q(metrične skodelice),
						'one' => q({0} metrična skodelica),
						'other' => q({0} metričnih skodelic),
						'two' => q({0} metrični skodelici),
					},
					'day' => {
						'few' => q({0} dni),
						'name' => q(dni),
						'one' => q({0} dan),
						'other' => q({0} dni),
						'per' => q({0} na dan),
						'two' => q({0} dneva),
					},
					'deciliter' => {
						'few' => q({0} decilitri),
						'name' => q(decilitri),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrov),
						'two' => q({0} decilitra),
					},
					'decimeter' => {
						'few' => q({0} decimetri),
						'name' => q(decimetri),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrov),
						'two' => q({0} decimetra),
					},
					'degree' => {
						'few' => q({0} stopinje),
						'name' => q(stopinja),
						'one' => q({0} stopinja),
						'other' => q({0} stopinj),
						'two' => q({0} stopinji),
					},
					'fahrenheit' => {
						'few' => q({0} stopinje Farenheita),
						'name' => q(stopinje Farenheita),
						'one' => q({0} stopinja Farenheita),
						'other' => q({0} stopinj Farenheita),
						'two' => q({0} stopinji Farenheita),
					},
					'fathom' => {
						'few' => q({0} fth),
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'two' => q({0} fth),
					},
					'fluid-ounce' => {
						'few' => q({0} tekoče unče),
						'name' => q(tekoče unče),
						'one' => q({0} tekoča unča),
						'other' => q({0} tekočih unč),
						'two' => q({0} tekoči unči),
					},
					'foodcalorie' => {
						'few' => q({0} kalorij),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorij),
						'two' => q({0} kaloriji),
					},
					'foot' => {
						'few' => q({0} čevlji),
						'name' => q(čevlji),
						'one' => q({0} čevelj),
						'other' => q({0} čevljev),
						'per' => q({0} na čevelj),
						'two' => q({0} čevlja),
					},
					'furlong' => {
						'few' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
						'two' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} galon),
						'name' => q(galone),
						'one' => q({0} galona),
						'other' => q({0} galon),
						'per' => q({0} na galono),
						'two' => q({0} galoni),
					},
					'gallon-imperial' => {
						'few' => q({0} imperialne galone),
						'name' => q(imperialna galona),
						'one' => q({0} imperialna galona),
						'other' => q({0} imperialne galone),
						'per' => q({0} na imp. gal),
						'two' => q({0} imperialni galoni),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} gigabiti),
						'name' => q(gigabiti),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitov),
						'two' => q({0} gigabita),
					},
					'gigabyte' => {
						'few' => q({0} gigabajti),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtov),
						'two' => q({0} gigabajta),
					},
					'gigahertz' => {
						'few' => q({0} gigahertzi),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzev),
						'two' => q({0} gigahertza),
					},
					'gigawatt' => {
						'few' => q({0} gigavati),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavatov),
						'two' => q({0} gigavata),
					},
					'gram' => {
						'few' => q({0} grami),
						'name' => q(grami),
						'one' => q({0} gram),
						'other' => q({0} gramov),
						'per' => q({0} na gram),
						'two' => q({0} grama),
					},
					'hectare' => {
						'few' => q({0} hektari),
						'name' => q(hektari),
						'one' => q({0} hektar),
						'other' => q({0} hektarov),
						'two' => q({0} hektara),
					},
					'hectoliter' => {
						'few' => q({0} hektolitri),
						'name' => q(hektolitri),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrov),
						'two' => q({0} hektolitra),
					},
					'hectopascal' => {
						'few' => q({0} hektopaskali),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskalov),
						'two' => q({0} hektopaskala),
					},
					'hertz' => {
						'few' => q({0} hertzi),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertzev),
						'two' => q({0} hertza),
					},
					'horsepower' => {
						'few' => q({0} konjske moči),
						'name' => q(konjska moč),
						'one' => q({0} konjska moč),
						'other' => q({0} konjskih moči),
						'two' => q({0} konjski moči),
					},
					'hour' => {
						'few' => q({0} ure),
						'name' => q(ur),
						'one' => q({0} ura),
						'other' => q({0} ur),
						'per' => q({0} na uro),
						'two' => q({0} uri),
					},
					'inch' => {
						'few' => q({0} palci),
						'name' => q(palec),
						'one' => q({0} palec),
						'other' => q({0} palcev),
						'per' => q({0} na palec),
						'two' => q({0} palca),
					},
					'inch-hg' => {
						'few' => q({0} palci živega srebra),
						'name' => q(palci živega srebra),
						'one' => q({0} palec živega srebra),
						'other' => q({0} palcev živega srebra),
						'two' => q({0} palca živega srebra),
					},
					'joule' => {
						'few' => q({0} jouli),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joulov),
						'two' => q({0} joula),
					},
					'karat' => {
						'few' => q({0} karati),
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karatov),
						'two' => q({0} karata),
					},
					'kelvin' => {
						'few' => q({0} kelvini),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinov),
						'two' => q({0} kelvina),
					},
					'kilobit' => {
						'few' => q({0} kilobiti),
						'name' => q(kilobiti),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitov),
						'two' => q({0} kilobita),
					},
					'kilobyte' => {
						'few' => q({0} kilobajti),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtov),
						'two' => q({0} kilobajta),
					},
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorij),
						'two' => q({0} kilokaloriji),
					},
					'kilogram' => {
						'few' => q({0} kilogrami),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramov),
						'per' => q({0} na kilogram),
						'two' => q({0} kilograma),
					},
					'kilohertz' => {
						'few' => q({0} kilohertzi),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzev),
						'two' => q({0} kilohertza),
					},
					'kilojoule' => {
						'few' => q({0} kilojouli),
						'name' => q(kilojouli),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulov),
						'two' => q({0} kilojoula),
					},
					'kilometer' => {
						'few' => q({0} kilometri),
						'name' => q(kilometri),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrov),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometra),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometri na uro),
						'name' => q(kilometri na uro),
						'one' => q({0} kilometer na uro),
						'other' => q({0} kilometrov na uro),
						'two' => q({0} kilometra na uro),
					},
					'kilowatt' => {
						'few' => q({0} kilovati),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovatov),
						'two' => q({0} kilovata),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilovatne ure),
						'name' => q(kilovatne ure),
						'one' => q({0} kilovatna ura),
						'other' => q({0} kilovatnih ur),
						'two' => q({0} kilovatni uri),
					},
					'knot' => {
						'few' => q({0} vozli),
						'name' => q(vozel),
						'one' => q({0} vozel),
						'other' => q({0} vozlov),
						'two' => q({0} vozla),
					},
					'light-year' => {
						'few' => q({0} svetlobna leta),
						'name' => q(svetlobnih let),
						'one' => q({0} svetlobno leto),
						'other' => q({0} svetlobnih let),
						'two' => q({0} svetlobni leti),
					},
					'liter' => {
						'few' => q({0} litri),
						'name' => q(litri),
						'one' => q({0} liter),
						'other' => q({0} litrov),
						'per' => q({0} na liter),
						'two' => q({0} litra),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} litri na 100 kilometrov),
						'name' => q(L/100km),
						'one' => q({0} liter na 100 kilometrov),
						'other' => q({0} litrov na 100 kilometrov),
						'two' => q({0} litra na 100 kilometrov),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litrov na kilometer),
						'name' => q(litrov na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrov na kilometer),
						'two' => q({0} litra na kilometer),
					},
					'lux' => {
						'few' => q({0} luksi),
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksov),
						'two' => q({0} luksa),
					},
					'megabit' => {
						'few' => q({0} megabiti),
						'name' => q(megabiti),
						'one' => q({0} megabit),
						'other' => q({0} megabitov),
						'two' => q({0} megabita),
					},
					'megabyte' => {
						'few' => q({0} megabajti),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtov),
						'two' => q({0} megabajta),
					},
					'megahertz' => {
						'few' => q({0} megahertzi),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzev),
						'two' => q({0} megahertza),
					},
					'megaliter' => {
						'few' => q({0} megalitri),
						'name' => q(megalitri),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrov),
						'two' => q({0} megalitra),
					},
					'megawatt' => {
						'few' => q({0} megavati),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavatov),
						'two' => q({0} megavata),
					},
					'meter' => {
						'few' => q({0} metri),
						'name' => q(metri),
						'one' => q({0} meter),
						'other' => q({0} metrov),
						'per' => q({0} na meter),
						'two' => q({0} metra),
					},
					'meter-per-second' => {
						'few' => q({0} metri na sekundo),
						'name' => q(metri na sekundo),
						'one' => q({0} meter na sekundo),
						'other' => q({0} metrov na sekundo),
						'two' => q({0} metra na sekundo),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metri na kvadratno sekundo),
						'name' => q(meter na kvadratno sekundo),
						'one' => q({0} meter na kvadratno sekundo),
						'other' => q({0} metrov na kvadratno sekundo),
						'two' => q({0} metra na kvadratno sekundo),
					},
					'metric-ton' => {
						'few' => q({0} metrične tone),
						'name' => q(metrične tone),
						'one' => q({0} metrična tona),
						'other' => q({0} metričnih ton),
						'two' => q({0} metrični toni),
					},
					'microgram' => {
						'few' => q({0} mikrogrami),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramov),
						'two' => q({0} mikrograma),
					},
					'micrometer' => {
						'few' => q({0} mikrometri),
						'name' => q(mikrometri),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrov),
						'two' => q({0} mikrometra),
					},
					'microsecond' => {
						'few' => q({0} mikrosekunde),
						'name' => q(mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekund),
						'two' => q({0} mikrosekundi),
					},
					'mile' => {
						'few' => q({0} milje),
						'name' => q(milje),
						'one' => q({0} milja),
						'other' => q({0} milj),
						'two' => q({0} milji),
					},
					'mile-per-gallon' => {
						'few' => q({0} milj na galono),
						'name' => q(milje na galono),
						'one' => q({0} milja na galono),
						'other' => q({0} milj na galono),
						'two' => q({0} milji na galono),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} milje na imperialno galono),
						'name' => q(milje na imperialno galono),
						'one' => q({0} milja na imperialno galono),
						'other' => q({0} milj na imperialno galono),
						'two' => q({0} milji na imperialno galono),
					},
					'mile-per-hour' => {
						'few' => q({0} milje na uro),
						'name' => q(milje na uro),
						'one' => q({0} milja na uro),
						'other' => q({0} milj na uro),
						'two' => q({0} milji na uro),
					},
					'mile-scandinavian' => {
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavska milja),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milj),
						'two' => q({0} skandinavski milji),
					},
					'milliampere' => {
						'few' => q({0} milliamperi),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliamperov),
						'two' => q({0} miliampera),
					},
					'millibar' => {
						'few' => q({0} milibari),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibarov),
						'two' => q({0} milibara),
					},
					'milligram' => {
						'few' => q({0} miligrami),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligramov),
						'two' => q({0} miligrama),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} miligrami na deciliter),
						'name' => q(miligrami na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramov na deciliter),
						'two' => q({0} miligrama na deciliter),
					},
					'milliliter' => {
						'few' => q({0} mililitri),
						'name' => q(mililitri),
						'one' => q({0} mililiter),
						'other' => q({0} militrov),
						'two' => q({0} mililitra),
					},
					'millimeter' => {
						'few' => q({0} milimetri),
						'name' => q(milimetri),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrov),
						'two' => q({0} milimetra),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetri živega srebra),
						'name' => q(milimetri živega srebra),
						'one' => q({0} milimeter živega srebra),
						'other' => q({0} milimetrov živega srebra),
						'two' => q({0} milimetra živega srebra),
					},
					'millimole-per-liter' => {
						'few' => q({0} milimoli na liter),
						'name' => q(milimol na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolov na liter),
						'two' => q({0} milimola na liter),
					},
					'millisecond' => {
						'few' => q({0} millisekunde),
						'name' => q(milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} millisekund),
						'two' => q({0} millisekundi),
					},
					'milliwatt' => {
						'few' => q({0} milivati),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivatov),
						'two' => q({0} milivata),
					},
					'minute' => {
						'few' => q({0} minute),
						'name' => q(minut),
						'one' => q({0} minuta),
						'other' => q({0} minut),
						'per' => q({0} na minuto),
						'two' => q({0} minuti),
					},
					'month' => {
						'few' => q({0} mesecev),
						'name' => q(mesecev),
						'one' => q({0} mesec),
						'other' => q({0} mesecev),
						'per' => q({0} na mesec),
						'two' => q({0} meseca),
					},
					'nanometer' => {
						'few' => q({0} nanometri),
						'name' => q(nanometri),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrov),
						'two' => q({0} nanometra),
					},
					'nanosecond' => {
						'few' => q({0} nanosekunde),
						'name' => q(nanosekunde),
						'one' => q({0} ns),
						'other' => q({0} nanosekund),
						'two' => q({0} nanosekundi),
					},
					'nautical-mile' => {
						'few' => q({0} navtične milje),
						'name' => q(navtična milja),
						'one' => q({0} navtična milja),
						'other' => q({0} navtičnih milj),
						'two' => q({0} navtični milji),
					},
					'ohm' => {
						'few' => q({0} ohmi),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohmov),
						'two' => q({0} ohma),
					},
					'ounce' => {
						'few' => q({0} unče),
						'name' => q(unče),
						'one' => q({0} unča),
						'other' => q({0} unč),
						'per' => q({0} na unčo),
						'two' => q({0} unči),
					},
					'ounce-troy' => {
						'few' => q({0} trojanske unče),
						'name' => q(trojanske unče),
						'one' => q({0} trojanska unča),
						'other' => q({0} trojanskih unč),
						'two' => q({0} trojanski unči),
					},
					'parsec' => {
						'few' => q({0} parseki),
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsekov),
						'two' => q({0} parseka),
					},
					'part-per-million' => {
						'few' => q({0} delcev na milijon),
						'name' => q(delci na milijon),
						'one' => q({0} delec na milijon),
						'other' => q({0} delcev na milijon),
						'two' => q({0} delca na milijon),
					},
					'per' => {
						'1' => q({0} na {1}),
					},
					'percent' => {
						'few' => q({0} %),
						'name' => q(odstotek),
						'one' => q({0} odstotek),
						'other' => q({0} odstotkov),
						'two' => q({0} %),
					},
					'permille' => {
						'few' => q({0} ‰),
						'name' => q(promile),
						'one' => q({0} promile),
						'other' => q({0} promilov),
						'two' => q({0} ‰),
					},
					'petabyte' => {
						'few' => q({0} PB),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtov),
						'two' => q({0} PB),
					},
					'picometer' => {
						'few' => q({0} pikometri),
						'name' => q(pikometri),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrov),
						'two' => q({0} pikometra),
					},
					'pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pint),
						'two' => q({0} pinti),
					},
					'pint-metric' => {
						'few' => q({0} metrične pinte),
						'name' => q(metrične pinte),
						'one' => q({0} metrična pinta),
						'other' => q({0} metričnih pint),
						'two' => q({0} metrični pinti),
					},
					'point' => {
						'few' => q({0} točke),
						'name' => q(točke),
						'one' => q({0} točka),
						'other' => q({0} pt),
						'two' => q({0} točki),
					},
					'pound' => {
						'few' => q({0} funti),
						'name' => q(funti),
						'one' => q({0} funt),
						'other' => q({0} funtov),
						'per' => q({0} na funt),
						'two' => q({0} funta),
					},
					'pound-per-square-inch' => {
						'few' => q({0} funti na kvadratni palec),
						'name' => q(funti na kvadratni palec),
						'one' => q({0} funt na kvadratni palec),
						'other' => q({0} funtov na kvadratni palec),
						'two' => q({0} funta na kvadratni palec),
					},
					'quart' => {
						'few' => q({0} četrtine),
						'name' => q(četrtine),
						'one' => q({0} četrtina),
						'other' => q({0} četrtin),
						'two' => q({0} četrtini),
					},
					'radian' => {
						'few' => q({0} radianov),
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radianov),
						'two' => q({0} radiana),
					},
					'revolution' => {
						'few' => q({0} vrtljaji),
						'name' => q(vrtljaj),
						'one' => q({0} vrtljaj),
						'other' => q({0} vrtljajev),
						'two' => q({0} vrtljaja),
					},
					'second' => {
						'few' => q({0} sekunde),
						'name' => q(sekund),
						'one' => q({0} sekunda),
						'other' => q({0} sekund),
						'per' => q({0} na sekundo),
						'two' => q({0} sekundi),
					},
					'square-centimeter' => {
						'few' => q({0} kvadratni centimetri),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimeter),
						'other' => q({0} kvadratnih centimetrov),
						'per' => q({0} na kvadratni centimeter),
						'two' => q({0} kvadratna centimetra),
					},
					'square-foot' => {
						'few' => q({0} kvadratni čevlji),
						'name' => q(kvadratni čevelj),
						'one' => q({0} kvadratni čevelj),
						'other' => q({0} kvadratnih čevljev),
						'two' => q({0} kvadratna čevlja),
					},
					'square-inch' => {
						'few' => q({0} kvadratnih palcev),
						'name' => q(kvadratni palec),
						'one' => q({0} kvadratni palec),
						'other' => q({0} kvadratnih palcev),
						'per' => q({0} na kvadratni palec),
						'two' => q({0} kvadratna palca),
					},
					'square-kilometer' => {
						'few' => q({0} kvadratni kilometri),
						'name' => q(kvadratni kilometri),
						'one' => q({0} kvadratni kilometer),
						'other' => q({0} kvadratnih kilometrov),
						'per' => q({0} na kvadratni kilometer),
						'two' => q({0} kvadratna kilometra),
					},
					'square-meter' => {
						'few' => q({0} kvadratni metri),
						'name' => q(kvadratni metri),
						'one' => q({0} kvadratni meter),
						'other' => q({0} kvadratnih metrov),
						'per' => q({0} na kvadratni meter),
						'two' => q({0} kvadratna metra),
					},
					'square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratna milja),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milj),
						'per' => q({0} na kvadratno miljo),
						'two' => q({0} kvadratni milji),
					},
					'square-yard' => {
						'few' => q({0} kvadratni jardi),
						'name' => q(kvadratni yard),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jardov),
						'two' => q({0} kvadratna jarda),
					},
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					'tablespoon' => {
						'few' => q({0} jedilne žlice),
						'name' => q(jedilne žlice),
						'one' => q({0} jedilna žlica),
						'other' => q({0} jedilnih žlic),
						'two' => q({0} jedilni žlici),
					},
					'teaspoon' => {
						'few' => q({0} čajne žličke),
						'name' => q(čajne žličke),
						'one' => q({0} čajna žlička),
						'other' => q({0} čajnih žličk),
						'two' => q({0} čajni žlički),
					},
					'terabit' => {
						'few' => q({0} terabiti),
						'name' => q(terabiti),
						'one' => q({0} terabit),
						'other' => q({0} terabitov),
						'two' => q({0} terabita),
					},
					'terabyte' => {
						'few' => q({0} terabajti),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtov),
						'two' => q({0} terabajta),
					},
					'ton' => {
						'few' => q({0} tone),
						'name' => q(tone),
						'one' => q({0} ameriška tona),
						'other' => q({0} ameriških ton),
						'two' => q({0} ameriški toni),
					},
					'volt' => {
						'few' => q({0} volti),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} voltov),
						'two' => q({0} volta),
					},
					'watt' => {
						'few' => q({0} vati),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vatov),
						'two' => q({0} vata),
					},
					'week' => {
						'few' => q({0} tednov),
						'name' => q(tednov),
						'one' => q({0} teden),
						'other' => q({0} tednov),
						'per' => q({0} na teden),
						'two' => q({0} tedna),
					},
					'yard' => {
						'few' => q({0} jardi),
						'name' => q(jardi),
						'one' => q({0} jard),
						'other' => q({0} jardov),
						'two' => q({0} jarda),
					},
					'year' => {
						'few' => q({0} let),
						'name' => q(let),
						'one' => q({0} leto),
						'other' => q({0} let),
						'per' => q({0} na leto),
						'two' => q({0} leti),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(smer),
					},
					'acre' => {
						'few' => q({0} jut.),
						'one' => q({0} jut.),
						'other' => q({0} jut.),
						'two' => q({0} jut.),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} ae),
						'name' => q(ae),
						'one' => q({0} ae),
						'other' => q({0} ae),
						'two' => q({0} ae),
					},
					'carat' => {
						'few' => q({0} CD),
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
						'two' => q({0} CD),
					},
					'celsius' => {
						'few' => q({0} °),
						'name' => q(°C),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
						'two' => q({0} cm),
					},
					'century' => {
						'few' => q({0} st),
						'name' => q(st.),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					'coordinate' => {
						'east' => q({0} V),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					'day' => {
						'few' => q({0} d),
						'name' => q(dni),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/dan.),
						'two' => q({0} d),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
						'two' => q({0} dm),
					},
					'degree' => {
						'few' => q({0} °),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
						'two' => q({0} °F),
					},
					'fathom' => {
						'few' => q({0} fth),
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'two' => q({0} fth),
					},
					'foot' => {
						'few' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
						'two' => q({0} ft),
					},
					'furlong' => {
						'few' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
						'two' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
						'two' => q({0} g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					'horsepower' => {
						'few' => q({0} KM),
						'one' => q({0} KM),
						'other' => q({0} hp),
						'two' => q({0} KM),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(ur),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
						'two' => q({0} h),
					},
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
						'two' => q({0} in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					'kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
						'two' => q({0} K),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
						'two' => q({0} kg),
					},
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'two' => q({0} km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					'knot' => {
						'few' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
						'two' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} sv. l.),
						'name' => q(sv. let),
						'one' => q({0} sv. l.),
						'other' => q({0} sv. l.),
						'two' => q({0} sv. l.),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'two' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
						'two' => q({0} l/100 km),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
						'two' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'two' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
						'two' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
						'two' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'two' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
						'two' => q({0} smi),
					},
					'millibar' => {
						'few' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					'milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
						'two' => q({0} mg),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
						'two' => q({0} mm Hg),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					'minute' => {
						'few' => q({0} min),
						'name' => q(minut),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
						'two' => q({0} min),
					},
					'month' => {
						'few' => q({0} m),
						'name' => q(mesecev),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
						'two' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
						'two' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
						'two' => q({0} nmi),
					},
					'ounce' => {
						'few' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
						'two' => q({0} oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
						'two' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
						'two' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0} %),
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					'picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					'point' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
						'two' => q({0} lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
						'two' => q({0} psi),
					},
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
						'two' => q({0} s),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'two' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'two' => q({0} m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'two' => q({0} mi²),
					},
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					'ton' => {
						'few' => q({0} tn),
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
						'two' => q({0} tn),
					},
					'watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					'week' => {
						'few' => q({0} t),
						'name' => q(tednov),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
						'two' => q({0} t),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					'year' => {
						'few' => q({0} l),
						'name' => q(let),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
					},
				},
				'short' => {
					'' => {
						'name' => q(smer),
					},
					'acre' => {
						'few' => q({0} ac),
						'name' => q(aker),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'two' => q({0} ac),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
						'two' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
						'two' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} ae),
						'name' => q(ae),
						'one' => q({0} ae),
						'other' => q({0} ae),
						'two' => q({0} ae),
					},
					'atmosphere' => {
						'few' => q({0} atm),
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
						'two' => q({0} atm),
					},
					'bit' => {
						'few' => q({0} bit),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
						'two' => q({0} bit),
					},
					'byte' => {
						'few' => q({0} bajti),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
						'two' => q({0} bajta),
					},
					'calorie' => {
						'few' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'two' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} CD),
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
						'two' => q({0} CD),
					},
					'celsius' => {
						'few' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
						'two' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} cL),
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
						'two' => q({0} cL),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
						'two' => q({0} cm),
					},
					'century' => {
						'few' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
						'two' => q({0} stol.),
					},
					'coordinate' => {
						'east' => q({0} V),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
						'two' => q({0} cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
						'two' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
						'two' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'two' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
						'two' => q({0} m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'two' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
						'two' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
						'two' => q({0} c),
					},
					'cup-metric' => {
						'few' => q({0} m. skod.),
						'name' => q(m. skod.),
						'one' => q({0} m. skod.),
						'other' => q({0} m. skod.),
						'two' => q({0} m. skod.),
					},
					'day' => {
						'few' => q({0} d),
						'name' => q(dni),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0} na dan),
						'two' => q({0} d),
					},
					'deciliter' => {
						'few' => q({0} dL),
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
						'two' => q({0} dL),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
						'two' => q({0} dm),
					},
					'degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
						'two' => q({0} °F),
					},
					'fathom' => {
						'few' => q({0} fth),
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'two' => q({0} fth),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
					},
					'foot' => {
						'few' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
						'two' => q({0} ft),
					},
					'furlong' => {
						'few' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
						'two' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
						'two' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					'gallon-imperial' => {
						'few' => q({0} imp. gal),
						'name' => q(imp. gal),
						'one' => q({0} imp. gal),
						'other' => q({0} imp. gal),
						'per' => q({0}/imp. gal),
						'two' => q({0} imp. gal),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
						'two' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
						'two' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
						'two' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
						'two' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
						'two' => q({0} g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'two' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hL),
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
						'two' => q({0} hL),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'two' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
						'two' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} KM),
						'name' => q(KM),
						'one' => q({0} KM),
						'other' => q({0} KM),
						'two' => q({0} KM),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(ur),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
						'two' => q({0} h),
					},
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
						'two' => q({0} in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'two' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'two' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
						'two' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
						'two' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
						'two' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
						'two' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
						'two' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
						'two' => q({0} kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
						'two' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
						'two' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'two' => q({0} km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'two' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'two' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
						'two' => q({0} kWh),
					},
					'knot' => {
						'few' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
						'two' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} sv. leta),
						'name' => q(sv. let),
						'one' => q({0} sv. let),
						'other' => q({0} sv. let),
						'two' => q({0} sv. leti),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
						'two' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} L/km),
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
						'two' => q({0} L/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
						'two' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
						'two' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
						'two' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
						'two' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
						'two' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'two' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
						'two' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'two' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
						'two' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
						'two' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'two' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp.),
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
						'two' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'two' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
						'two' => q({0} smi),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
						'two' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'two' => q({0} mbar),
					},
					'milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
						'two' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} mg/dL),
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
						'two' => q({0} mg/dL),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'two' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mmHG),
						'name' => q(mmHg),
						'one' => q({0} mmHG),
						'other' => q({0} mmHG),
						'two' => q({0} mmHG),
					},
					'millimole-per-liter' => {
						'few' => q({0} mmol/L),
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
						'two' => q({0} mmol/L),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
						'two' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
						'two' => q({0} min),
					},
					'month' => {
						'few' => q({0} m),
						'name' => q(mesecev),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
						'two' => q({0} m),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
						'two' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
						'two' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
						'two' => q({0} nmi),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
						'two' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
						'two' => q({0} oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
						'two' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
						'two' => q({0} pc),
					},
					'part-per-million' => {
						'few' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
						'two' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0} %),
						'name' => q(odstotek),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					'permille' => {
						'few' => q({0} ‰),
						'name' => q(promile),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					'petabyte' => {
						'few' => q({0} PB),
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
						'two' => q({0} PB),
					},
					'picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'two' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					'pint-metric' => {
						'few' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
						'two' => q({0} mpt),
					},
					'point' => {
						'few' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
						'two' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
						'two' => q({0} lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
						'two' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
						'two' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
						'two' => q({0} rad),
					},
					'revolution' => {
						'few' => q({0} vrt),
						'name' => q(vrt),
						'one' => q({0} vrt),
						'other' => q({0} vrt),
						'two' => q({0} vrt),
					},
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/s),
						'two' => q({0} sek.),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
						'two' => q({0} cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'two' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
						'two' => q({0} in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
						'two' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
						'two' => q({0} m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
						'two' => q({0} mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
						'two' => q({0} yd²),
					},
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					'tablespoon' => {
						'few' => q({0} žlice),
						'name' => q(žlica),
						'one' => q({0} žlica),
						'other' => q({0} žlic),
						'two' => q({0} žlici),
					},
					'teaspoon' => {
						'few' => q({0} žličke),
						'name' => q(žlička),
						'one' => q({0} žlička),
						'other' => q({0} žličk),
						'two' => q({0} žlički),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
						'two' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
						'two' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} sh tn),
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
						'two' => q({0} sh tn),
					},
					'volt' => {
						'few' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
						'two' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
						'two' => q({0} W),
					},
					'week' => {
						'few' => q({0} t),
						'name' => q(tednov),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
						'two' => q({0} t),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
						'two' => q({0} yd),
					},
					'year' => {
						'few' => q({0} l),
						'name' => q(let),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
						'two' => q({0} l),
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
				end => q({0} in {1}),
				2 => q({0} in {1}),
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
			'exponential' => q(e),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
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
					'two' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
					'two' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
					'two' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mio'.'',
					'one' => '0 mio'.'',
					'other' => '0 mio'.'',
					'two' => '0 mio'.'',
				},
				'10000000' => {
					'few' => '00 mio'.'',
					'one' => '00 mio'.'',
					'other' => '00 mio'.'',
					'two' => '00 mio'.'',
				},
				'100000000' => {
					'few' => '000 mio'.'',
					'one' => '000 mio'.'',
					'other' => '000 mio'.'',
					'two' => '000 mio'.'',
				},
				'1000000000' => {
					'few' => '0 mrd'.'',
					'one' => '0 mrd'.'',
					'other' => '0 mrd'.'',
					'two' => '0 mrd'.'',
				},
				'10000000000' => {
					'few' => '00 mrd'.'',
					'one' => '00 mrd'.'',
					'other' => '00 mrd'.'',
					'two' => '00 mrd'.'',
				},
				'100000000000' => {
					'few' => '000 mrd'.'',
					'one' => '000 mrd'.'',
					'other' => '000 mrd'.'',
					'two' => '000 mrd'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
					'two' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
					'two' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
					'two' => '000 bil'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
					'few' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
					'two' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
					'two' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
					'two' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mio'.'',
					'one' => '0 mio'.'',
					'other' => '0 mio'.'',
					'two' => '0 mio'.'',
				},
				'10000000' => {
					'few' => '00 mio'.'',
					'one' => '00 mio'.'',
					'other' => '00 mio'.'',
					'two' => '00 mio'.'',
				},
				'100000000' => {
					'few' => '000 mio'.'',
					'one' => '000 mio'.'',
					'other' => '000 mio'.'',
					'two' => '000 mio'.'',
				},
				'1000000000' => {
					'few' => '0 mrd'.'',
					'one' => '0 mrd'.'',
					'other' => '0 mrd'.'',
					'two' => '0 mrd'.'',
				},
				'10000000000' => {
					'few' => '00 mrd'.'',
					'one' => '00 mrd'.'',
					'other' => '00 mrd'.'',
					'two' => '00 mrd'.'',
				},
				'100000000000' => {
					'few' => '000 mrd'.'',
					'one' => '000 mrd'.'',
					'other' => '000 mrd'.'',
					'two' => '000 mrd'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
					'two' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
					'two' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
					'two' => '000 bil'.'',
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
			symbol => 'AED',
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
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgani),
				'few' => q(afganiji),
				'one' => q(afgani),
				'other' => q(afganijev),
				'two' => q(afganija),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albanski lek),
				'few' => q(albanski leki),
				'one' => q(albanski lek),
				'other' => q(albanskih lekov),
				'two' => q(albanska leka),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(armenski dram),
				'few' => q(armenski drami),
				'one' => q(armenski dram),
				'other' => q(armenskih dramov),
				'two' => q(armenska drama),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(nizozemsko-antilski gulden),
				'few' => q(nizozemsko-antilski guldni),
				'one' => q(nizozemsko-antilski gulden),
				'other' => q(nizozemsko-antilskih guldnov),
				'two' => q(nizozemsko-antilska guldna),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'AWG',
			display_name => {
				'currency' => q(arubski florin),
				'few' => q(arubski florin),
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
			symbol => 'AZN',
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
			symbol => 'BAM',
			display_name => {
				'currency' => q(bosansko-hercegovska konvertibilna marka),
				'few' => q(bosansko-hercegovske konvertibilne marke),
				'one' => q(bosansko-hercegovska konvertibilna marka),
				'other' => q(bosansko-hercegovskih konvertibilnih mark),
				'two' => q(bosansko-hercegovski konvertibilni marki),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadoški dolar),
				'few' => q(barbadoški dolarji),
				'one' => q(barbadoški dolar),
				'other' => q(barbadoških dolarjev),
				'two' => q(barbadoška dolarja),
			},
		},
		'BDT' => {
			symbol => 'BDT',
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
			symbol => 'BGN',
			display_name => {
				'currency' => q(bolgarski lev),
				'few' => q(bolgarski levi),
				'one' => q(bolgarski lev),
				'other' => q(bolgarskih levov),
				'two' => q(bolgarska leva),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahranski dinar),
				'few' => q(bahranski dinarji),
				'one' => q(bahranski dinar),
				'other' => q(bahranskih dinarjev),
				'two' => q(bahranska dinarja),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundski frank),
				'few' => q(burundski franki),
				'one' => q(burundski frank),
				'other' => q(burundskih frankov),
				'two' => q(burundska franka),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(bermudski dolar),
				'few' => q(bermudski dolarji),
				'one' => q(bermudski dolar),
				'other' => q(bermudskih dolarjev),
				'two' => q(bermudska dolarja),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(brunejski dolar),
				'few' => q(brunejski dolarji),
				'one' => q(brunejski dolar),
				'other' => q(brunejskih dolarjev),
				'two' => q(brunejska dolarja),
			},
		},
		'BOB' => {
			symbol => 'BOB',
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
			symbol => 'BSD',
			display_name => {
				'currency' => q(bahamski dolar),
				'few' => q(bahamski dolarji),
				'one' => q(bahamski dolar),
				'other' => q(bahamskih dolarjev),
				'two' => q(bahamska dolarja),
			},
		},
		'BTN' => {
			symbol => 'BTN',
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
			symbol => 'BWP',
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
			symbol => 'BYN',
			display_name => {
				'currency' => q(beloruski rubelj),
				'few' => q(beloruski rublji),
				'one' => q(beloruski rubelj),
				'other' => q(beloruskih rubljev),
				'two' => q(beloruska rublja),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(beloruski rubelj \(2000–2016\)),
				'few' => q(beloruski rublji \(2000–2016\)),
				'one' => q(beloruski rubelj \(2000–2016\)),
				'other' => q(beloruskih rubljev \(2000–2016\)),
				'two' => q(beloruska rublja \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
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
			symbol => 'CDF',
			display_name => {
				'currency' => q(kongoški frank),
				'few' => q(kongoški frank),
				'one' => q(kongoški frank),
				'other' => q(kongoških frankov),
				'two' => q(kongoška franka),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(evro WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
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
			symbol => 'CLP',
			display_name => {
				'currency' => q(čilski peso),
				'few' => q(čilski pesi),
				'one' => q(čilski peso),
				'other' => q(čilskih pesov),
				'two' => q(čilska pesa),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(kitajski juan \(offshore\)),
				'few' => q(kitajski juani renminbi \(offshore\)),
				'one' => q(kitajski juan renminbi \(offshore\)),
				'other' => q(kitajskih juanov renminbi \(offshore\)),
				'two' => q(kitajska juana renminbi \(offshore\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(kitajski juan),
				'few' => q(kitajski juani renminbi),
				'one' => q(kitajski juan renminbi),
				'other' => q(kitajskih juanov renminbi),
				'two' => q(kitajska juana renmibi),
			},
		},
		'COP' => {
			symbol => 'COP',
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
			symbol => 'CRC',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubanski konvertibilni peso),
				'few' => q(kubanski konvertibilni pesi),
				'one' => q(kubanski konvertibilni peso),
				'other' => q(kubanskih konvertibilnih pesov),
				'two' => q(kubanska konvertibilna pesa),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubanski peso),
				'few' => q(kubanski pesi),
				'one' => q(kubanski peso),
				'other' => q(kubanskih pesov),
				'two' => q(kubanska pesa),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
			symbol => 'CZK',
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
			symbol => 'DJF',
			display_name => {
				'currency' => q(džibutski frank),
				'few' => q(džibutski franki),
				'one' => q(džibutski frank),
				'other' => q(džibutskih frankov),
				'two' => q(džibutska franka),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(danska krona),
				'few' => q(danske krone),
				'one' => q(danska krona),
				'other' => q(danskih kron),
				'two' => q(danski kroni),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dominikanski peso),
				'few' => q(dominikanski pesi),
				'one' => q(dominikanski peso),
				'other' => q(dominikanskih pesov),
				'two' => q(dominikanska pesa),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
			symbol => 'EGP',
			display_name => {
				'currency' => q(egiptovski funt),
				'few' => q(egiptovski funti),
				'one' => q(egiptovski funt),
				'other' => q(egiptovskih funtov),
				'two' => q(egiptovska funta),
			},
		},
		'ERN' => {
			symbol => 'ERN',
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
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiopski bir),
				'few' => q(etiopski biri),
				'one' => q(etiopski bir),
				'other' => q(etiopskih birov),
				'two' => q(etiopska bira),
			},
		},
		'EUR' => {
			symbol => '€',
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
			symbol => 'FJD',
			display_name => {
				'currency' => q(fidžijski dolar),
				'few' => q(fidžijski dolarji),
				'one' => q(fidžijski dolar),
				'other' => q(fidžijskih dolarjev),
				'two' => q(fidžijska dolarja),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
			symbol => 'GEL',
			display_name => {
				'currency' => q(gruzijski lari),
				'few' => q(gruzijski lari),
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
			symbol => 'GHS',
			display_name => {
				'currency' => q(ganski cedi),
				'few' => q(ganski cedi),
				'one' => q(ganski cedi),
				'other' => q(ganskih cedov),
				'two' => q(ganska ceda),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltarski funt),
				'few' => q(gibraltarski funti),
				'one' => q(gibraltarski funt),
				'other' => q(gibraltarskih funtov),
				'two' => q(gibraltarska funta),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambijski dalasi),
				'few' => q(gambijski dalasi),
				'one' => q(gambijski dalasi),
				'other' => q(gambijskih dalasov),
				'two' => q(gambijska dalasa),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
			display_name => {
				'currency' => q(gvajanski dolar),
				'few' => q(gvajanski dolarji),
				'one' => q(gvajanski dolar),
				'other' => q(gvajanskih dolarjev),
				'two' => q(gvajanska dolarja),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(hongkonški dolar),
				'few' => q(hongkonški dolarji),
				'one' => q(hongkonški dolar),
				'other' => q(hongkonških dolarjev),
				'two' => q(hongkonška dolarja),
			},
		},
		'HNL' => {
			symbol => 'HNL',
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
			symbol => 'HRK',
			display_name => {
				'currency' => q(hrvaška kuna),
				'few' => q(hrvaške kune),
				'one' => q(hrvaška kuna),
				'other' => q(hrvaških kun),
				'two' => q(hrvaški kuni),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haitski gurd),
				'few' => q(haitski gurdi),
				'one' => q(haitski gurd),
				'other' => q(haitskih gurdov),
				'two' => q(haitska gurda),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(madžarski forint),
				'few' => q(madžarski forinti),
				'one' => q(madžarski forint),
				'other' => q(madžarskih forintov),
				'two' => q(madžarska forinta),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => '₪',
			display_name => {
				'currency' => q(izraelski šekel),
				'few' => q(izraelski šekeli),
				'one' => q(izraelski šekel),
				'other' => q(izraelskih šekelov),
				'two' => q(izraelska šekela),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(indijska rupija),
				'few' => q(indijske rupije),
				'one' => q(indijska rupija),
				'other' => q(indijskih rupij),
				'two' => q(indijski rupiji),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(iraški dinar),
				'few' => q(iraški dinarji),
				'one' => q(iraški dinar),
				'other' => q(iraških dinarjev),
				'two' => q(iraška dinarja),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iranski rial),
				'few' => q(iranski riali),
				'one' => q(iranski rial),
				'other' => q(iranskih rialov),
				'two' => q(iranska riala),
			},
		},
		'ISK' => {
			symbol => 'ISK',
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
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamajški dolar),
				'few' => q(jamajški dolarji),
				'one' => q(jamajški dolar),
				'other' => q(jamajških dolarjev),
				'two' => q(jamajška dolarja),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(kenijski šiling),
				'few' => q(kenijski šilingi),
				'one' => q(kenijski šiling),
				'other' => q(kenijskih šilingov),
				'two' => q(kenijska šilinga),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgiški som),
				'few' => q(kirgiški somi),
				'one' => q(kirgiški som),
				'other' => q(kirgiških somov),
				'two' => q(kirgiška soma),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kamboški riel),
				'few' => q(kamboški rieli),
				'one' => q(kamboški riel),
				'other' => q(kamboških rielov),
				'two' => q(kamboška riela),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(komorski frank),
				'few' => q(komorski franki),
				'one' => q(komorski frank),
				'other' => q(komorskih frankov),
				'two' => q(komorska franka),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(severnokorejski von),
				'few' => q(severnokorejski voni),
				'one' => q(severnokorejski von),
				'other' => q(severnokorejskih vonov),
				'two' => q(severnokorejska vona),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(južnokorejski von),
				'few' => q(južnokorejski voni),
				'one' => q(južnokorejski von),
				'other' => q(južnokorejskih vonov),
				'two' => q(južnokorejska vona),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuvajtski dinar),
				'few' => q(kuvajtski dinarji),
				'one' => q(kuvajtski dinar),
				'other' => q(kuvajtskih dinarjev),
				'two' => q(kuvajtska dinarja),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(kajmanski dolar),
				'few' => q(kajmanski dolarji),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanski dolar),
				'two' => q(kajmanska dolarja),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kazahstanski tenge),
				'few' => q(kazahstanski tenge),
				'one' => q(kazahstanski tenge),
				'other' => q(kazahstanskih tengov),
				'two' => q(kazahstanska tenga),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laoški kip),
				'few' => q(laoški kipi),
				'one' => q(laoški kip),
				'other' => q(laoških kipov),
				'two' => q(laoška kipa),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanonski funt),
				'few' => q(libanonski funti),
				'one' => q(libanonski funt),
				'other' => q(libanonskih funtov),
				'two' => q(libanonska funta),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(šrilanška rupija),
				'few' => q(šrilanške rupije),
				'one' => q(šrilanška rupija),
				'other' => q(šrilanških rupij),
				'two' => q(šrilanški rupiji),
			},
		},
		'LRD' => {
			symbol => 'LRD',
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
				'currency' => q(lesoški loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(litovski litas),
				'few' => q(litovski litas),
				'one' => q(litovski litas),
				'other' => q(litovski litas),
				'two' => q(litovski litas),
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
			symbol => 'LVL',
			display_name => {
				'currency' => q(latvijski lats),
				'few' => q(latvijski lats),
				'one' => q(latvijski lats),
				'other' => q(latvijski lats),
				'two' => q(latvijski lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latvijski rubelj),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(libijski dinar),
				'few' => q(libijski dinarji),
				'one' => q(libijski dinar),
				'other' => q(libijskih dinarjev),
				'two' => q(libijska dinarja),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldavijski leu),
				'few' => q(moldavijski leu),
				'one' => q(moldavijski leu),
				'other' => q(moldavijskih leuov),
				'two' => q(moldavijska leua),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(malgaški ariarij),
				'few' => q(malgaški ariariji),
				'one' => q(malgaški ariarij),
				'other' => q(malgaških ariarijev),
				'two' => q(malgaška ariarija),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(malgaški frank),
			},
		},
		'MKD' => {
			symbol => 'MKD',
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
			symbol => 'MMK',
			display_name => {
				'currency' => q(mjanmarski kjat),
				'few' => q(mjanmarski kjati),
				'one' => q(mjanmarski kjat),
				'other' => q(mjanmarskih kjatov),
				'two' => q(mjanmarska kjata),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolski tugriki),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskih tugrikov),
				'two' => q(mongolska tugrika),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(makavska pataka),
				'few' => q(makavske patake),
				'one' => q(makavska pataka),
				'other' => q(makavskih patak),
				'two' => q(makavski pataki),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(mavretanska uguija \(1973–2017\)),
				'few' => q(mavretanske uguije \(1973–2017\)),
				'one' => q(mavretanska uguija \(1973–2017\)),
				'other' => q(mavretanskih uguij \(1973–2017\)),
				'two' => q(mavretanski uguiji \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(mavricijska rupija),
				'few' => q(mavricijske rupije),
				'one' => q(mavricijska rupija),
				'other' => q(mavricijskih rupij),
				'two' => q(mavricijski rupiji),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maldivska rufija),
				'few' => q(maldivske rufije),
				'one' => q(maldivska rufija),
				'other' => q(maldivskih rufij),
				'two' => q(maldivski rufiji),
			},
		},
		'MWK' => {
			symbol => 'MWK',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(mozambiški metikal),
				'few' => q(mozambiški metikali),
				'one' => q(mozambiški metikal),
				'other' => q(mozambiških metikalov),
				'two' => q(mozambiška metikala),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namibijski dolar),
				'few' => q(namibijski dolarji),
				'one' => q(namibijski dolar),
				'other' => q(namibijskih dolarjev),
				'two' => q(namibijska dolarja),
			},
		},
		'NGN' => {
			symbol => 'NGN',
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
			symbol => 'NIO',
			display_name => {
				'currency' => q(nikaraška zlata kordova),
				'few' => q(nikaraške zlate kordove),
				'one' => q(nikaraška zlata kordova),
				'other' => q(nikaraških zlatih kordov),
				'two' => q(nikaraški zlati kordovi),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nizozemski gulden),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(norveška krona),
				'few' => q(norveške krone),
				'one' => q(norveška krona),
				'other' => q(norveških kron),
				'two' => q(norveški kroni),
			},
		},
		'NPR' => {
			symbol => 'NPR',
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
			symbol => 'OMR',
			display_name => {
				'currency' => q(omanski rial),
				'few' => q(omanski riali),
				'one' => q(omanski rial),
				'other' => q(omanskih rialov),
				'two' => q(omanska riala),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
			symbol => 'PEN',
			display_name => {
				'currency' => q(perujski sol),
				'few' => q(perujski soli),
				'one' => q(perujski sol),
				'other' => q(perujskih solov),
				'two' => q(perujska sola),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(perujski sol \(1863–1965\)),
				'few' => q(perujski soli \(1863–1965\)),
				'one' => q(perujski sol \(1863–1965\)),
				'other' => q(perujskih solov \(1863–1965\)),
				'two' => q(perujska sola \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskih rupij),
				'two' => q(pakistanski rupiji),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(poljski novi zlot),
				'few' => q(poljski novi zloti),
				'one' => q(poljski novi zlot),
				'other' => q(poljskih novih zlotov),
				'two' => q(poljska nova zlota),
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(paragvajski gvarani),
				'few' => q(paragvajski gvarani),
				'one' => q(paragvajski gvarani),
				'other' => q(paragvajskih gvaranijev),
				'two' => q(paragvajska gvaranija),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'RON',
			display_name => {
				'currency' => q(romunski leu),
				'few' => q(romunski leu),
				'one' => q(romunski leu),
				'other' => q(romunskih leuov),
				'two' => q(romunska leua),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(srbski dinar),
				'few' => q(srbski dinarji),
				'one' => q(srbski dinar),
				'other' => q(srbskih dinarjev),
				'two' => q(srbska dinarja),
			},
		},
		'RUB' => {
			symbol => 'RUB',
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
			symbol => 'RWF',
			display_name => {
				'currency' => q(ruandski frank),
				'few' => q(ruandski franki),
				'one' => q(ruandski frank),
				'other' => q(ruandskih frankov),
				'two' => q(ruandska franka),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(saudski rial),
				'few' => q(saudski riali),
				'one' => q(saudski rial),
				'other' => q(saudskih rialov),
				'two' => q(saudska riala),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(solomonski dolar),
				'few' => q(solomonski dolarji),
				'one' => q(solomonski dolar),
				'other' => q(solomonskih dolarjev),
				'two' => q(solomonska dolarja),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
			symbol => 'SDG',
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
			symbol => 'SEK',
			display_name => {
				'currency' => q(švedska krona),
				'few' => q(švedske krone),
				'one' => q(švedska krona),
				'other' => q(švedskih kron),
				'two' => q(švedski kroni),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurski dolarji),
				'one' => q(singapurski dolar),
				'other' => q(singapurskih dolarjev),
				'two' => q(singapurska dolarja),
			},
		},
		'SHP' => {
			symbol => 'SHP',
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(sieraleonski leone),
				'few' => q(sieraleonski leoni),
				'one' => q(sieraleonski leone),
				'other' => q(sieraleonskih leonov),
				'two' => q(sieraleonska leona),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(somalski šiling),
				'few' => q(somalski šilingi),
				'one' => q(somalski šiling),
				'other' => q(somalskih šilingov),
				'two' => q(somalska šilinga),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(južnosudanski funt),
				'few' => q(južnosudanski funti),
				'one' => q(južnosudanski funt),
				'other' => q(južnosudanskih funtov),
				'two' => q(južnosudanska funta),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(saotomejska dobra \(1977–2017\)),
				'few' => q(saotomejske dobre \(1977–2017\)),
				'one' => q(saotomejska dobra \(1977–2017\)),
				'other' => q(saotomejskih dober \(1977–2017\)),
				'two' => q(saotomejski dobri \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(saotomejska dobra),
				'few' => q(saotomejske dobre),
				'one' => q(saotomejska dobra),
				'other' => q(saotomejskih dober),
				'two' => q(saotomejski dobri),
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
			symbol => 'SYP',
			display_name => {
				'currency' => q(sirijski funt),
				'few' => q(sirijski funti),
				'one' => q(sirijski funt),
				'other' => q(sirijskih funtov),
				'two' => q(sirijska funta),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(svazijski lilangeni),
				'few' => q(svazijski lilangeni),
				'one' => q(svazijski lilangeni),
				'other' => q(svazijskih lilangenijev),
				'two' => q(svazijska lilangenija),
			},
		},
		'THB' => {
			symbol => 'THB',
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
			symbol => 'TJS',
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
			symbol => 'TMT',
			display_name => {
				'currency' => q(turkmenistanski novi manat),
				'few' => q(turkmenistanski novi manati),
				'one' => q(turkmenistanski novi manat),
				'other' => q(turkmenistanskih novih manatov),
				'two' => q(turkmenistanska nova manata),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tunizijski dinar),
				'few' => q(tunizijski dinarji),
				'one' => q(tunizijski dinar),
				'other' => q(tunizijskih dinarjev),
				'two' => q(tunizijska dinarja),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
			symbol => 'TRY',
			display_name => {
				'currency' => q(nova turška lira),
				'few' => q(nove turške lire),
				'one' => q(nova turška lira),
				'other' => q(novih turških lir),
				'two' => q(novi turški liri),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzanijski šiling),
				'few' => q(tanzanijski šilingi),
				'one' => q(tanzanijski šiling),
				'other' => q(tanzanijskih šilingov),
				'two' => q(tanzanijska šilinga),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
			symbol => 'UGX',
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(urugvajski peso),
				'few' => q(urugvajski pesi),
				'one' => q(urugvajski peso),
				'other' => q(urugvajskih pesov),
				'two' => q(urugvajska pesa),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
			symbol => 'VEF',
			display_name => {
				'currency' => q(venezuelski bolivar \(2008–2018\)),
				'few' => q(venezuelski bolivarji \(2008–2018\)),
				'one' => q(venezuelski bolivar \(2008–2018\)),
				'other' => q(venezuelskih bolivarjev \(2008–2018\)),
				'two' => q(venezuelska bolivarja \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(venezuelski bolivar),
				'few' => q(venezuelski bolivarji),
				'one' => q(venezuelski bolivar),
				'other' => q(venezuelskih bolivarjev),
				'two' => q(venezuelska bolivarja),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(vientnamski dong),
				'few' => q(vietnamski dongi),
				'one' => q(vientnamski dong),
				'other' => q(vietnamskih dongov),
				'two' => q(vietnamska donga),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatujski vatu),
				'few' => q(vanuatujski vati),
				'one' => q(vanuatujski vatu),
				'other' => q(vanuatujskih vatujev),
				'two' => q(vanuatujska vatuja),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(samoanska tala),
				'few' => q(samoanske tale),
				'one' => q(samoanska tala),
				'other' => q(samoanskih tal),
				'two' => q(samoanski tali),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA frank BEAC),
				'few' => q(franki CFA BEAC),
				'one' => q(srednjeafriški frank CFA),
				'other' => q(srednjeafriški frank CFA),
				'two' => q(franka CFA BEAC),
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
			symbol => 'CFA',
			display_name => {
				'currency' => q(zahodnoafriški frank CFA),
				'few' => q(franki CFA BCEAO),
				'one' => q(zahodnoafriški frank CFA),
				'other' => q(zahodnoafriški frank CFA),
				'two' => q(franka CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladij),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP frank),
				'few' => q(franki CFP),
				'one' => q(CFP frank),
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
			symbol => 'YER',
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
			symbol => 'ZAR',
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
			symbol => 'ZMW',
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
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'avg.',
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
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
					narrow => {
						mon => 'p',
						tue => 't',
						wed => 's',
						thu => 'č',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
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
					abbreviated => {
						mon => 'pon.',
						tue => 'tor.',
						wed => 'sre.',
						thu => 'čet.',
						fri => 'pet.',
						sat => 'sob.',
						sun => 'ned.'
					},
					narrow => {
						mon => 'p',
						tue => 't',
						wed => 's',
						thu => 'č',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. četrtletje',
						1 => '2. četrtletje',
						2 => '3. četrtletje',
						3 => '4. četrtletje'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1. čet.',
						1 => '2. čet.',
						2 => '3. čet.',
						3 => '4. čet.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. četrtletje',
						1 => '2. četrtletje',
						2 => '3. četrtletje',
						3 => '4. četrtletje'
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
			if ($_ eq 'coptic') {
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
			if ($_ eq 'ethiopic') {
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
			if ($_ eq 'hebrew') {
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
			if ($_ eq 'indian') {
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
			if ($_ eq 'islamic') {
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
			if ($_ eq 'persian') {
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
					'am' => q{dop.},
					'evening1' => q{zvečer},
					'midnight' => q{opolnoči},
					'morning1' => q{zjutraj},
					'morning2' => q{dopoldan},
					'night1' => q{ponoči},
					'noon' => q{opoldne},
					'pm' => q{pop.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pop.},
					'am' => q{dop.},
					'evening1' => q{zveč.},
					'midnight' => q{poln.},
					'morning1' => q{jut.},
					'morning2' => q{dop.},
					'night1' => q{noč},
					'noon' => q{pold.},
					'pm' => q{pop.},
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
				'0' => 'pr. Kr.',
				'1' => 'po Kr.'
			},
			wide => {
				'0' => 'pred Kristusom',
				'1' => 'po Kristusu'
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
				'0' => 'Saka'
			},
			narrow => {
				'0' => 'Saka'
			},
			wide => {
				'0' => 'Saka'
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
				'0' => 'AH'
			},
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
				'0' => 'pred RK',
				'1' => 'Minguo koledar'
			},
			narrow => {
				'0' => 'pred RK',
				'1' => 'Minguo koledar'
			},
			wide => {
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, dd. MMMM y G},
			'long' => q{dd. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d. MM. yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, dd. MMMM y},
			'long' => q{dd. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{d. MM. yy},
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
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyM => q{M/y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d. M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyM => q{MMM y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH'h'},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d. M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMW => q{W. 'teden' 'v' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d. M. y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d. M. y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'teden' 'v' Y},
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
				M => q{M.–M. y},
				y => q{M. y – M. y},
			},
			yMEd => {
				M => q{E, d. M. – E, d. M. y},
				d => q{E, d. – E, d. M. y},
				y => q{E, d. M. y – E, d. M. y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. MMM – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{d. M. – d. M. y},
				d => q{d. M. y – d. M. y},
				y => q{d. M. y – d. M. y},
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
				a => q{h a–h a},
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
				M => q{M.–M. y},
				y => q{M. y–M. y},
			},
			yMEd => {
				M => q{E, d. M. – E, d. M. y},
				d => q{E, d. – E, d. M. y},
				y => q{E, d. M. y – E, d. M. y},
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
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} čas),
		regionFormat => q({0} poletni čas),
		regionFormat => q({0} standardni čas),
		fallbackFormat => q({1} ({0})),
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
			exemplarCity => q#Kartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinšasa#,
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
			exemplarCity => q#Lubumbaši#,
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
			exemplarCity => q#Mogadišu#,
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
			exemplarCity => q#Guadeloupe#,
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
			exemplarCity => q#Martinik#,
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
			exemplarCity => q#Ciudad de Mexico#,
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
			exemplarCity => q#Center, Severna Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Severna Dakota#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
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
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrajn#,
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
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunej#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Čojbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damask#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
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
			exemplarCity => q#Hongkong#,
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
			exemplarCity => q#Macao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muškat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikozija#,
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
			exemplarCity => q#Uralsk#,
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
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
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
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
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
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
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
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Južna Georgia#,
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
		'Choibalsan' => {
			long => {
				'daylight' => q#Čojbalsanski poletni čas#,
				'generic' => q#Čojbalsanski čas#,
				'standard' => q#Čojbalsanski standardni čas#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
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
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
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
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišinjev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Köbenhavn#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#irski standardni čas#,
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
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lizbona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#britanski poletni čas#,
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
			exemplarCity => q#Praga#,
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
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
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
			exemplarCity => q#Dunaj#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilna#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
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
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
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
				'standard' => q#Ekvatorski otoki: Čas#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Poletni čas otoka Lord Howe#,
				'generic' => q#Čas otoka Lord Howe#,
				'standard' => q#Standardni čas otoka Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarieski čas#,
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
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Mehiški severozahodni poletni čas#,
				'generic' => q#Mehiški severozahodni čas#,
				'standard' => q#Mehiški severozahodni standardni čas#,
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
				'standard' => q#Čas: Norfolški otoki#,
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
			exemplarCity => q#Velikonočni otok#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
