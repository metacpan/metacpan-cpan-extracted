=encoding utf8

=head1

Locale::CLDR::Locales::Bs - Package for language Bosnian

=cut

package Locale::CLDR::Locales::Bs;
# This file auto generated from Data\common\main\bs.xml
#	on Sun  7 Oct 10:23:15 am GMT

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine' ]},
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
					rule => q(jedinica),
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
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četristo[ →→]),
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
					rule => q(←%spellout-cardinal-feminine← hiljada[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliard[ →→]),
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
					rule => q(jedenaest),
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
					rule => q(šestnaest),
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
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četristo[ →→]),
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
					rule => q(←%spellout-cardinal-feminine← hiljada[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliard[ →→]),
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
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(četristo[ →→]),
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
					rule => q(←%spellout-cardinal-feminine← hiljada[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliard[ →→]),
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
				'aa' => 'afarski',
 				'ab' => 'abhaski',
 				'ace' => 'ačinski',
 				'ach' => 'akoli',
 				'ada' => 'adangmejski',
 				'ady' => 'adigejski',
 				'ae' => 'avestanski',
 				'af' => 'afrikans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akadijski',
 				'ale' => 'aleutski',
 				'alt' => 'južni altai',
 				'am' => 'amharski',
 				'an' => 'aragonski',
 				'ang' => 'staroengleski',
 				'anp' => 'angika',
 				'ar' => 'arapski',
 				'ar_001' => 'moderni standardni arapski',
 				'arc' => 'aramejski',
 				'arn' => 'mapuški',
 				'arp' => 'arapaho',
 				'arw' => 'aravak',
 				'as' => 'asamski',
 				'asa' => 'asu',
 				'ast' => 'asturijski',
 				'av' => 'avarski',
 				'awa' => 'avadhi',
 				'ay' => 'ajmara',
 				'az' => 'azerbejdžanski',
 				'az@alt=short' => 'azerski',
 				'ba' => 'baškirski',
 				'bal' => 'baluči',
 				'ban' => 'balinezijski',
 				'bas' => 'basa',
 				'bax' => 'bamunski',
 				'bbj' => 'gomala',
 				'be' => 'bjeloruski',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'bugarski',
 				'bgn' => 'zapadni belučki',
 				'bho' => 'bojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengalski',
 				'bo' => 'tibetanski',
 				'br' => 'bretonski',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosanski',
 				'bss' => 'akoski',
 				'bua' => 'buriat',
 				'bug' => 'bugiški',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'katalonski',
 				'cad' => 'kado',
 				'car' => 'karipski',
 				'cay' => 'kajuga',
 				'cch' => 'atsam',
 				'ce' => 'čečenski',
 				'ceb' => 'cebuano',
 				'cgg' => 'čiga',
 				'ch' => 'čamoro',
 				'chb' => 'čibča',
 				'chg' => 'čagatai',
 				'chk' => 'čukeski',
 				'chm' => 'mari',
 				'chn' => 'činukski žargon',
 				'cho' => 'čoktav',
 				'chp' => 'čipvijanski',
 				'chr' => 'čiroki',
 				'chy' => 'čejenski',
 				'ckb' => 'centralnokurdski',
 				'co' => 'korzikanski',
 				'cop' => 'koptski',
 				'cr' => 'kri',
 				'crh' => 'krimski turski',
 				'crs' => 'seselva kreolski francuski',
 				'cs' => 'češki',
 				'csb' => 'kašubijanski',
 				'cu' => 'staroslavenski',
 				'cv' => 'čuvaški',
 				'cy' => 'velški',
 				'da' => 'danski',
 				'dak' => 'dakota',
 				'dar' => 'dargva',
 				'dav' => 'taita',
 				'de' => 'njemački',
 				'de_CH' => 'gornjonjemački (Švicarska)',
 				'del' => 'delaver',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'donjolužičkosrpski',
 				'dua' => 'duala',
 				'dum' => 'srednjovjekovni holandski',
 				'dv' => 'divehi',
 				'dyo' => 'jola-foni',
 				'dyu' => 'diula',
 				'dz' => 'džonga',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efik',
 				'egy' => 'staroegipatski',
 				'eka' => 'ekajuk',
 				'el' => 'grčki',
 				'elx' => 'elamitski',
 				'en' => 'engleski',
 				'en_GB@alt=short' => 'engleski (UK)',
 				'en_US@alt=short' => 'engleski (SAD)',
 				'enm' => 'srednjovjekovni engleski',
 				'eo' => 'esperanto',
 				'es' => 'španski',
 				'et' => 'estonski',
 				'eu' => 'baskijski',
 				'ewo' => 'evondo',
 				'fa' => 'perzijski',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finski',
 				'fil' => 'filipino',
 				'fj' => 'fidžijski',
 				'fo' => 'farski',
 				'fon' => 'fon',
 				'fr' => 'francuski',
 				'frm' => 'srednjovjekovni francuski',
 				'fro' => 'starofrancuski',
 				'frr' => 'sjeverni frizijski',
 				'frs' => 'istočnofrizijski',
 				'fur' => 'friulijski',
 				'fy' => 'zapadni frizijski',
 				'ga' => 'irski',
 				'gaa' => 'ga',
 				'gag' => 'gagauški',
 				'gay' => 'gajo',
 				'gba' => 'gbaja',
 				'gd' => 'škotski galski',
 				'gez' => 'staroetiopski',
 				'gil' => 'gilbertski',
 				'gl' => 'galicijski',
 				'gmh' => 'srednjovjekovni gornjonjemački',
 				'gn' => 'gvarani',
 				'goh' => 'staronjemački',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotski',
 				'grb' => 'grebo',
 				'grc' => 'starogrčki',
 				'gsw' => 'njemački (Švicarska)',
 				'gu' => 'gudžarati',
 				'guz' => 'gusi',
 				'gv' => 'manks',
 				'gwi' => 'gvičin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'haw' => 'havajski',
 				'he' => 'hebrejski',
 				'hi' => 'hindi',
 				'hil' => 'hiligajnon',
 				'hit' => 'hitite',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'hrvatski',
 				'hsb' => 'gornjolužičkosrpski',
 				'ht' => 'haićanski kreolski',
 				'hu' => 'mađarski',
 				'hup' => 'hupa',
 				'hy' => 'armenski',
 				'hz' => 'herero',
 				'ia' => 'interlingva',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonezijski',
 				'ie' => 'interlingve',
 				'ig' => 'igbo',
 				'ii' => 'sičuan ji',
 				'ik' => 'inupiak',
 				'ilo' => 'iloko',
 				'inh' => 'ingušetski',
 				'io' => 'ido',
 				'is' => 'islandski',
 				'it' => 'talijanski',
 				'iu' => 'inuktitut',
 				'ja' => 'japanski',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'makame',
 				'jpr' => 'judeo-perzijski',
 				'jrb' => 'judeo-arapski',
 				'jv' => 'javanski',
 				'ka' => 'gruzijski',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'kabile',
 				'kac' => 'kačin',
 				'kaj' => 'kaju',
 				'kam' => 'kamba',
 				'kaw' => 'kavi',
 				'kbd' => 'kabardijski',
 				'kbl' => 'kanembu',
 				'kcg' => 'tjap',
 				'kde' => 'makonde',
 				'kea' => 'zelenortski',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'kasi',
 				'kho' => 'kotanizijski',
 				'khq' => 'kojra čini',
 				'ki' => 'kikuju',
 				'kj' => 'kuanjama',
 				'kk' => 'kazaški',
 				'kkj' => 'kako',
 				'kl' => 'kalalisutski',
 				'kln' => 'kalenjin',
 				'km' => 'kmerski',
 				'kmb' => 'kimbundu',
 				'kn' => 'kanada',
 				'ko' => 'korejski',
 				'koi' => 'komi-permski',
 				'kok' => 'konkani',
 				'kos' => 'kosrejski',
 				'kpe' => 'kpele',
 				'kr' => 'kanuri',
 				'krc' => 'karačaj-balkar',
 				'kri' => 'krio',
 				'krl' => 'karelijski',
 				'kru' => 'kuruški',
 				'ks' => 'kašmirski',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kelnski',
 				'ku' => 'kurdski',
 				'kum' => 'kumik',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'kornski',
 				'ky' => 'kirgiški',
 				'la' => 'latinski',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'landa',
 				'lam' => 'lamba',
 				'lb' => 'luksemburški',
 				'lez' => 'lezgijski',
 				'lg' => 'ganda',
 				'li' => 'limburški',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laoski',
 				'lol' => 'mongo',
 				'loz' => 'lozi',
 				'lrc' => 'sjeverni luri',
 				'lt' => 'litvanski',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luhija',
 				'lv' => 'latvijski',
 				'mad' => 'madureški',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maitili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'mokša',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauricijski kreolski',
 				'mg' => 'malgaški',
 				'mga' => 'srednjovjekovni irski',
 				'mgh' => 'makuva-meto',
 				'mgo' => 'meta',
 				'mh' => 'maršalski',
 				'mi' => 'maorski',
 				'mic' => 'mikmak',
 				'min' => 'minangkabau',
 				'mk' => 'makedonski',
 				'ml' => 'malajalam',
 				'mn' => 'mongolski',
 				'mnc' => 'manču',
 				'mni' => 'manipuri',
 				'moh' => 'mohavk',
 				'mos' => 'mosi',
 				'mr' => 'marati',
 				'ms' => 'malajski',
 				'mt' => 'malteški',
 				'mua' => 'mundang',
 				'mul' => 'više jezika',
 				'mus' => 'kriški',
 				'mwl' => 'mirandeški',
 				'mwr' => 'marvari',
 				'my' => 'burmanski',
 				'mye' => 'mjene',
 				'myv' => 'erzija',
 				'mzn' => 'mazanderanski',
 				'na' => 'nauru',
 				'nap' => 'napolitanski',
 				'naq' => 'nama',
 				'nb' => 'norveški (Bokmal)',
 				'nd' => 'sjeverni ndebele',
 				'nds' => 'donjonjemački',
 				'nds_NL' => 'donjosaksonski',
 				'ne' => 'nepalski',
 				'new' => 'nevari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'nl' => 'holandski',
 				'nl_BE' => 'flamanski',
 				'nmg' => 'kvasio',
 				'nn' => 'norveški (Nynorsk)',
 				'nnh' => 'ngiembon',
 				'no' => 'norveški',
 				'nog' => 'nogai',
 				'non' => 'staronordijski',
 				'nqo' => 'nko',
 				'nr' => 'južni ndebele',
 				'nso' => 'sjeverni soto',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nwc' => 'klasični nevari',
 				'ny' => 'njanja',
 				'nym' => 'njamvezi',
 				'nyn' => 'njankole',
 				'nyo' => 'njoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitanski',
 				'oj' => 'ojibva',
 				'om' => 'oromo',
 				'or' => 'orijski',
 				'os' => 'osetski',
 				'osa' => 'osage',
 				'ota' => 'osmanski turski',
 				'pa' => 'pandžapski',
 				'pag' => 'pangasinski',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauanski',
 				'pcm' => 'nigerijski pidžin',
 				'peo' => 'staroperzijski',
 				'phn' => 'feničanski',
 				'pi' => 'pali',
 				'pl' => 'poljski',
 				'pon' => 'ponpejski',
 				'prg' => 'pruski',
 				'pro' => 'staroprovansalski',
 				'ps' => 'paštu',
 				'ps@alt=variant' => 'pušto',
 				'pt' => 'portugalski',
 				'qu' => 'kečua',
 				'quc' => 'kiče',
 				'raj' => 'rajastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongan',
 				'rm' => 'retoromanski',
 				'rn' => 'rundi',
 				'ro' => 'rumunski',
 				'ro_MD' => 'moldavski',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'korijenski',
 				'ru' => 'ruski',
 				'rup' => 'arumunski',
 				'rw' => 'kinjaruanda',
 				'rwk' => 'rua',
 				'sa' => 'sanskrit',
 				'sad' => 'sandave',
 				'sah' => 'jakutski',
 				'sam' => 'samaritanski aramejski',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambaj',
 				'sbp' => 'sangu',
 				'sc' => 'sardinijski',
 				'scn' => 'sicilijanski',
 				'sco' => 'škotski',
 				'sd' => 'sindi',
 				'sdh' => 'južni kurdski',
 				'se' => 'sjeverni sami',
 				'see' => 'seneka',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'kojraboro seni',
 				'sg' => 'sango',
 				'sga' => 'staroirski',
 				'sh' => 'srpskohrvatski',
 				'shi' => 'tahelhit',
 				'shn' => 'šan',
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
 				'sn' => 'šona',
 				'snk' => 'soninke',
 				'so' => 'somalski',
 				'sog' => 'sogdien',
 				'sq' => 'albanski',
 				'sr' => 'srpski',
 				'srn' => 'srananski tongo',
 				'srr' => 'serer',
 				'ss' => 'svati',
 				'ssy' => 'saho',
 				'st' => 'južni soto',
 				'su' => 'sundanski',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerski',
 				'sv' => 'švedski',
 				'sw' => 'svahili',
 				'swb' => 'komorski',
 				'syc' => 'klasični sirijski',
 				'syr' => 'sirijski',
 				'ta' => 'tamilski',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadžički',
 				'th' => 'tajlandski',
 				'ti' => 'tigrinja',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turkmenski',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonski',
 				'tli' => 'tlingit',
 				'tmh' => 'tamašek',
 				'tn' => 'tsvana',
 				'to' => 'tonganski',
 				'tog' => 'njasa tonga',
 				'tpi' => 'tok pisin',
 				'tr' => 'turski',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimšian',
 				'tt' => 'tatarski',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'tvi',
 				'twq' => 'tasavak',
 				'ty' => 'tahićanski',
 				'tyv' => 'tuvinijski',
 				'tzm' => 'centralnoatlaski tamazigt',
 				'udm' => 'udmurt',
 				'ug' => 'ujgurski',
 				'uga' => 'ugaritski',
 				'uk' => 'ukrajinski',
 				'umb' => 'umbundu',
 				'und' => 'nepoznati jezik',
 				'ur' => 'urdu',
 				'uz' => 'uzbečki',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vijetnamski',
 				'vo' => 'volapuk',
 				'vot' => 'votski',
 				'vun' => 'vunjo',
 				'wa' => 'valun',
 				'wae' => 'valser',
 				'wal' => 'valamo',
 				'war' => 'varej',
 				'was' => 'vašo',
 				'wbp' => 'varlpiri',
 				'wo' => 'volof',
 				'xal' => 'kalmik',
 				'xh' => 'hosa',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japeški',
 				'yav' => 'jangben',
 				'ybb' => 'jemba',
 				'yi' => 'jidiš',
 				'yo' => 'jorubanski',
 				'yue' => 'kantonski',
 				'za' => 'zuang',
 				'zap' => 'zapotečki',
 				'zbl' => 'blis simboli',
 				'zen' => 'zenaga',
 				'zgh' => 'standardni marokanski tamazigt',
 				'zh' => 'kineski',
 				'zh_Hans' => 'kineski (pojednostavljeni)',
 				'zh_Hant' => 'kineski (tradicionalni)',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'bez lingvističkog sadržaja',
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
			'Afak' => 'afaka pismo',
 			'Arab' => 'arapsko pismo',
 			'Arab@alt=variant' => 'perzijsko-arapsko pismo',
 			'Armi' => 'imperijsko aramejsko pismo',
 			'Armn' => 'armensko pismo',
 			'Avst' => 'avestansko pismo',
 			'Bali' => 'balijsko pismo',
 			'Bamu' => 'bamum pismo',
 			'Bass' => 'bassa vah pismo',
 			'Batk' => 'batak pismo',
 			'Beng' => 'bengalsko pismo',
 			'Blis' => 'blisimbolično pismo',
 			'Bopo' => 'pismo bopomofo',
 			'Brah' => 'bramansko pismo',
 			'Brai' => 'brajevo pismo',
 			'Bugi' => 'buginsko pismo',
 			'Buhd' => 'buhidsko pismo',
 			'Cakm' => 'čakmansko pismo',
 			'Cans' => 'Ujedinjeni kanadski aboridžinski silabici',
 			'Cari' => 'karijsko pismo',
 			'Cham' => 'čamsko pismo',
 			'Cher' => 'čeroki',
 			'Cirt' => 'cirt pismo',
 			'Copt' => 'koptičko pismo',
 			'Cprt' => 'kiparsko pismo',
 			'Cyrl' => 'ćirilica',
 			'Cyrs' => 'Staroslovenska crkvena ćirilica',
 			'Deva' => 'pismo devanagari',
 			'Dsrt' => 'dezeret',
 			'Egyd' => 'egipatsko narodno pismo',
 			'Egyh' => 'egipatsko hijeratsko pismo',
 			'Egyp' => 'egipatski hijeroglifi',
 			'Ethi' => 'etiopsko pismo',
 			'Geok' => 'gruzijsko khutsuri pismo',
 			'Geor' => 'gruzijsko pismo',
 			'Glag' => 'glagoljica',
 			'Goth' => 'gotika',
 			'Gran' => 'grantha pismo',
 			'Grek' => 'grčko pismo',
 			'Gujr' => 'pismo gudžarati',
 			'Guru' => 'pismo gurmuki',
 			'Hanb' => 'pismo hanb',
 			'Hang' => 'pismo hangul',
 			'Hani' => 'pismo han',
 			'Hano' => 'hanuno pismo',
 			'Hans' => 'pojednostavljeno',
 			'Hans@alt=stand-alone' => 'pojednostavljeno pismo han',
 			'Hant' => 'tradicionalno',
 			'Hant@alt=stand-alone' => 'tradicionalno pismo han',
 			'Hebr' => 'hebrejsko pismo',
 			'Hira' => 'pismo hiragana',
 			'Hluw' => 'anatolijski hijeroglifi',
 			'Hmng' => 'pahawh hmong pismo',
 			'Hrkt' => 'katakana ili hiragana',
 			'Hung' => 'Staromađarsko pismo',
 			'Inds' => 'induško ismo',
 			'Ital' => 'staro italsko pismo',
 			'Jamo' => 'pismo jamo',
 			'Java' => 'javansko pismo',
 			'Jpan' => 'japansko pismo',
 			'Jurc' => 'jurchen pismo',
 			'Kali' => 'kajah li pismo',
 			'Kana' => 'pismo katakana',
 			'Khar' => 'karošti pismo',
 			'Khmr' => 'kmersko pismo',
 			'Khoj' => 'khojki pismo',
 			'Knda' => 'pismo kanada',
 			'Kore' => 'korejsko pismo',
 			'Kpel' => 'kpelle pismo',
 			'Kthi' => 'kaićansko pismo',
 			'Lana' => 'lanna pismo',
 			'Laoo' => 'laosko pismo',
 			'Latf' => 'latinica (fraktur varijanta)',
 			'Latg' => 'galska latinica',
 			'Latn' => 'latinica',
 			'Lepc' => 'lepča pismo',
 			'Limb' => 'limbu pismo',
 			'Lina' => 'linearno A pismo',
 			'Linb' => 'linearno B pismo',
 			'Lisu' => 'fraser pismo',
 			'Loma' => 'loma pismo',
 			'Lyci' => 'lisijsko pismo',
 			'Lydi' => 'lidijsko pismo',
 			'Mand' => 'mandeansko pismo',
 			'Mani' => 'manihejsko pismo',
 			'Maya' => 'majanski hijeroglifi',
 			'Mend' => 'mende pismo',
 			'Merc' => 'meroitski kurziv',
 			'Mero' => 'meroitik pismo',
 			'Mlym' => 'malajalamsko pismo',
 			'Mong' => 'mongolsko pismo',
 			'Moon' => 'mesečevo pismo',
 			'Mroo' => 'mro pismo',
 			'Mtei' => 'meitei majek pismo',
 			'Mymr' => 'mijanmarsko pismo',
 			'Narb' => 'staro sjevernoarapsko pismo',
 			'Nbat' => 'nabatejsko pismo',
 			'Nkgb' => 'naxi geba pismo',
 			'Nkoo' => 'n’ko pismo',
 			'Nshu' => 'nushu pismo',
 			'Ogam' => 'ogham pismo',
 			'Olck' => 'ol čiki pismo',
 			'Orkh' => 'orkhon pismo',
 			'Orya' => 'pismo orija',
 			'Osma' => 'osmanja pismo',
 			'Palm' => 'palmyrene pismo',
 			'Perm' => 'staro permiksko pismo',
 			'Phag' => 'phags-pa pismo',
 			'Phli' => 'pisani pahlavi',
 			'Phlp' => 'psalter pahlavi',
 			'Phlv' => 'pahlavi pismo',
 			'Phnx' => 'feničansko pismo',
 			'Plrd' => 'polard fonetsko pismo',
 			'Prti' => 'pisani partian',
 			'Rjng' => 'rejang pismo',
 			'Roro' => 'rongorongo pismo',
 			'Runr' => 'runsko pismo',
 			'Samr' => 'samaritansko pismo',
 			'Sara' => 'sarati pismo',
 			'Sarb' => 'staro južnoarapsko pismo',
 			'Saur' => 'sauraštra pismo',
 			'Sgnw' => 'znakovno pismo',
 			'Shaw' => 'šavian pismo',
 			'Shrd' => 'sharada pismo',
 			'Sind' => 'khudawadi pismo',
 			'Sinh' => 'pismo sinhala',
 			'Sora' => 'sora sompeng pismo',
 			'Sylo' => 'siloti nagri pismo',
 			'Syrc' => 'sirijsko pismo',
 			'Syre' => 'sirijsko estrangelo pismo',
 			'Syrj' => 'zapadnosirijsko pismo',
 			'Syrn' => 'pismo istočne Sirije',
 			'Tagb' => 'tagbanva pismo',
 			'Takr' => 'takri pismo',
 			'Tale' => 'tai le pismo',
 			'Talu' => 'novo tai lue pismo',
 			'Taml' => 'tamilsko pismo',
 			'Tang' => 'tangut pismo',
 			'Tavt' => 'tai viet pismo',
 			'Telu' => 'pismo telugu',
 			'Teng' => 'tengvar pismo',
 			'Tfng' => 'tifinag pismo',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'pismo tana',
 			'Thai' => 'tajlandsko pismo',
 			'Tibt' => 'tibetansko pismo',
 			'Tirh' => 'tirhuta pismo',
 			'Ugar' => 'ugaritsko pismo',
 			'Vaii' => 'vai pismo',
 			'Visp' => 'vidljivi govor',
 			'Wara' => 'varang kshiti pismo',
 			'Wole' => 'woleai pismo',
 			'Xpeo' => 'staropersijsko pismo',
 			'Xsux' => 'sumersko-akadsko kuneiform pismo',
 			'Yiii' => 'ji pismo',
 			'Zinh' => 'nasledno pismo',
 			'Zmth' => 'matematička notacija',
 			'Zsye' => 'emoji sličice',
 			'Zsym' => 'simboli',
 			'Zxxx' => 'nepisani jezik',
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
 			'003' => 'Sjeverna Amerika',
 			'005' => 'Južna Amerika',
 			'009' => 'Okeanija',
 			'011' => 'Zapadna Afrika',
 			'013' => 'Srednja Amerika',
 			'014' => 'Istočna Afrika',
 			'015' => 'Sjeverna Afrika',
 			'017' => 'Srednja Afrika',
 			'018' => 'Južna Afrika',
 			'019' => 'Amerika',
 			'021' => 'Sjeverni dio Amerike',
 			'029' => 'Karibi',
 			'030' => 'Istočna Azija',
 			'034' => 'Južna Azija',
 			'035' => 'Jugoistočna Azija',
 			'039' => 'Južna Evropa',
 			'053' => 'Australazija',
 			'054' => 'Melanezija',
 			'057' => 'Mikronezijska regija',
 			'061' => 'Polinezija',
 			'142' => 'Azija',
 			'143' => 'Srednja Azija',
 			'145' => 'Zapadna Azija',
 			'150' => 'Evropa',
 			'151' => 'Istočna Evropa',
 			'154' => 'Sjeverna Evropa',
 			'155' => 'Zapadna Evropa',
 			'202' => 'Subsaharska Afrika',
 			'419' => 'Latinska Amerika',
 			'AC' => 'Ostrvo Ascension',
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
 			'AX' => 'Olandska ostrva',
 			'AZ' => 'Azerbejdžan',
 			'BA' => 'Bosna i Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgija',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bugarska',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sveti Bartolomej',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunej',
 			'BO' => 'Bolivija',
 			'BQ' => 'Karipska Holandija',
 			'BR' => 'Brazil',
 			'BS' => 'Bahami',
 			'BT' => 'Butan',
 			'BV' => 'Ostrvo Buve',
 			'BW' => 'Bocvana',
 			'BY' => 'Bjelorusija',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosova (Keelingova) ostrva',
 			'CD' => 'Demokratska Republika Kongo',
 			'CD@alt=variant' => 'DR Kongo',
 			'CF' => 'Centralnoafrička Republika',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Republika Kongo',
 			'CH' => 'Švicarska',
 			'CI' => 'Obala Slonovače',
 			'CI@alt=variant' => 'Obala Bjelokosti',
 			'CK' => 'Kukova ostrva',
 			'CL' => 'Čile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Kolumbija',
 			'CP' => 'Ostrvo Kliperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kape Verde',
 			'CW' => 'Kurasao',
 			'CX' => 'Božićno ostrvo',
 			'CY' => 'Kipar',
 			'CZ' => 'Češka',
 			'CZ@alt=variant' => 'Češka Republika',
 			'DE' => 'Njemačka',
 			'DG' => 'Dijego Garsija',
 			'DJ' => 'Džibuti',
 			'DK' => 'Danska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikanska Republika',
 			'DZ' => 'Alžir',
 			'EA' => 'Seuta i Melilja',
 			'EC' => 'Ekvador',
 			'EE' => 'Estonija',
 			'EG' => 'Egipat',
 			'EH' => 'Zapadna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Španija',
 			'ET' => 'Etiopija',
 			'EU' => 'Evropska unija',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finska',
 			'FJ' => 'Fidži',
 			'FK' => 'Folklandska ostrva',
 			'FK@alt=variant' => 'Folklandska (Malvinska) ostrva',
 			'FM' => 'Mikronezija',
 			'FO' => 'Farska ostrva',
 			'FR' => 'Francuska',
 			'GA' => 'Gabon',
 			'GB' => 'Velika Britanija',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzija',
 			'GF' => 'Francuska Gvajana',
 			'GG' => 'Gernzi',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grenland',
 			'GM' => 'Gambija',
 			'GN' => 'Gvineja',
 			'GP' => 'Gvadalupe',
 			'GQ' => 'Ekvatorijalna Gvineja',
 			'GR' => 'Grčka',
 			'GS' => 'Južna Džordžija i Južna Sendvič ostrva',
 			'GT' => 'Gvatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gvineja-Bisao',
 			'GY' => 'Gvajana',
 			'HK' => 'Hong Kong (SAR Kina)',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Herd i arhipelag MekDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Hrvatska',
 			'HT' => 'Haiti',
 			'HU' => 'Mađarska',
 			'IC' => 'Kanarska ostrva',
 			'ID' => 'Indonezija',
 			'IE' => 'Irska',
 			'IL' => 'Izrael',
 			'IM' => 'Ostrvo Man',
 			'IN' => 'Indija',
 			'IO' => 'Britanska Teritorija u Indijskom Okeanu',
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
 			'KN' => 'Sveti Kits i Nevis',
 			'KP' => 'Sjeverna Koreja',
 			'KR' => 'Južna Koreja',
 			'KW' => 'Kuvajt',
 			'KY' => 'Kajmanska ostrva',
 			'KZ' => 'Kazahstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Sveta Lucija',
 			'LI' => 'Lihtenštajn',
 			'LK' => 'Šri Lanka',
 			'LR' => 'Liberija',
 			'LS' => 'Lesoto',
 			'LT' => 'Litvanija',
 			'LU' => 'Luksemburg',
 			'LV' => 'Latvija',
 			'LY' => 'Libija',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavija',
 			'ME' => 'Crna Gora',
 			'MF' => 'Sveti Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Maršalova ostrva',
 			'MK' => 'Makedonija',
 			'MK@alt=variant' => 'Makedonija (BJR)',
 			'ML' => 'Mali',
 			'MM' => 'Mjanmar',
 			'MN' => 'Mongolija',
 			'MO' => 'Makao (SAR Kina)',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Sjeverna Marijanska ostrva',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritanija',
 			'MS' => 'Monserat',
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
 			'NF' => 'Ostrvo Norfolk',
 			'NG' => 'Nigerija',
 			'NI' => 'Nikaragva',
 			'NL' => 'Holandija',
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
 			'PN' => 'Pitkernska Ostrva',
 			'PR' => 'Porto Riko',
 			'PS' => 'Palestinska Teritorija',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paragvaj',
 			'QA' => 'Katar',
 			'QO' => 'Vanjska Okeanija',
 			'RE' => 'Reunion',
 			'RO' => 'Rumunija',
 			'RS' => 'Srbija',
 			'RU' => 'Rusija',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudijska Arabija',
 			'SB' => 'Solomonska Ostrva',
 			'SC' => 'Sejšeli',
 			'SD' => 'Sudan',
 			'SE' => 'Švedska',
 			'SG' => 'Singapur',
 			'SH' => 'Sveta Helena',
 			'SI' => 'Slovenija',
 			'SJ' => 'Svalbard i Jan Majen',
 			'SK' => 'Slovačka',
 			'SL' => 'Sijera Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinam',
 			'SS' => 'Južni Sudan',
 			'ST' => 'Sao Tome i Principe',
 			'SV' => 'Salvador',
 			'SX' => 'Sint Marten',
 			'SY' => 'Sirija',
 			'SZ' => 'Svazilend',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Ostrva Turks i Kaikos',
 			'TD' => 'Čad',
 			'TF' => 'Francuske Južne Teritorije',
 			'TG' => 'Togo',
 			'TH' => 'Tajland',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Istočni Timor',
 			'TL@alt=variant' => 'TL',
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
 			'UM' => 'Američka Vanjska Ostrva',
 			'UN' => 'Ujedinjene Nacije',
 			'UN@alt=short' => 'UN',
 			'US' => 'Sjedinjene Američke Države',
 			'US@alt=short' => 'SAD',
 			'UY' => 'Urugvaj',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Sveti Vinsent i Grenadin',
 			'VE' => 'Venecuela',
 			'VG' => 'Britanska Djevičanska ostrva',
 			'VI' => 'Američka Djevičanska ostrva',
 			'VN' => 'Vijetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Ostrva Valis i Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Majote',
 			'ZA' => 'Južnoafrička Republika',
 			'ZM' => 'Zambija',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Nepoznata oblast',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Tradicionalna nemačka ortografija',
 			'1994' => 'Standardizovana rezijanska ortografija',
 			'1996' => 'Nemačka ortografija 1996',
 			'1606NICT' => 'Francuski iz kasnog srednjeg veka do 1606.',
 			'1694ACAD' => 'Rani moderni francuski',
 			'1959ACAD' => 'Akademski',
 			'ALUKU' => 'aluku dijalekt',
 			'AREVELA' => 'Istočni jermenski',
 			'AREVMDA' => 'Zapadno-jermenski',
 			'BAKU1926' => 'Ujedinjeni turski latinični alfabet',
 			'BISKE' => 'San Đorđijo/Bila dijalekt',
 			'BOONT' => 'Buntling',
 			'EMODENG' => 'rani moderni engleski',
 			'FONIPA' => 'IPA fonetika',
 			'FONUPA' => 'UPA fonetika',
 			'KKCOR' => 'Uobičajena ortografija',
 			'KSCOR' => 'standardna ortografija',
 			'LIPAW' => 'Lipovac dijalekt rezijanski',
 			'METELKO' => 'metelčica',
 			'MONOTON' => 'Monotonik',
 			'NEDIS' => 'Natison dijalekt',
 			'NJIVA' => 'Gnjiva/Njiva dijalekt',
 			'NULIK' => 'moderni volapuk',
 			'OSOJS' => 'Oseako/Osojane dijalekt',
 			'PAMAKA' => 'pamaka dijalekt',
 			'PINYIN' => 'Pinjinska romanizacija',
 			'POLYTON' => 'Politonik',
 			'POSIX' => 'Kompjuter',
 			'REVISED' => 'Revidirana ortigrafija',
 			'ROZAJ' => 'Rezijan',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Škotski standardni engleski',
 			'SCOUSE' => 'Skauz',
 			'SOLBA' => 'Stolvica/Solbica dijalekt',
 			'TARASK' => 'Taraskijevica ortografija',
 			'UCCOR' => 'Ujedinjena ortografija',
 			'UCRCOR' => 'Ujedinjena revidirana ortografija',
 			'VALENCIA' => 'Valencijski',
 			'WADEGILE' => 'Vejd-Žajl romanizacija',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Kalendar',
 			'cf' => 'Format valute',
 			'colalternate' => 'Zanemarivanje poredavanja simbola',
 			'colbackwards' => 'Obrnuto poredavanje po naglasku',
 			'colcasefirst' => 'Poredavanje po velikim/malim slovima',
 			'colcaselevel' => 'Poredavanje u skladu s veličinom slova',
 			'collation' => 'Sortiranje',
 			'colnormalization' => 'Normalizirano poredavanje',
 			'colnumeric' => 'Numeričko poredavanje',
 			'colstrength' => 'Jačina poredavanja',
 			'currency' => 'Valuta',
 			'hc' => 'Format vremena (12 ili 24)',
 			'lb' => 'Stil prijeloma reda',
 			'ms' => 'Mjerni sistem',
 			'numbers' => 'Brojevi',
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
 				'indian' => q{Indijski nacionalni kalendar},
 				'islamic' => q{islamski kalendar},
 				'islamic-civil' => q{Islamski civilni kalendar},
 				'iso8601' => q{kalendar ISO-8601},
 				'japanese' => q{japanski kalendar},
 				'persian' => q{perzijski kalendar},
 				'roc' => q{kalendar Republike Kine},
 			},
 			'cf' => {
 				'account' => q{računovodstveni format valute},
 				'standard' => q{standardni format valute},
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
 				'big5han' => q{Tradicionalno kinesko sortiranje},
 				'dictionary' => q{rječničko razvrstavanje},
 				'ducet' => q{standardno Unicode sortiranje},
 				'gb2312han' => q{Pojednostavljeno kinesko sortiranje},
 				'phonebook' => q{Sortiranje kao telefonski imenik},
 				'phonetic' => q{Fonetski poredak},
 				'pinyin' => q{Pinjin sortiranje},
 				'reformed' => q{reformirano razvrstavanje},
 				'search' => q{općenito pretraživanje},
 				'searchjl' => q{Pretraživanje po početnom suglasniku hangula},
 				'standard' => q{standardno sortiranje},
 				'stroke' => q{Sortiranje po broju crta},
 				'traditional' => q{Tradicionalno sortiranje},
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
 				'loose' => q{Slobodni stil prijeloma reda},
 				'normal' => q{Normalni stil prijeloma reda},
 				'strict' => q{Strogi stil prijeloma reda},
 			},
 			'm0' => {
 				'bgn' => q{US BGN transliteracija},
 				'ungegn' => q{UN GEGN transliteracija},
 			},
 			'ms' => {
 				'metric' => q{metrički sistem},
 				'uksystem' => q{britanski mjerni sistem},
 				'ussystem' => q{američki mjerni sistem},
 			},
 			'numbers' => {
 				'arab' => q{arapsko-indijski brojevi},
 				'arabext' => q{prošireni arapsko-indijski brojevi},
 				'armn' => q{armenski brojevi},
 				'armnlow' => q{mali armenski brojevi},
 				'beng' => q{bengalski brojevi},
 				'deva' => q{brojevi pisma devanagari},
 				'ethi' => q{etiopski brojevi},
 				'finance' => q{Financijski brojevi},
 				'fullwide' => q{široki brojevi},
 				'geor' => q{gruzijski brojevi},
 				'grek' => q{grčki brojevi},
 				'greklow' => q{mali grčki brojevi},
 				'gujr' => q{brojevi pisma gudžarati},
 				'guru' => q{brojevi pisma gurmuki},
 				'hanidec' => q{kineski decimalni brojevi},
 				'hans' => q{pojednostavljeni kineski brojevi},
 				'hansfin' => q{pojednostavljeni kineski finansijski brojevi},
 				'hant' => q{tradicionalni kineski brojevi},
 				'hantfin' => q{tradicionalni kineski finansijski brojevi},
 				'hebr' => q{hebrejski brojevi},
 				'jpan' => q{japanski brojevi},
 				'jpanfin' => q{japanski finansijski brojevi},
 				'khmr' => q{kmerski brojevi},
 				'knda' => q{brojevi pisma kanada},
 				'laoo' => q{laoski brojevi},
 				'latn' => q{arapski brojevi},
 				'mlym' => q{malajalamski brojevi},
 				'mong' => q{Mongolske znamenke},
 				'mymr' => q{mijanmarski brojevi},
 				'native' => q{Izvorne znamenke},
 				'orya' => q{orijski brojevi},
 				'roman' => q{rimski brojevi},
 				'romanlow' => q{mali rimski brojevi},
 				'taml' => q{tradicionalni tamilski brojevi},
 				'tamldec' => q{tamilski brojevi},
 				'telu' => q{brojevi pisma telugu},
 				'thai' => q{tajlandski brojevi},
 				'tibt' => q{tibetanski brojevi},
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
			'metric' => q{metrički},
 			'UK' => q{britanski},
 			'US' => q{američki},

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
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŽ}', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', '{LJ}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a b c č ć d {dž} đ e f g h i j k l {lj} m n {nj} o p r s š t u v z ž]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] @ * / ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŽ}', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', '{LJ}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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
						'few' => q({0} jutar-stope),
						'name' => q(jutar-stope),
						'one' => q({0} jutar-stopa),
						'other' => q({0} jutar-stopa),
					},
					'ampere' => {
						'few' => q({0} ampera),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} ampera),
					},
					'arc-minute' => {
						'few' => q({0} ugaona minuta),
						'name' => q(ugaone minute),
						'one' => q({0} ugaona minuta),
						'other' => q({0} ugaonih minuta),
					},
					'arc-second' => {
						'few' => q({0} ugaone sekunde),
						'name' => q(ugaone sekunde),
						'one' => q({0} ugaona sekunda),
						'other' => q({0} ugaonih sekundi),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomske jedinice),
						'name' => q(astronomske jedinice),
						'one' => q({0} astronomska jedinica),
						'other' => q({0} astronomskih jedinica),
					},
					'bit' => {
						'few' => q({0} bita),
						'name' => q(biti),
						'one' => q({0} bit),
						'other' => q({0} bita),
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
						'few' => q({0} stepena Celzijusa),
						'name' => q(stepeni Celzijusa),
						'one' => q({0} stepen Celzijusa),
						'other' => q({0} stepeni Celzijusa),
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
						'per' => q({0} po centimetru),
					},
					'century' => {
						'few' => q({0} stoljeća),
						'name' => q(stoljeća),
						'one' => q({0} stoljeće),
						'other' => q({0} stoljeća),
					},
					'coordinate' => {
						'east' => q({0} istok),
						'north' => q({0} sjever),
						'south' => q({0} jug),
						'west' => q({0} zapad),
					},
					'cubic-centimeter' => {
						'few' => q({0} kubna centimetra),
						'name' => q(kubni centimetri),
						'one' => q({0} kubni centimetar),
						'other' => q({0} kubnih centimetara),
						'per' => q({0} po kubnom centimetru),
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
						'per' => q({0} po kubnom metru),
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
						'other' => q({0} kubnih jarda),
					},
					'cup' => {
						'few' => q({0} šolje),
						'name' => q(šolje),
						'one' => q({0} šolja),
						'other' => q({0} šolja),
					},
					'cup-metric' => {
						'few' => q({0} metričke šolje),
						'name' => q(metričke šolje),
						'one' => q({0} metrička šolja),
						'other' => q({0} metričkih šolja),
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
						'few' => q({0} stepena),
						'name' => q(stepeni),
						'one' => q({0} stepen),
						'other' => q({0} stepeni),
					},
					'fahrenheit' => {
						'few' => q({0} stepena Farenhajta),
						'name' => q(stepeni Farenhajta),
						'one' => q({0} stepen Farenhajta),
						'other' => q({0} stepeni Farenhajta),
					},
					'fluid-ounce' => {
						'few' => q({0} tečne unce),
						'name' => q(tečne unce),
						'one' => q({0} tečna unca),
						'other' => q({0} tečnih unci),
					},
					'foodcalorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					'foot' => {
						'few' => q({0} stope),
						'name' => q(stope),
						'one' => q({0} stopa),
						'other' => q({0} stopa),
						'per' => q({0} po stopi),
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
						'per' => q({0} po galonu),
					},
					'gallon-imperial' => {
						'few' => q({0} brit. galona),
						'name' => q(Brit. galoni),
						'one' => q({0} brit. galon),
						'other' => q({0} brit. galona),
						'per' => q({0} po brit. galonu),
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
						'per' => q({0} po gramu),
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
						'per' => q({0} na sat),
					},
					'inch' => {
						'few' => q({0} inča),
						'name' => q(inči),
						'one' => q({0} inč),
						'other' => q({0} inča),
						'per' => q({0} po inču),
					},
					'inch-hg' => {
						'few' => q({0} inča živinog stuba),
						'name' => q(inči živinog stuba),
						'one' => q({0} inč živinog stuba),
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
						'per' => q({0} po kilogramu),
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
						'per' => q({0} po kilometru),
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
						'few' => q({0} kilovat-sata),
						'name' => q(kilovat-sat),
						'one' => q({0} kilovat-sat),
						'other' => q({0} kilovat-sati),
					},
					'knot' => {
						'few' => q({0} čvora),
						'name' => q(čvorovi),
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
						'few' => q({0} litra),
						'name' => q(litri),
						'one' => q({0} litar),
						'other' => q({0} litara),
						'per' => q({0} po litru),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} litara na 100 kilometara),
						'name' => q(litri na 100 kilometara),
						'one' => q({0} litar na 100 kilometara),
						'other' => q({0} litara na 100 kilometara),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litra po kilometru),
						'name' => q(litri po kilometru),
						'one' => q({0} litar po kilometru),
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
						'one' => q({0} megabajta),
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
						'per' => q({0} po metru),
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
						'few' => q({0} metričke tone),
						'name' => q(metričke tone),
						'one' => q({0} metrička tona),
						'other' => q({0} metričkih tona),
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
						'few' => q({0} milje po brit. galonu),
						'name' => q(milje po brit. galonu),
						'one' => q({0} milja po brit. galonu),
						'other' => q({0} milja po brit. galonu),
					},
					'mile-per-hour' => {
						'few' => q({0} milje na sat),
						'name' => q(milje na sat),
						'one' => q({0} milja na sat),
						'other' => q({0} milja na sat),
					},
					'mile-scandinavian' => {
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavske milje),
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
						'few' => q({0} milimetra živinog stuba),
						'name' => q(milimetri živinog stuba),
						'one' => q({0} milimetar živinog stuba),
						'other' => q({0} milimetara živinog stuba),
					},
					'millimole-per-liter' => {
						'few' => q({0} milimola po litru),
						'name' => q(milimoli po litru),
						'one' => q({0} milimol po litru),
						'other' => q({0} milimola po litru),
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
						'per' => q({0} po minuti),
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
						'per' => q({0} po unci),
					},
					'ounce-troy' => {
						'few' => q({0} fine unce),
						'name' => q(fine unce),
						'one' => q({0} fina unca),
						'other' => q({0} finih unci),
					},
					'parsec' => {
						'few' => q({0} parseka),
						'name' => q(parseci),
						'one' => q({0} parsek),
						'other' => q({0} parseka),
					},
					'part-per-million' => {
						'few' => q({0} dijela na milion),
						'name' => q(dijelovi na milion),
						'one' => q({0} dio na milion),
						'other' => q({0} dijelova na milion),
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
						'few' => q({0} tč),
						'name' => q(tačke),
						'one' => q({0} tačka),
						'other' => q({0} tačaka),
					},
					'pound' => {
						'few' => q({0} funte),
						'name' => q(funte),
						'one' => q({0} funta),
						'other' => q({0} funti),
						'per' => q({0} po funti),
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
						'few' => q({0} okreta),
						'name' => q(okret),
						'one' => q({0} okret),
						'other' => q({0} okreta),
					},
					'second' => {
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
						'per' => q({0} po sekundi),
					},
					'square-centimeter' => {
						'few' => q({0} kvadratna centimetra),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimetar),
						'other' => q({0} kvadratnih centimetara),
						'per' => q({0} po kvadratnom centimetru),
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
						'per' => q({0} po kvadratnom inču),
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
						'per' => q({0} po kvadratnom metru),
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
						'other' => q({0} kvadratnih jarda),
					},
					'tablespoon' => {
						'few' => q({0} kašike),
						'name' => q(kašike),
						'one' => q({0} kašika),
						'other' => q({0} kašika),
					},
					'teaspoon' => {
						'few' => q({0} kašičice),
						'name' => q(kašičice),
						'one' => q({0} kašičica),
						'other' => q({0} kašičica),
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
						'few' => q({0} tone),
						'name' => q(tone),
						'one' => q({0} tona),
						'other' => q({0} tona),
					},
					'volt' => {
						'few' => q({0} volta),
						'name' => q(volti),
						'one' => q({0} volt),
						'other' => q({0} volta),
					},
					'watt' => {
						'few' => q({0} vata),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vata),
					},
					'week' => {
						'few' => q({0} sedmice),
						'name' => q(sedmice),
						'one' => q({0} sedmica),
						'other' => q({0} sedmica),
						'per' => q({0} sedmično),
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
					'celsius' => {
						'few' => q({0}°),
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
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
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'few' => q({0} d.),
						'name' => q(dan),
						'one' => q({0} d.),
						'other' => q({0} d.),
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
					'foot' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gram' => {
						'few' => q({0} g),
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'few' => q({0} KS),
						'one' => q({0} KS),
						'other' => q({0} KS),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(sat),
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
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
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
					'light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'few' => q({0}l),
						'name' => q(litar),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} L/100 km),
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(metar),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'few' => q({0} mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'millibar' => {
						'few' => q({0} mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(milisekunda),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'few' => q({0} m),
						'name' => q(minuta),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'month' => {
						'few' => q({0} mj.),
						'name' => q(mjesec),
						'one' => q({0} mj.),
						'other' => q({0} mj.),
					},
					'ounce' => {
						'few' => q({0} oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'few' => q({0} pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					'second' => {
						'few' => q({0} s),
						'name' => q(sekunda),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
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
					'watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} sedm.),
						'name' => q(sedm.),
						'one' => q({0} sedm.),
						'other' => q({0} sedm.),
					},
					'yard' => {
						'few' => q({0} yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} god.),
						'name' => q(god.),
						'one' => q({0} god.),
						'other' => q({0} god.),
					},
				},
				'short' => {
					'acre' => {
						'few' => q({0} kj),
						'name' => q(katastarska jutra),
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
						'name' => q(amperi),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'name' => q(ugaone minute),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'name' => q(ugaone sekunde),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} aj),
						'name' => q(aj),
						'one' => q({0} aj),
						'other' => q({0} aj),
					},
					'bit' => {
						'few' => q({0} bit),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'few' => q({0} bajt),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					'calorie' => {
						'few' => q({0} kal.),
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					'carat' => {
						'few' => q({0} CD),
						'name' => q(karati),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'few' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'few' => q({0} cL),
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
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
						'east' => q({0} I),
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
						'name' => q(šolje),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'few' => q({0} mc),
						'name' => q(mcup),
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
						'few' => q({0} dL),
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'name' => q(stepeni),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0}°F),
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} kal.),
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					'foot' => {
						'few' => q({0} ft),
						'name' => q(stope),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
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
						'few' => q({0} b. gal),
						'name' => q(B. gal),
						'one' => q({0} b. gal),
						'other' => q({0} b. gal),
						'per' => q({0}/b. gal),
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
						'name' => q(grami),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'name' => q(hektari),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hL),
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
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
						'few' => q({0} ks),
						'name' => q(ks),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(sati),
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
						'name' => q(in Hg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'name' => q(džuli),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'name' => q(karati),
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
						'name' => q(kilodžul),
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
						'name' => q(kW-sat),
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
						'few' => q({0} sg),
						'name' => q(svjetlosne godine),
						'one' => q({0} sg),
						'other' => q({0} sg),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(litri),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} L/100 km),
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} L/km),
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'name' => q(luks),
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
						'few' => q({0} ML),
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'name' => q(metri),
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
						'name' => q(mikrosekunde),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'name' => q(milje),
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
						'few' => q({0} mi/b. gal),
						'name' => q(milje/b. gal),
						'one' => q({0} mi/b. gal),
						'other' => q({0} mi/b. gal),
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
						'few' => q({0} mg/dL),
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'few' => q({0} mL),
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
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
						'few' => q({0} mmol/L),
						'name' => q(milimol/litar),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(milisekunde),
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
						'few' => q({0} min.),
						'name' => q(minute),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					'month' => {
						'few' => q({0} mj.),
						'name' => q(mjeseci),
						'one' => q({0} mj.),
						'other' => q({0} mj.),
						'per' => q({0} mj.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'name' => q(nanosekunde),
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
						'name' => q(omi),
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
						'name' => q(parseci),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'few' => q({0} ppm),
						'name' => q(dijelovi/milion),
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
						'name' => q(pinte),
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
						'few' => q({0} tč),
						'name' => q(tč),
						'one' => q({0} tč),
						'other' => q({0} tč),
					},
					'pound' => {
						'few' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lbs),
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
						'name' => q(radijani),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'few' => q({0} okr.),
						'name' => q(okret),
						'one' => q({0} okr.),
						'other' => q({0} okr.),
					},
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sekunde),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
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
						'name' => q(tone),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'few' => q({0} V),
						'name' => q(volti),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'name' => q(vati),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} sedm.),
						'name' => q(sedmice),
						'one' => q({0} sedm.),
						'other' => q({0} sedm.),
						'per' => q({0}/sedm.),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(jardi),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} god.),
						'name' => q(godine),
						'one' => q({0} god.),
						'other' => q({0} god.),
						'per' => q({0}/god.),
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
				end => q({0} i {1}),
				2 => q({0} i {1}),
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
					'few' => '0 hilj'.'',
					'one' => '0 hilj'.'',
					'other' => '0 hilj'.'',
				},
				'10000' => {
					'few' => '00 hilj'.'',
					'one' => '00 hilj'.'',
					'other' => '00 hilj'.'',
				},
				'100000' => {
					'few' => '000 hilj'.'',
					'one' => '000 hilj'.'',
					'other' => '000 hilj'.'',
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
					'few' => '0 hiljade',
					'one' => '0 hiljada',
					'other' => '0 hiljada',
				},
				'10000' => {
					'few' => '00 hiljade',
					'one' => '00 hiljada',
					'other' => '00 hiljada',
				},
				'100000' => {
					'few' => '000 hiljade',
					'one' => '000 hiljada',
					'other' => '000 hiljada',
				},
				'1000000' => {
					'few' => '0 miliona',
					'one' => '0 milion',
					'other' => '0 miliona',
				},
				'10000000' => {
					'few' => '00 miliona',
					'one' => '00 milion',
					'other' => '00 miliona',
				},
				'100000000' => {
					'few' => '000 miliona',
					'one' => '000 milion',
					'other' => '000 miliona',
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
					'few' => '0 biliona',
					'one' => '0 bilion',
					'other' => '0 biliona',
				},
				'10000000000000' => {
					'few' => '00 biliona',
					'one' => '00 bilion',
					'other' => '00 biliona',
				},
				'100000000000000' => {
					'few' => '000 biliona',
					'one' => '000 bilion',
					'other' => '000 biliona',
				},
			},
			'short' => {
				'1000' => {
					'few' => '0 hilj'.'',
					'one' => '0 hilj'.'',
					'other' => '0 hilj'.'',
				},
				'10000' => {
					'few' => '00 hilj'.'',
					'one' => '00 hilj'.'',
					'other' => '00 hilj'.'',
				},
				'100000' => {
					'few' => '000 hilj'.'',
					'one' => '000 hilj'.'',
					'other' => '000 hilj'.'',
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
				'currency' => q(Andorska pezeta),
				'few' => q(Andorijske pezete),
				'one' => q(Andorijska pezeta),
				'other' => q(Andorijske pezete),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham Ujedinjenih Arapskih Emirata),
				'few' => q(dirhama \(UAE\)),
				'one' => q(dirham \(UAE\)),
				'other' => q(dirhama \(UAE\)),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Avganistanski avgani \(1927–2002\)),
				'few' => q(Avganistanska avgana \(1927–2002\)),
				'one' => q(Avganistanski avgan \(1927–2002\)),
				'other' => q(Avganistanski avgan \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afganistanski afgan),
				'few' => q(afganistanska afgana),
				'one' => q(afganistanski afgan),
				'other' => q(afganistanskih afgana),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albanski lek \(1946–1965\)),
				'few' => q(Albanska leka \(1946–1965\)),
				'one' => q(albanski lek \(1946–1965\)),
				'other' => q(albanski lek \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albanski lek),
				'few' => q(albanska leka),
				'one' => q(albanski lek),
				'other' => q(albanskih leka),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armenski dram),
				'few' => q(armenska drama),
				'one' => q(armenski dram),
				'other' => q(armenskih drama),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Holandskoantilski gulden),
				'few' => q(holandskoantilska guldena),
				'one' => q(holandskoantilski gulden),
				'other' => q(holandskoantilskih guldena),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angolska kvanza),
				'few' => q(angolske kvanze),
				'one' => q(angolska kvanza),
				'other' => q(angolskih kvanzi),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolijska kvanza \(1977–1991\)),
				'few' => q(Angolijske kvanze \(1977–1991\)),
				'one' => q(Angolijska kvanza \(1977–1991\)),
				'other' => q(Angolijskih kvanzi \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolijska nova kvanza \(1990–2000\)),
				'few' => q(angolijske nove kvanze \(1990–2000\)),
				'one' => q(angolijska nova kvanza \(1990–2000\)),
				'other' => q(angolski novi kvanze \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolijska kvanza reajustado \(1995–1999\)),
				'few' => q(angalske kvanze reađustado \(1995–1999\)),
				'one' => q(angolijska kvanza reađustado \(1995–1999\)),
				'other' => q(angolijskih kvanzi reađustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentinski austral),
				'few' => q(argentinska australa),
				'one' => q(argentinski austral),
				'other' => q(argentinski australs),
			},
		},
		'ARL' => {
			display_name => {
				'few' => q(argentinski pezos lej),
				'one' => q(argentinski pezos lej),
				'other' => q(argentinski pezos lej),
			},
		},
		'ARM' => {
			display_name => {
				'few' => q(argentinski pezos moneda nacional),
				'one' => q(argentinski pezo monedo nacional),
				'other' => q(argentinskih pezosa moneda nacional),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentinski pezo \(1983–1985\)),
				'few' => q(argentinska pezosa \(1983–1985\)),
				'one' => q(argentinski pezo \(1983–1985\)),
				'other' => q(argentinskih pezosa \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentinski pezos),
				'few' => q(argentinska pezosa),
				'one' => q(argentinski pezos),
				'other' => q(argentinskih pezosa),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Austrijski šiling),
				'few' => q(austrijska šilinga),
				'one' => q(austrijski šiling),
				'other' => q(austrijskih šilinga),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(Australijski dolar),
				'few' => q(australijska dolara),
				'one' => q(australijski dolar),
				'other' => q(australijskih dolara),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Arubanski florin),
				'few' => q(arubanska florina),
				'one' => q(arubanski florin),
				'other' => q(arubanskih florina),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbejdžanski manat \(1993–2006\)),
				'few' => q(azerbejdžanska manata \(1993–2006\)),
				'one' => q(azerbejdžanski manat \(1993–2006\)),
				'other' => q(azerbejdžanskih manata \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Azerbejdžanski manat),
				'few' => q(azerbejdžanska manata),
				'one' => q(azerbejdžanski manat),
				'other' => q(azerbejdžanskih manata),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosansko-Hercegovački dinar),
				'few' => q(Bosansko-Hercegovačka dinara),
				'one' => q(bosansko-hercegovački dinar),
				'other' => q(bosansko-hercegovačkih dinara),
			},
		},
		'BAM' => {
			symbol => 'KM',
			display_name => {
				'currency' => q(Bosanskohercegovačka konvertibilna marka),
				'few' => q(bosanskohercegovačke konvertibilne marke),
				'one' => q(bosanskohercegovačka konvertibilna marka),
				'other' => q(bosanskohercegovačkih konvertibilnih maraka),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Bosansko-hercegovački novi dinar),
				'few' => q(bosansko-hercegovački novi dinari),
				'one' => q(bosansko-hercegovački novi dinar),
				'other' => q(bosansko-hercegovački novi dinar),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbadoski dolar),
				'few' => q(barbadoska dolara),
				'one' => q(barbadoski dolar),
				'other' => q(barbadoskih dolara),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladeška taka),
				'few' => q(bangladeške take),
				'one' => q(bangladeška taka),
				'other' => q(bangladeških taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgijski frank \(konvertibilni\)),
				'few' => q(belgijska franka \(konvertibilna\)),
				'one' => q(belgijski franak \(konvertibilni\)),
				'other' => q(belgijskih franaka \(konvertibilnih\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgijski franak),
				'few' => q(belgijska franka),
				'one' => q(belgijski franak),
				'other' => q(belgijskih franaka),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgijski frank \(finansijski\)),
				'few' => q(belgijska franka \(finansijska\)),
				'one' => q(belgijski franak \(finansijski\)),
				'other' => q(belgijskih franaka \(finansijskih\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bugarski tvrdi lev),
				'few' => q(bugarska tvrda leva),
				'one' => q(bugarski tvrdi lev),
				'other' => q(bugarskih tvrdih leva),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Bugarski socijalistički lev),
				'few' => q(bugarska socijalistička leva),
				'one' => q(bugarski socijalistički lev),
				'other' => q(bugarskih socijalističkih leva),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bugarski lev),
				'few' => q(bugarska leva),
				'one' => q(bugarski lev),
				'other' => q(bugarskih leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bugarski lev \(1879–1952\)),
				'few' => q(Bugarska leva \(1879–1952\)),
				'one' => q(bugarski lev \(1879–1952\)),
				'other' => q(Bugarskih leva \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahreinski dinar),
				'few' => q(bahreinska dinara),
				'one' => q(bahreinski dinar),
				'other' => q(bahreinskih dinara),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundski franak),
				'few' => q(burundska franka),
				'one' => q(burundski franak),
				'other' => q(burundskih franaka),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermudski dolar),
				'few' => q(bermudska dolara),
				'one' => q(bermudski dolar),
				'other' => q(bermudskih dolara),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunejski dolar),
				'few' => q(brunejska dolara),
				'one' => q(brunejski dolar),
				'other' => q(brunejskih dolara),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolivijski boliviano),
				'few' => q(bolivijska boliviana),
				'one' => q(bolivijski boliviano),
				'other' => q(bolivijskih boliviana),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Bolivijski boliviano \(1863–1963\)),
				'few' => q(bolivijska boliviana \(1863–1963\)),
				'one' => q(bolivijski boliviano \(1863–1963\)),
				'other' => q(bolivijskih boliviana \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivijski pezo),
				'few' => q(Bolivijska pezosa),
				'one' => q(bolivijski pezo),
				'other' => q(bolivijskih pezosa),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivijski mvdol),
				'few' => q(bolivijska mvdola),
				'one' => q(bolivijski mvdol),
				'other' => q(bolivijskih mvdola),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brazilski kruzeiro novo \(1967–1986\)),
				'few' => q(brazilska nova kruzeira \(1967–1986\)),
				'one' => q(brazilski novi kruzeiro \(1967–1986\)),
				'other' => q(brazilskih novih kruzeira \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brazilski kruzado \(1986–1989\)),
				'few' => q(brazilska kruzadosa \(1986–1989\)),
				'one' => q(brazilskih kruzado \(1986–1989\)),
				'other' => q(brazilskih kruzadosa \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brazilski kruzeiro \(1990–1993\)),
				'few' => q(brazilska kruzeira \(1990–1993\)),
				'one' => q(brazilski kruzeiro \(1990–1993\)),
				'other' => q(brazilskih kruzeira \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(Brazilski real),
				'few' => q(brazilska reala),
				'one' => q(brazilski real),
				'other' => q(brazilskih reala),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brazilski kruzado novo \(1989–1990\)),
				'few' => q(brazilska nova kruzada \(1989–1990\)),
				'one' => q(brazilski novi kruzado \(1989–1990\)),
				'other' => q(brazilskih novih kruzada \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazilski kruzeiro \(1993–1994\)),
				'few' => q(brazilijska kruzeira \(1993–1994\)),
				'one' => q(brazilski kruzeiro \(1993–1994\)),
				'other' => q(brazilskih kruzeira \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brazilski kruzeiro \(1942–1967\)),
				'few' => q(brazilijska kruzeira \(1942–1967\)),
				'one' => q(brazilski kruzeiro \(1942–1967\)),
				'other' => q(brazilskih kruzeira \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahamski dolar),
				'few' => q(bahamska dolara),
				'one' => q(bahamski dolar),
				'other' => q(bahamskih dolara),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Butanski ngultrum),
				'few' => q(butanska ngultruma),
				'one' => q(butanski ngultrum),
				'other' => q(butanskih ngultruma),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmanski kjat),
				'few' => q(burmanska kjata),
				'one' => q(burmanski kjat),
				'other' => q(burmanskih kjata),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Bocvanska pula),
				'few' => q(bocvanske pule),
				'one' => q(bocvanska pula),
				'other' => q(bocvanskih pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Beloruska nova rublja \(1994–1999\)),
				'few' => q(beloruske nove rublje \(1994–1999\)),
				'one' => q(beloruska nova rublja \(1994–1999\)),
				'other' => q(beloruskih novih rublji \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Bjeloruska rublja),
				'few' => q(bjeloruske rublje),
				'one' => q(bjeloruska rublja),
				'other' => q(bjeloruskih rubalja),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Bjeloruska rublja \(2000–2016\)),
				'few' => q(bjeloruske rublje \(2000–2016\)),
				'one' => q(bjeloruska rublja \(2000–2016\)),
				'other' => q(bjeloruskih rubalja \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Belizeanski dolar),
				'few' => q(belizeanska dolara),
				'one' => q(belizeanski dolar),
				'other' => q(belizeanskih dolara),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Kanadski dolar),
				'few' => q(kanadska dolara),
				'one' => q(kanadski dolar),
				'other' => q(kanadskih dolara),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongoanski franak),
				'few' => q(kongoanska franka),
				'one' => q(kongoanski franak),
				'other' => q(kongoanskih franaka),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR Evro),
				'few' => q(WIR evra),
				'one' => q(WIR evro),
				'other' => q(WIR evra),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Švicarski franak),
				'few' => q(švicarska franka),
				'one' => q(švicarski franak),
				'other' => q(švicarskih franaka),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franak),
				'few' => q(WIR franka),
				'one' => q(WIR franak),
				'other' => q(WIR franak),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Čileanski eskudo),
				'few' => q(čileanska eskuda),
				'one' => q(čileanski eskudo),
				'other' => q(čileanskih eskuda),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Čileanski unidades de fomento),
				'few' => q(čileanska unidades de fomentos),
				'one' => q(čileanski unidades de fomentos),
				'other' => q(čileanski unidades de fomentos),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Čileanski pezos),
				'few' => q(čileanska pezosa),
				'one' => q(čileanski pezos),
				'other' => q(čileanskih pezosa),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Kineski juan \(izvanteritorijalni\)),
				'few' => q(kineska juana \(izvanteritorijalni\)),
				'one' => q(kineski juan \(izvanteritorijalni\)),
				'other' => q(kineskih juana \(izvanteritorijalni\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dolar kineske narodne banke),
				'few' => q(dolari kineske narodne banke),
				'one' => q(dolar kineske narodne banke),
				'other' => q(dolar kineske narodne banke),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(Kineski juan),
				'few' => q(kineska juana),
				'one' => q(kineski juan),
				'other' => q(kineskih juana),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolumbijski pezos),
				'few' => q(kolumbijska pezosa),
				'one' => q(kolumbijski pezos),
				'other' => q(kolumbijskih pezosa),
			},
		},
		'COU' => {
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
				'currency' => q(Kostarikanski kolon),
				'few' => q(kostarikanska kolona),
				'one' => q(kostarikanski kolon),
				'other' => q(kostarikanskih kolona),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Srpski dinar \(2002–2006\)),
				'few' => q(srpska dinara \(2002–2006\)),
				'one' => q(srpski dinar \(2002–2006\)),
				'other' => q(srpskih dinara \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Čehoslovačka tvrda koruna),
				'few' => q(čehoslovačke tvrde krune),
				'one' => q(čehoslovačka tvrda kruna),
				'other' => q(čehoslovačka tvrda kruna),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kubanski konvertibilni pezos),
				'few' => q(kubanska konvertibilna pezosa),
				'one' => q(kubanski konvertibilni pezos),
				'other' => q(kubanskih konvertibilnih pezosa),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubanski pezos),
				'few' => q(kubanska pezosa),
				'one' => q(kubanski pezos),
				'other' => q(kubanskih pezosa),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Zelenortski eskudo),
				'few' => q(zelenortska eskuda),
				'one' => q(zelenortski eskudo),
				'other' => q(zelenortskih eskuda),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kipratska funta),
				'few' => q(kiparske funte),
				'one' => q(kiparska funta),
				'other' => q(kiparska funta),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Češka kruna),
				'few' => q(češke krune),
				'one' => q(češka kruna),
				'other' => q(čeških kruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Istočnoevropska marka),
				'few' => q(istočnonemačke marke),
				'one' => q(istočnonemačka marka),
				'other' => q(istočnonemačkih maraka),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Nemačka marka),
				'few' => q(Nemačke marke),
				'one' => q(nemačka marka),
				'other' => q(nemačkih maraka),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Džibutski franak),
				'few' => q(džibutska franka),
				'one' => q(džibutski franak),
				'other' => q(džibutskih franaka),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Danska kruna),
				'few' => q(danske krune),
				'one' => q(danska kruna),
				'other' => q(danskih kruna),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikanski pezos),
				'few' => q(dominikanska pezosa),
				'one' => q(dominikanski pezos),
				'other' => q(dominikanskih pezosa),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Alžirski dinar),
				'few' => q(alžirska dinara),
				'one' => q(alžirski dinar),
				'other' => q(alžirskih dinara),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ekvadorijski sukr),
				'few' => q(ekvadorska sakra),
				'one' => q(ekvadorska sakra),
				'other' => q(ekvadorskih sakra),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ekvadorski unidad de valor konstantin \(UVC\)),
				'few' => q(ekvadorska unidad de valor constante \(UVC\)),
				'one' => q(ekvadorski unidad de valor constante \(UVC\)),
				'other' => q(ekvadorski unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estonska kruna),
				'few' => q(estonske krune),
				'one' => q(estonska kruna),
				'other' => q(estonskih kruna),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Egipatska funta),
				'few' => q(egipatske funte),
				'one' => q(egipatska funta),
				'other' => q(egipatskih funti),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritrejska nakfa),
				'few' => q(eritrejske nakfe),
				'one' => q(eritrejska nakfa),
				'other' => q(eritrejskih nakfi),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Španska pezeta \(račun\) ESA),
				'few' => q(španske pezete \(A račun\)),
				'one' => q(španska pezeta \(A račun\)),
				'other' => q(španska pezeta \(A račun\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Španska pezeta \(konvertibilni račun\)),
				'few' => q(španske pezete \(konvertibilan račun\)),
				'one' => q(španska pezeta \(konvertibilan račun\)),
				'other' => q(španska pezeta \(konvertibilan račun\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Španska pezeta),
				'few' => q(španska pezeta),
				'one' => q(španska pezeta),
				'other' => q(španske pezete),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Etiopski bir),
				'few' => q(etiopska bira),
				'one' => q(etiopski bir),
				'other' => q(etiopskih bira),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'few' => q(eura),
				'one' => q(euro),
				'other' => q(eura),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finska marka),
				'few' => q(Finske marke),
				'one' => q(finska marka),
				'other' => q(finskih maraka),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fidžijski dolar),
				'few' => q(fidžijska dolara),
				'one' => q(fidžijski dolar),
				'other' => q(fidžijskih dolara),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Folklandska funta),
				'few' => q(folklandske funte),
				'one' => q(folklandska funta),
				'other' => q(folklandskih funti),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Francuski franak),
				'few' => q(Francuska franka),
				'one' => q(francuski franak),
				'other' => q(francuskih franaka),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(Britanska funta),
				'few' => q(britanske funte),
				'one' => q(britanska funta),
				'other' => q(britanskih funti),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Gruzijski kupon larit),
				'few' => q(gruzijska kupon larita),
				'one' => q(gruzijski kupon larit),
				'other' => q(gruzijskih kupon larita),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Gruzijski lari),
				'few' => q(gruzijska larija),
				'one' => q(gruzijski lari),
				'other' => q(gruzijskih larija),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ganijski cedi \(1979–2007\)),
				'few' => q(ganska ceda \(1979–2007\)),
				'one' => q(ganski ced \(1979–2007\)),
				'other' => q(ganskih ceda \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ganski cedi),
				'few' => q(ganska cedija),
				'one' => q(ganski cedi),
				'other' => q(ganskih cedija),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltarska funta),
				'few' => q(gibraltarske funte),
				'one' => q(gibraltarska funta),
				'other' => q(gibraltarskih funti),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambijski dalasi),
				'few' => q(gambijska dalasija),
				'one' => q(gambijski dalasi),
				'other' => q(gambijskih dalasija),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Gvinejski franak),
				'few' => q(gvinejska franka),
				'one' => q(gvinejski franak),
				'other' => q(gvinejskih franaka),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Gvinejski sili),
				'few' => q(gvinejska silija),
				'one' => q(gvinejski sili),
				'other' => q(gvinejski silij),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Evatorijalna gvineja ekvele),
				'few' => q(evatorijalno-gvinejska ekvela),
				'one' => q(evatorijalno-gvinejski ekvele),
				'other' => q(evatorijalno-gvinejskih ekvela),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drahma),
				'few' => q(grčke drahme),
				'one' => q(grčka drahma),
				'other' => q(grčkih drahmi),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Gvatemalski kecal),
				'few' => q(gvatemalska kecala),
				'one' => q(gvatemalski kecal),
				'other' => q(gvatemalskih kecala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugalska Gvineja eskudo),
				'few' => q(portugalsko-gvinejska eskuda),
				'one' => q(portugalsko-gvinejski eskudo),
				'other' => q(portugalsko-gvinejski eskudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Gvineja bisao pezo),
				'few' => q(gvineja-bisaoška pezosa),
				'one' => q(gvineja-bisaoški pezo),
				'other' => q(gvinejsko-bisaoski pezos),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Gvajanski dolar),
				'few' => q(gvajanska dolara),
				'one' => q(gvajanski dolar),
				'other' => q(gvajanskih dolara),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Honkonški dolar),
				'few' => q(hongkonška dolara),
				'one' => q(hongkonški dolar),
				'other' => q(hongkonških dolara),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Honduraška lempira),
				'few' => q(honduraške lempire),
				'one' => q(honduraška lempira),
				'other' => q(honduraških lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Hrvatski dinar),
				'few' => q(Hrvatska dinara),
				'one' => q(hrvatski dinar),
				'other' => q(hrvatskih dinara),
			},
		},
		'HRK' => {
			symbol => 'kn',
			display_name => {
				'currency' => q(Hrvatska kuna),
				'few' => q(hrvatske kune),
				'one' => q(hrvatska kuna),
				'other' => q(hrvatskih kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haićanski gurd),
				'few' => q(haićanska gurda),
				'one' => q(haićanski gurd),
				'other' => q(haićanskih gurda),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Mađarska forinta),
				'few' => q(mađarske forinte),
				'one' => q(mađarska forinta),
				'other' => q(mađarskih forinti),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonežanska rupija),
				'few' => q(indonežanske rupije),
				'one' => q(indonežanska rupija),
				'other' => q(indonežanskih rupija),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irska funta),
				'few' => q(irske funte),
				'one' => q(irska funta),
				'other' => q(irskih funti),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Izraelska funta),
				'few' => q(izraelske funte),
				'one' => q(izraelska funta),
				'other' => q(izraelska funta),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(stari izraelski šekeli),
				'few' => q(stari izraelski šekeli),
				'one' => q(stari izraelski šekeli),
				'other' => q(stari izraelski šekeli),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(Izraelski novi šekel),
				'few' => q(izraelska nova šekela),
				'one' => q(izraelski novi šekel),
				'other' => q(izraelskih novih šekela),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Indijska rupija),
				'few' => q(indijske rupije),
				'one' => q(indijska rupija),
				'other' => q(indijskih rupija),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Irački dinar),
				'few' => q(iračka dinara),
				'one' => q(irački dinar),
				'other' => q(iračkih dinara),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Iranski rijal),
				'few' => q(iranska rijala),
				'one' => q(iranski rijal),
				'other' => q(iranskih rijala),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(stara islandska kruna),
				'few' => q(stara islandska kruna),
				'one' => q(stara islandska kruna),
				'other' => q(stara islandska kruna),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Islandska kruna),
				'few' => q(islandske krune),
				'one' => q(islandska kruna),
				'other' => q(islandskih kruna),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italijanska lira),
				'few' => q(Italijanske lire),
				'one' => q(italijanska lira),
				'other' => q(italijanske lire),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamajčanski dolar),
				'few' => q(jamajčanska dolara),
				'one' => q(jamajčanski dolar),
				'other' => q(jamajčanskih dolara),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jordanski dinar),
				'few' => q(jordanska dinara),
				'one' => q(jordanski dinar),
				'other' => q(jordanskih dinara),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japanski jen),
				'few' => q(japanska jena),
				'one' => q(japanski jen),
				'other' => q(japanskih jena),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Kenijski šiling),
				'few' => q(kenijska šilinga),
				'one' => q(kenijski šiling),
				'other' => q(kenijskih šilinga),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kirgistanski som),
				'few' => q(kirgistanska soma),
				'one' => q(kirgistanski som),
				'other' => q(kirgistanskih soma),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodžanski rijel),
				'few' => q(kambodžanska rijela),
				'one' => q(kambodžanski rijel),
				'other' => q(kambodžanskih rijela),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komorski franak),
				'few' => q(komorska franka),
				'one' => q(komorski franak),
				'other' => q(komorskih franaka),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Sjevernokorejski von),
				'few' => q(sjevernokorejska vona),
				'one' => q(sjevernokorejski von),
				'other' => q(sjevernokorejskih vona),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Južno-korejski hvan \(1953–1962\)),
				'few' => q(južno-korejska hvana \(1953–1962\)),
				'one' => q(južno-korejski hvan \(1953–1962\)),
				'other' => q(južno-korejski hvana \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Južno-korejski Von \(1945–1953\)),
				'few' => q(južno-korejska vona \(1945–1953\)),
				'one' => q(južno-korejski von \(1945–1953\)),
				'other' => q(južno-korejski von \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Južnokorejski von),
				'few' => q(južnokorejska vona),
				'one' => q(južnokorejski von),
				'other' => q(južnokorejskih vona),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuvajtski dinar),
				'few' => q(kuvajtska dinara),
				'one' => q(kuvajtski dinar),
				'other' => q(kuvajtskih dinara),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kajmanski dolar),
				'few' => q(kajmanska dolara),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanskih dolara),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kazahstanski tenge),
				'few' => q(kazahstanska tenga),
				'one' => q(kazahstanski tenge),
				'other' => q(kazahstanskih tenga),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laoski kip),
				'few' => q(laoska kipa),
				'one' => q(laoski kip),
				'other' => q(laoskih kipa),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libanska funta),
				'few' => q(libanske funte),
				'one' => q(libanska funta),
				'other' => q(libanskih funti),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Šrilankanska rupija),
				'few' => q(šrilankanske rupije),
				'one' => q(šrilankanska rupija),
				'other' => q(šrilankanskih rupija),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberijski dolar),
				'few' => q(liberijska dolara),
				'one' => q(liberijski dolar),
				'other' => q(liberijskih dolara),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotski loti),
				'few' => q(lesotska lotisa),
				'one' => q(lesotski lotis),
				'other' => q(lesotskih lotisa),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litvanski litas),
				'few' => q(litvanska litasa),
				'one' => q(litvanski litas),
				'other' => q(litvanskih litasa),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litvanski talonas),
				'few' => q(litvanske talone),
				'one' => q(litvanska talona),
				'other' => q(litvanskih talona),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luksemburški konvertibilni franak),
				'few' => q(luksemburška konvertibilna franka),
				'one' => q(luksemburški konvertibilni franak),
				'other' => q(luksemburški konvertibilni franak),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luksemburški franak),
				'few' => q(luksemburška franka),
				'one' => q(luksemburški franak),
				'other' => q(luksemburški franci),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luksemburški finansijski franak),
				'few' => q(luksemburška financijska franka),
				'one' => q(luksemburški financijski franak),
				'other' => q(luksemburški financijski franak),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Letonski lats),
				'few' => q(letonska latsa),
				'one' => q(letonski lats),
				'other' => q(letonskih latsa),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvijska rublja),
				'few' => q(latvijska rublja),
				'one' => q(latvijska rublja),
				'other' => q(latvijska rublja),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Libijski dinar),
				'few' => q(libijska dinara),
				'one' => q(libijski dinar),
				'other' => q(libijskih dinara),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokanski dirham),
				'few' => q(marokanska dirhama),
				'one' => q(marokanski dirham),
				'other' => q(marokanskih dirhama),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokanski franak),
				'few' => q(marokanska franka),
				'one' => q(marokanski franak),
				'other' => q(marokanski franak),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monegaskaški franak),
				'few' => q(monegaskaška franka),
				'one' => q(monegaskaški franak),
				'other' => q(monegaskaških franaka),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldavski kupon),
				'few' => q(moldovanska kupona),
				'one' => q(moldovanski kupon),
				'other' => q(moldovanskih kupona),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldavski lej),
				'few' => q(moldavska leja),
				'one' => q(moldavski lej),
				'other' => q(moldavskih leja),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Malagaški arijari),
				'few' => q(malagaška arijarija),
				'one' => q(malagaški arijari),
				'other' => q(malagaških arijarija),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Malagasijski franak),
				'few' => q(madagaskarska franka),
				'one' => q(madagaskarski franak),
				'other' => q(madagaskarski franaka),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Makedonski denar),
				'few' => q(makedonska denara),
				'one' => q(makedonski denar),
				'other' => q(makedonskih denara),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Makedonski denar \(1992–1993\)),
				'few' => q(makedonska denara \(1992–1993\)),
				'one' => q(makedonski denar \(1992–1993\)),
				'other' => q(makedonskih dinara \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malijanski franak),
				'few' => q(malijska franka),
				'one' => q(malijski franak),
				'other' => q(malijski franak),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Mijanmarski kjat),
				'few' => q(mijanmarska kjata),
				'one' => q(mijanmarski kjat),
				'other' => q(mijanmarskih kjata),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongolski tugrik),
				'few' => q(mongolska tugrika),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskih tugrika),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Makaonska pataka),
				'few' => q(makaonske patake),
				'one' => q(makaonska pataka),
				'other' => q(makaonskih pataka),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mauritanijska ugvija \(1973–2017\)),
				'few' => q(mauritanijske ugvije \(1973–2017\)),
				'one' => q(mauritanijska ugvija \(1973–2017\)),
				'other' => q(mauritanijskih ugvija \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritanijska ugvija),
				'few' => q(mauritanijske ugvije),
				'one' => q(mauritanijska ugvija),
				'other' => q(mauritanijskih ugvija),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Malteška lira),
				'few' => q(malteške lire),
				'one' => q(malteška lira),
				'other' => q(malteških lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Malteška funta),
				'few' => q(malteške funte),
				'one' => q(malteška funta),
				'other' => q(malteška funta),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mauricijska rupija),
				'few' => q(mauricijske rupije),
				'one' => q(mauricijska rupija),
				'other' => q(mauricijskih rupija),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldivska rufija),
				'few' => q(maldivske rufije),
				'one' => q(maldivska rufija),
				'other' => q(maldivskih rufija),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malavijska kvača),
				'few' => q(malavijske kvače),
				'one' => q(malavijska kvača),
				'other' => q(malavijskih kvača),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Meksički pezos),
				'few' => q(meksička pezosa),
				'one' => q(meksički pezos),
				'other' => q(meksičkih pezosa),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Meksijski srebrno pezo \(1861–1992\)),
				'few' => q(meksička srebrna pezosa \(1861–1992\)),
				'one' => q(meksički srebrni pezos \(1861–1992\)),
				'other' => q(meksički srebrni pezos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Meksijski unidad de inverzion),
				'few' => q(meksička unidads de inversion \(UDI\)),
				'one' => q(meksički unidads de inversion \(UDI\)),
				'other' => q(meksički unidads de inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malezijski ringit),
				'few' => q(malezijska ringita),
				'one' => q(malezijski ringit),
				'other' => q(malezijskih ringita),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambijski eskudo),
				'few' => q(mozambijska eskuda),
				'one' => q(mozambijski eskudo),
				'other' => q(mozambijski eskudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambijski metikal \(1980–2006\)),
				'few' => q(mozambijska metikala \(1980–2006\)),
				'one' => q(mozambijski metikal \(1980–2006\)),
				'other' => q(mozambijski metikal \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mozambijski metikal),
				'few' => q(mozambijska metikala),
				'one' => q(mozambijski metikal),
				'other' => q(mozambijskih metikala),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibijski dolar),
				'few' => q(namibijska dolara),
				'one' => q(namibijski dolar),
				'other' => q(namibijskih dolara),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigerijska naira),
				'few' => q(nigerijske naire),
				'one' => q(nigerijska naira),
				'other' => q(nigerijskih naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nikaragvanška kordoba \(1988–1991\)),
				'few' => q(nikaragvanske kordobe \(1988–1991\)),
				'one' => q(nikaragvanska kordoba \(1988–1991\)),
				'other' => q(nikaragvanska kordoba \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikaragvanska kordoba),
				'few' => q(nikaragvanske kordobe),
				'one' => q(nikaragvanska kordoba),
				'other' => q(nikaragvanskih kordoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Holandski gulden),
				'few' => q(holandska guldena),
				'one' => q(holandski gulden),
				'other' => q(holandskih guldena),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norveška kruna),
				'few' => q(norveške krune),
				'one' => q(norveška kruna),
				'other' => q(norveških kruna),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepalska rupija),
				'few' => q(nepalske rupije),
				'one' => q(nepalska rupija),
				'other' => q(nepalskih rupija),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(Novozelandski dolar),
				'few' => q(novozelandska dolara),
				'one' => q(novozelandski dolar),
				'other' => q(novozelandskih dolara),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omanski rijal),
				'few' => q(omanska rijala),
				'one' => q(omanski rijal),
				'other' => q(omanskih rijala),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panamska balboa),
				'few' => q(panamske balboe),
				'one' => q(panamska balboa),
				'other' => q(panamskih balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruvijski inti),
				'few' => q(peruanske inte),
				'one' => q(peruanska inta),
				'other' => q(peruanska inta),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peruanski sol),
				'few' => q(peruanska sola),
				'one' => q(peruanski sol),
				'other' => q(peruanskih sola),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruvijski sol \(1863–1965\)),
				'few' => q(peruanska sola \(1863–1965\)),
				'one' => q(peruanski sol \(1863–1965\)),
				'other' => q(peruanski sol \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina Papue Nove Gvineje),
				'few' => q(kine Papue Nove Gvineje),
				'one' => q(kina Papue Nove Gvineje),
				'other' => q(kina Papue Nove Gvineje),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipinski pezos),
				'few' => q(filipinska pezosa),
				'one' => q(filipinski pezos),
				'other' => q(filipinskih pezosa),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskih rupija),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Poljski zlot),
				'few' => q(poljska zlota),
				'one' => q(poljski zlot),
				'other' => q(poljskih zlota),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Poljski zloti \(1950–1995\)),
				'few' => q(poljske zlote \(1950–1995\)),
				'one' => q(poljski zlot \(1950–1995\)),
				'other' => q(poljski zlot \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugalski eskudo),
				'few' => q(portugalska eskuda),
				'one' => q(portugalski eskudo),
				'other' => q(portugalskih eskuda),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paragvajski gvarani),
				'few' => q(paragvajska gvaranija),
				'one' => q(paragvajski gvarani),
				'other' => q(paragvajskih gvaranija),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Katarski rijal),
				'few' => q(katarska rijala),
				'one' => q(katarski rijal),
				'other' => q(katarskih rijala),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rodizijski dolar),
				'few' => q(rodezijska dolara),
				'one' => q(rodezijski dolar),
				'other' => q(rodezijski dolar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumunski leu \(1952–2006\)),
				'few' => q(rumunska leua \(1952–2006\)),
				'one' => q(rumunski leu \(1952–2006\)),
				'other' => q(rumunskih leua \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Rumunski lej),
				'few' => q(rumunska leja),
				'one' => q(rumunski lej),
				'other' => q(rumunskih leja),
			},
		},
		'RSD' => {
			symbol => 'din.',
			display_name => {
				'currency' => q(Srpski dinar),
				'few' => q(srpska dinara),
				'one' => q(srpski dinar),
				'other' => q(srpskih dinara),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Ruska rublja),
				'few' => q(ruske rublje),
				'one' => q(ruska rublja),
				'other' => q(ruskih rubalja),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Ruska rublja \(1991–1998\)),
				'few' => q(ruske rublje \(1991–1998\)),
				'one' => q(ruska rublja \(1991–1998\)),
				'other' => q(ruskih rublji \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruandski franak),
				'few' => q(ruandska franka),
				'one' => q(ruandski franak),
				'other' => q(ruandskih franaka),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saudijski rijal),
				'few' => q(saudijska rijala),
				'one' => q(saudijski rijal),
				'other' => q(saudijskih rijala),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Solomonski dolar),
				'few' => q(solomonska dolara),
				'one' => q(solomonski dolar),
				'other' => q(solomonskih dolara),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Sejšelska rupija),
				'few' => q(sejšelske rupije),
				'one' => q(sejšelska rupija),
				'other' => q(sejšelskih rupija),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudanski dinar \(1992–2007\)),
				'few' => q(sudanska dinara \(1992–2007\)),
				'one' => q(sudanski dinar \(1992–2007\)),
				'other' => q(sudanski dinar \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudanska funta),
				'few' => q(sudanske funte),
				'one' => q(sudanska funta),
				'other' => q(sudanskih funti),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudanska funta \(1957–1998\)),
				'few' => q(sudanske funte \(1957–1998\)),
				'one' => q(sudanska funta \(1957–1998\)),
				'other' => q(sudanska funta \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Švedska kruna),
				'few' => q(švedske krune),
				'one' => q(švedska kruna),
				'other' => q(švedskih kruna),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapurski dolar),
				'few' => q(singapurska dolara),
				'one' => q(singapurski dolar),
				'other' => q(singapurskih dolara),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Svetohelenska funta),
				'few' => q(svetohelenske funte),
				'one' => q(svetohelenska funta),
				'other' => q(svetohelenskih funti),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovenski tolar),
				'few' => q(slovenačka tolara),
				'one' => q(slovenački tolar),
				'other' => q(slovenačkih tolara),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovačka kruna),
				'few' => q(slovačke kune),
				'one' => q(slovačka kuna),
				'other' => q(slovačkih kuna),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sijeraleonski leone),
				'few' => q(sijeraleonska leona),
				'one' => q(sijeraleonski leone),
				'other' => q(sijeraleonskih leona),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somalski šiling),
				'few' => q(somalska šilinga),
				'one' => q(somalski šiling),
				'other' => q(somalskih šilinga),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinamski dolar),
				'few' => q(surinamska dolara),
				'one' => q(surinamski dolar),
				'other' => q(surinamskih dolara),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamski gilder),
				'few' => q(surinamska guldena),
				'one' => q(surinamski gulden),
				'other' => q(surinamski gulden),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Južnosudanska funta),
				'few' => q(južnosudanske funte),
				'one' => q(južnosudanska funta),
				'other' => q(južnosudanskih funti),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra Sao Toma i Principa \(1977–2017\)),
				'few' => q(dobre Sao Toma i Principa \(1977–2017\)),
				'one' => q(dobra Sao Toma i Principa \(1977–2017\)),
				'other' => q(dobri Sao Toma i Principa \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra Sao Toma i Principa),
				'few' => q(dobre Sao Toma i Principa),
				'one' => q(dobra Sao Toma i Principa),
				'other' => q(dobri Sao Toma i Principa),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovjetska rublja),
				'few' => q(sovjetske rublje),
				'one' => q(sovjetska rublja),
				'other' => q(sovjetske rublje),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadorski kolon),
				'few' => q(salvadorska kolona),
				'one' => q(salvadorski kolon),
				'other' => q(salvadorski kolon),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Sirijska funta),
				'few' => q(sirijske funte),
				'one' => q(sirijska funta),
				'other' => q(sirijskih funti),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Svazilendski lilangeni),
				'few' => q(svazilendska lilangena),
				'one' => q(svazilendski lilangeni),
				'other' => q(svazilendskih lilangena),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Tajlandski baht),
				'few' => q(tajlandska bahta),
				'one' => q(tajlandski baht),
				'other' => q(tajlandskih bahta),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadžakistanska rublja),
				'few' => q(tadžikistanske rublje),
				'one' => q(tadžikistanska rublja),
				'other' => q(tadžikistanska rublja),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tadžikistanski somoni),
				'few' => q(tadžikistanska somonija),
				'one' => q(tadžikistanski somoni),
				'other' => q(tadžikistanskih somonija),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistanski manat \(1993–2009\)),
				'few' => q(turkmenistanska manata \(1993–2009\)),
				'one' => q(turkmenistanski manat \(1993–2009\)),
				'other' => q(turkmenistanski manat \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Turkmenistanski manat),
				'few' => q(turkmenistanska manata),
				'one' => q(turkmenistanski manat),
				'other' => q(turkmenistanskih manata),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tuniški dinar),
				'few' => q(tuniška dinara),
				'one' => q(tuniški dinar),
				'other' => q(tuniških dinara),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tonganska panga),
				'few' => q(tonganske pange),
				'one' => q(tonganska panga),
				'other' => q(tonganskih panga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timorški eskudo),
				'few' => q(timorska eskuda),
				'one' => q(timorski eskudo),
				'other' => q(timorski eskudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turska lira \(1922–2005\)),
				'few' => q(turske lire \(1922–2005\)),
				'one' => q(turska lira \(1922–2005\)),
				'other' => q(turkskih lira \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turska lira),
				'few' => q(turske lire),
				'one' => q(turska lira),
				'other' => q(turskih lira),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidadtobaški dolar),
				'few' => q(trinidadtobaška dolara),
				'one' => q(trinidadtobaški dolar),
				'other' => q(trinidadtobaških dolara),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Novi tajvanski dolar),
				'few' => q(nova tajvanska dolara),
				'one' => q(novi tajvanski dolar),
				'other' => q(novih tajvanskih dolara),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzanijski šiling),
				'few' => q(tanzanijska šilinga),
				'one' => q(tanzanijski šiling),
				'other' => q(tanzanijskih šilinga),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukrajinska hrivnja),
				'few' => q(ukrajinske hrivnje),
				'one' => q(ukrajinska hrivnja),
				'other' => q(ukrajinskih hrivnji),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrajinski karbovaneti),
				'few' => q(ukrajinska karbovantsiva),
				'one' => q(ukrajinski karbovantsiv),
				'other' => q(ukrajinski karbovantsiv),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandijski šiling \(1966–1987\)),
				'few' => q(ugandska šilinga \(1966–1987\)),
				'one' => q(ugandski šiling \(1966–1987\)),
				'other' => q(ugandski šiling \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Ugandski šiling),
				'few' => q(ugandska šilinga),
				'one' => q(ugandski šiling),
				'other' => q(ugandskih šilinga),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(Američki dolar),
				'few' => q(američka dolara),
				'one' => q(američki dolar),
				'other' => q(američkih dolara),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(SAD dolar \(sledeći dan\)),
				'few' => q(američka dolara \(sledeći dan\)),
				'one' => q(američki dolar \(sledeći dan\)),
				'other' => q(američki dolar \(sledeći dan\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(SAD dolar \(isti dan\)),
				'few' => q(američka dolara \(isti dan\)),
				'one' => q(američki dolar \(isti dan\)),
				'other' => q(američki dolar \(isti dan\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Urugvajski pezo en unidades indeksades),
				'few' => q(urugvajska pesosa en unidades indexadas),
				'one' => q(urugvajski pesos en unidades indexadas),
				'other' => q(urugvajski pesos en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Urugvajski pezo \(1975–1993\)),
				'few' => q(urugvajska pezosa \(1975–1993\)),
				'one' => q(urugvajski pezos \(1975–1993\)),
				'other' => q(urugvajski pezos \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Urugvajski pezos),
				'few' => q(urugvajska pezosa),
				'one' => q(urugvajski pezos),
				'other' => q(urugvajskih pezosa),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Uzbekistanski som),
				'few' => q(uzbekistanska soma),
				'one' => q(uzbekistanski som),
				'other' => q(uzbekistanskih soma),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venecuelanski bolivar \(1871–2008\)),
				'few' => q(venecuelska bolivara \(1871–2008\)),
				'one' => q(venecuelski bolivar \(1871–2008\)),
				'other' => q(venecuelskih bolivara \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venecuelanski bolivar),
				'few' => q(venecuelanska bolivara),
				'one' => q(venecuelanski bolivar),
				'other' => q(venecuelanskih bolivara),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vijetnamski dong),
				'few' => q(vijetnamska donga),
				'one' => q(vijetnamski dong),
				'other' => q(vijetnamskih donga),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vijetnamski dong \(1978–1985\)),
				'few' => q(vijetnamska donga \(1978–1985\)),
				'one' => q(vijetnamski dong \(1978–1985\)),
				'other' => q(vijetnamski dong \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatski vatu),
				'few' => q(vanuatska vatua),
				'one' => q(vanuatski vatu),
				'other' => q(vanuatskih vatua),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoanska tala),
				'few' => q(samoanske tale),
				'one' => q(samoanska tala),
				'other' => q(samoanskih tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Centralnoafrički franak \(CFA\)),
				'few' => q(centralnoafrička franka \(CFA\)),
				'one' => q(centralnoafrički franak \(CFA\)),
				'other' => q(centralnoafričkih franaka \(CFA\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Srebro),
				'few' => q(srebra),
				'one' => q(srebro),
				'other' => q(srebro),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Zlato),
				'few' => q(zlata),
				'one' => q(zlato),
				'other' => q(zlato),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Evropska kompozitna jedinica),
				'few' => q(evropske složene jedinice),
				'one' => q(evropska složena jedinica),
				'other' => q(evropska složena jedinica),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Evropska novčana jedinica),
				'few' => q(evropske monetarne jedinice),
				'one' => q(evropska monetarna jedinica),
				'other' => q(evropska monetarna jedinica),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Evropska jedinica računa \(XBC\)),
				'few' => q(evropske obračunske jedinice \(XBC\)),
				'one' => q(evropska obračunska jedinica \(XBC\)),
				'other' => q(evropska obračunska jedinica \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Evropska jedinica računa \(XBD\)),
				'few' => q(evropske obračunske jedinice \(XBD\)),
				'one' => q(evropska obračunska jedinica \(XBD\)),
				'other' => q(evropska obračunska jedinica \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(Istočnokaripski dolar),
				'few' => q(istočnokaripska dolara),
				'one' => q(istočnokaripski dolar),
				'other' => q(istočnokaripskih dolara),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Posebna prava),
				'few' => q(posebna crtaća prava),
				'one' => q(posebno crtaće pravo),
				'other' => q(posebnih crtaćih prava),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Evropska valutna jedinica),
				'few' => q(evropske valutne jedinice),
				'one' => q(evropska valutna jedinica),
				'other' => q(evropskih valutnih jedinica),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Francuski zlatni frank),
				'few' => q(francuska zlatna franka),
				'one' => q(francuski zlatni franak),
				'other' => q(francuskih zlatnih franaka),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Francuski UIC-frank),
				'few' => q(francuska UIC-franka),
				'one' => q(francuski UIC-franak),
				'other' => q(francuskih UIC-franaka),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Zapadnoafrički franak \(CFA\)),
				'few' => q(zapadnoafrička franka \(CFA\)),
				'one' => q(zapadnoafrički franak \(CFA\)),
				'other' => q(zapadnoafričkih franaka \(CFA\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladijum),
				'few' => q(paladijuma),
				'one' => q(paladijum),
				'other' => q(paladijuma),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(Franak \(CFP\)),
				'few' => q(franka \(CFP\)),
				'one' => q(franak \(CFP\)),
				'other' => q(franaka \(CFP\)),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platina),
				'few' => q(platine),
				'one' => q(platina),
				'other' => q(platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET fondovi),
				'few' => q(RINET fonda),
				'one' => q(RINET fond),
				'other' => q(RINET fondova),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Kod testirane valute),
				'few' => q(ispitna koda valute),
				'one' => q(ispitni kod valute),
				'other' => q(ispitnih kodova valute),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nepoznata valuta),
				'few' => q(nepoznate valute),
				'one' => q(nepoznata valuta),
				'other' => q(nepoznatih valuta),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemenski dinar),
				'few' => q(jemenska dinara),
				'one' => q(jemenski dinar),
				'other' => q(jemenskih dinara),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Jemenski rijal),
				'few' => q(jemenska rijala),
				'one' => q(jemenski rijal),
				'other' => q(jemenskih rijala),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslovenski tvrdi dinar),
				'few' => q(jugoslovenska čvrsta dinara),
				'one' => q(jugoslovenski čvrsti dinar),
				'other' => q(jugoslovenskih čvstih dinara),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslovenski novi dinar),
				'few' => q(jugoslovenska nova dinara),
				'one' => q(jugoslovenski novi dinar),
				'other' => q(jugoslovenskih novih dinara),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslovenski konvertibilni dinar),
				'few' => q(jugoslovenska konvertibilna dinara),
				'one' => q(jugoslovenski konvertibilni dinar),
				'other' => q(jugoslovenskih konvertibilnih dinara),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Jugoslovenski reformirani dinar),
				'few' => q(jugoslovenska reformirana dinara),
				'one' => q(jugoslovenski reformirani dinar),
				'other' => q(jugoslovenskih reformiranih dinara),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Južnoafrički rand \(finansijski\)),
				'few' => q(južnoafrička randa \(financijska\)),
				'one' => q(južnoafrički rand \(financijski\)),
				'other' => q(južnoafičkih randa \(financijskih\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Južnoafrički rand),
				'few' => q(južnoafrička randa),
				'one' => q(južnoafrički rand),
				'other' => q(južnoafričkih randa),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambijska kvača \(1968–2012\)),
				'few' => q(zambijske kvače \(1968–2012\)),
				'one' => q(zambijska kvača \(1968–2012\)),
				'other' => q(zambijske kvače \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zambijska kvača),
				'few' => q(zambijske kvače),
				'one' => q(zambijska kvača),
				'other' => q(zambijskih kvača),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zairski novi zair \(1993–1998\)),
				'few' => q(zairska nova zaira \(1993–1998\)),
				'one' => q(zairski novi zair \(1993–1998\)),
				'other' => q(zairskih novih zaira \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairski zair \(1971–1993\)),
				'few' => q(zairska zaira \(1971–1993\)),
				'one' => q(zairski zair \(1971–1993\)),
				'other' => q(zairskih zaira \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabvejski dolar \(1980–2008\)),
				'few' => q(zimbabvejska dolara \(1980–2008\)),
				'one' => q(zimbabvejski dolar \(1980–2008\)),
				'other' => q(zimbabvejski dolari \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabvejski dolar \(2009\)),
				'few' => q(zimbabvejska dolara \(2009\)),
				'one' => q(zimbabvejski dolaz \(2009\)),
				'other' => q(zimbabvejskih dolara \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabvejski dolar \(2008\)),
				'few' => q(zimbabvejska dolara \(2008\)),
				'one' => q(zimbabvejski dolaz \(2008\)),
				'other' => q(zimbabvejskih dolara \(2008\)),
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
							'jan',
							'feb',
							'mar',
							'apr',
							'maj',
							'jun',
							'jul',
							'avg',
							'sep',
							'okt',
							'nov',
							'dec'
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
							'mart',
							'april',
							'maj',
							'juni',
							'juli',
							'avgust',
							'septembar',
							'oktobar',
							'novembar',
							'decembar'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'feb',
							'mar',
							'apr',
							'maj',
							'jun',
							'jul',
							'avg',
							'sep',
							'okt',
							'nov',
							'dec'
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
							'mart',
							'april',
							'maj',
							'juni',
							'juli',
							'avgust',
							'septembar',
							'oktobar',
							'novembar',
							'decembar'
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
							'muh.',
							'saf.',
							'rab. i',
							'rab. ii',
							'džum. i',
							'džum. ii',
							'redž.',
							'ša.',
							'ram.',
							'še.',
							'zul-k.',
							'zul-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharem',
							'safer',
							'rabiʻ i',
							'rabiʻ ii',
							'džumade i',
							'džumade ii',
							'redžeb',
							'šaʻban',
							'ramazan',
							'ševal',
							'zul-kade',
							'zul-hidže'
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
					abbreviated => {0 => 'KV1',
						1 => 'KV2',
						2 => 'KV3',
						3 => 'KV4'
					},
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
					},
					wide => {0 => 'Prvi kvartal',
						1 => 'Drugi kvartal',
						2 => 'Treći kvartal',
						3 => 'Četvrti kvartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'KV1',
						1 => 'KV2',
						2 => 'KV3',
						3 => 'KV4'
					},
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
					},
					wide => {0 => 'Prvi kvartal',
						1 => 'Drugi kvartal',
						2 => 'Treći kvartal',
						3 => 'Četvrti kvartal'
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
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					'pm' => q{popodne},
					'noon' => q{podne},
					'afternoon1' => q{poslijepodne},
					'midnight' => q{ponoć},
					'morning1' => q{ujutro},
					'night1' => q{po noći},
					'am' => q{prijepodne},
					'evening1' => q{navečer},
				},
				'narrow' => {
					'pm' => q{popodne},
					'noon' => q{podne},
					'midnight' => q{ponoć},
					'afternoon1' => q{poslijepodne},
					'night1' => q{po noći},
					'morning1' => q{ujutro},
					'am' => q{prijepodne},
					'evening1' => q{navečer},
				},
				'wide' => {
					'pm' => q{popodne},
					'noon' => q{podne},
					'afternoon1' => q{poslijepodne},
					'midnight' => q{ponoć},
					'morning1' => q{ujutro},
					'night1' => q{po noći},
					'am' => q{prijepodne},
					'evening1' => q{navečer},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'noon' => q{podne},
					'pm' => q{popodne},
					'afternoon1' => q{poslijepodne},
					'midnight' => q{ponoć},
					'night1' => q{po noći},
					'morning1' => q{ujutro},
					'evening1' => q{navečer},
					'am' => q{prijepodne},
				},
				'narrow' => {
					'morning1' => q{ujutro},
					'night1' => q{po noći},
					'evening1' => q{navečer},
					'am' => q{prijepodne},
					'noon' => q{podne},
					'pm' => q{popodne},
					'midnight' => q{ponoć},
					'afternoon1' => q{poslijepodne},
				},
				'wide' => {
					'night1' => q{po noći},
					'morning1' => q{ujutro},
					'am' => q{prijepodne},
					'evening1' => q{navečer},
					'pm' => q{popodne},
					'noon' => q{podne},
					'midnight' => q{ponoć},
					'afternoon1' => q{poslijepodne},
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'p. n. e.',
				'1' => 'n. e.'
			},
			narrow => {
				'0' => 'p.n.e.',
				'1' => 'n.e.'
			},
			wide => {
				'0' => 'prije nove ere',
				'1' => 'nove ere'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'japanese' => {
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
			'full' => q{E, d.M.y.},
			'long' => q{d.M.y.},
			'medium' => q{d.M.y.},
			'short' => q{d.M.y.},
		},
		'generic' => {
			'full' => q{EEEE, dd. MMMM y. G},
			'long' => q{dd. MMMM y. G},
			'medium' => q{dd.MM.y. G},
			'short' => q{dd.MM.y. GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y.},
			'long' => q{d. MMMM y.},
			'medium' => q{d. MMM y.},
			'short' => q{d.M.yy.},
		},
		'hebrew' => {
		},
		'islamic' => {
			'full' => q{EEEE, dd. MMMM y. G},
			'long' => q{dd. MMMM y. G},
			'medium' => q{dd.MM.y. G},
			'short' => q{dd.MM.y. G},
		},
		'japanese' => {
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
		'islamic' => {
		},
		'japanese' => {
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
		'generic' => {
			'full' => q{{1} 'u' {0}},
			'long' => q{{1} 'u' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'u' {0}},
			'long' => q{{1} 'u' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{MMM y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{W. 'sedmica' 'u' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d. M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
			ms => q{mm:ss},
			y => q{y.},
			yM => q{MM/y},
			yMEd => q{E, d.M.y.},
			yMM => q{M/y},
			yMMM => q{MMM y.},
			yMMMEd => q{E, d. MMM y.},
			yMMMM => q{LLLL y.},
			yMMMd => q{d. MMM y.},
			yMd => q{d.M.y.},
			yQQQ => q{QQQ y.},
			yQQQQ => q{QQQQ y.},
			yw => q{w. 'sedmica' 'u' y.},
		},
		'islamic' => {
			Ed => q{E, dd.},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd.MM.},
			MMM => q{LLL},
			MMMEd => q{E, dd. MMM},
			MMMd => q{dd. MMM},
			Md => q{dd.MM.},
			d => q{d},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			ms => q{mm:ss},
			y => q{y. G},
			yM => q{MM.y. G},
			yMEd => q{E, dd.MM.y. G},
			yMMM => q{MMM y. G},
			yMMMEd => q{E, dd. MMM y. G},
			yMMMd => q{dd. MMM y. G},
			yMd => q{dd.MM.y. G},
			yQQQ => q{y G QQQ},
			yQQQQ => q{y G QQQQ},
		},
		'roc' => {
			M => q{L.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			d => q{d.},
		},
		'japanese' => {
			Ed => q{E, d.},
			Gy => q{y. GGG},
			MEd => q{E, d. M.},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			Md => q{d. M.},
			y => q{y. GGG},
			yM => q{M. y. GGGGG},
			yMEd => q{E, d. M. y. GGGGG},
			yMMM => q{LLL y. GGGGG},
			yMMMEd => q{E, d. MMM y. GGGGG},
			yMMMd => q{d. MMM y. GGGGG},
			yMd => q{d. M. y. GGGGG},
			yQQQ => q{QQQ y. GGGGG},
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
			GyMMM => q{MMM y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			H => q{H},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			ms => q{mm:ss},
			y => q{y. G},
			yyyy => q{y. G},
			yyyyM => q{MM/y G},
			yyyyMEd => q{E, d.M.y. G},
			yyyyMMM => q{MMM y. G},
			yyyyMMMEd => q{E, d. MMM y. G},
			yyyyMMMM => q{LLLL y. G},
			yyyyMMMd => q{d. MMM y. G},
			yyyyMd => q{d.M.y. G},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
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
				H => q{HH – HH'h'},
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
				M => q{M–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d. M – d. M.},
				d => q{d. M – d. M.},
			},
			d => {
				d => q{d–d.},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h'h' a},
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
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d.M.y. – E, d.M.y.},
				d => q{E, d.M.y. – E, d.M.y.},
				y => q{E, d.M.y. – E, d.M.y.},
			},
			yMMM => {
				M => q{LLL – LLL y.},
				y => q{LLL y. – LLL y.},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y.},
				d => q{E, d. – E, d. MMM y.},
				y => q{E, d. MMM y. – E, d. MMM y.},
			},
			yMMMM => {
				M => q{LLLL – LLLL y.},
				y => q{LLLL y. – LLLL y.},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y.},
				d => q{d. – d. MMM y.},
				y => q{d. MMM y. – d. MMM y.},
			},
			yMd => {
				M => q{d.M.y. – d.M.y.},
				d => q{d.M.y. – d.M.y.},
				y => q{d.M.y. – d.M.y.},
			},
		},
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
				M => q{M. – M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{LLL–LLL},
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
				M => q{d.M. – d.M.},
				d => q{d.M. – d.M.},
			},
			d => {
				d => q{d. – d.},
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
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, d.M.y. – E, d.M.y. G},
				d => q{E, d.M.y. – E, d.M.y. G},
				y => q{E, d.M.y. – E, d.M.y. G},
			},
			yMMM => {
				M => q{LLL–LLL y. G},
				y => q{LLL y. – LLL y. G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y. G},
				d => q{E, dd. – E, dd. MMM y. G},
				y => q{E, d. MMM y. – E, d. MMM y. G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y. G},
				y => q{LLLL y. – LLLL y. G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y. G},
				d => q{d. – d. MMM y. G},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{d.M.y. – d.M.y. G},
				d => q{d.M.y. – d.M.y. G},
				y => q{d.M.y. – d.M.y. G},
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
		gmtFormat => q(GMT {0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0}, ljetno vrijeme),
		regionFormat => q({0}, standardno vrijeme),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre letnje računanje vremena#,
				'generic' => q#Acre vreme#,
				'standard' => q#Acre standardno vreme#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistansko vrijeme#,
			},
		},
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
			exemplarCity => q#Algiers#,
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
			exemplarCity => q#Kazablanka#,
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
			exemplarCity => q#Mogadiš#,
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
		'Africa_Central' => {
			long => {
				'standard' => q#Centralnoafričko vrijeme#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Istočnoafričko vrijeme#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Južnoafričko standardno vrijeme#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Zapadnoafričko ljetno vrijeme#,
				'generic' => q#Zapadnoafričko vrijeme#,
				'standard' => q#Zapadnoafričko standardno vrijeme#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aljaskansko ljetno vrijeme#,
				'generic' => q#Aljaskansko vrijeme#,
				'standard' => q#Aljaskansko standardno vrijeme#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatu letnje računanje vremena#,
				'generic' => q#Almatu vreme#,
				'standard' => q#Almatu standardno vreme#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonsko ljetno vrijeme#,
				'generic' => q#Amazonsko vrijeme#,
				'standard' => q#Amazonsko standardno vrijeme#,
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
			exemplarCity => q#Antigva#,
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
			exemplarCity => q#Asuncion#,
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
			exemplarCity => q#Kurasao#,
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
			exemplarCity => q#Gvadalupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
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
		'America_Central' => {
			long => {
				'daylight' => q#Sjevernoameričko centralno ljetno vrijeme#,
				'generic' => q#Sjevernoameričko centralno vrijeme#,
				'standard' => q#Sjevernoameričko centralno standardno vrijeme#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Sjevernoameričko istočno ljetno vrijeme#,
				'generic' => q#Sjevernoameričko istočno vrijeme#,
				'standard' => q#Sjevernoameričko istočno standardno vrijeme#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Sjevernoameričko planinsko ljetno vrijeme#,
				'generic' => q#Sjevernoameričko planinsko vrijeme#,
				'standard' => q#Sjevernoameričko planinsko standardno vrijeme#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Sjevernoameričko pacifičko ljetno vrijeme#,
				'generic' => q#Sjevernoameričko pacifičko vrijeme#,
				'standard' => q#Sjevernoameričko pacifičko standardno vrijeme#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadir letnje računanje vremena#,
				'generic' => q#Anadir vreme#,
				'standard' => q#Anadir standardno vreme#,
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
				'daylight' => q#Apijsko ljetno vrijeme#,
				'generic' => q#Apijsko vrijeme#,
				'standard' => q#Apijsko standardno vrijeme#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Akvtau letnje računanje vremena#,
				'generic' => q#Akvtau vreme#,
				'standard' => q#Akvtau standardno vreme#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Akvtobe letnje računanje vremena#,
				'generic' => q#Akvtobe vreme#,
				'standard' => q#Akvtobe standardno vreme#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabijsko ljetno vrijeme#,
				'generic' => q#Arabijsko vrijeme#,
				'standard' => q#Arabijsko standardno vrijeme#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinsko ljetno vrijeme#,
				'generic' => q#Argentinsko vrijeme#,
				'standard' => q#Argentinsko standardno vrijeme#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Zapadnoargentinsko ljetno vrijeme#,
				'generic' => q#Zapadnoargentinsko vrijeme#,
				'standard' => q#Zapadnoargentinsko standardno vrijeme#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armensko ljetno vrijeme#,
				'generic' => q#Armensko vrijeme#,
				'standard' => q#Armensko standardno vrijeme#,
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
			exemplarCity => q#Akutobe#,
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
			exemplarCity => q#Bejrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruneji#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Čojbalsan#,
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
			exemplarCity => q#Džajapura#,
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
			exemplarCity => q#Kučing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
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
			exemplarCity => q#Muskat#,
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
			exemplarCity => q#Pnom Pen#,
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
			exemplarCity => q#Rangun#,
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
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šangaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
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
			exemplarCity => q#Thimphu#,
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
			exemplarCity => q#Vijentijan#,
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
				'daylight' => q#Sjevernoameričko atlantsko ljetno vrijeme#,
				'generic' => q#Sjevernoameričko atlantsko vrijeme#,
				'standard' => q#Sjevernoameričko atlantsko standardno vrijeme#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azori#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rejkjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#South Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sveta Helena#,
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
			exemplarCity => q#Lord Hau#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidnej#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Centralnoaustralijsko ljetno vrijeme#,
				'generic' => q#Centralnoaustralijsko vrijeme#,
				'standard' => q#Centralnoaustralijsko standardno vrijeme#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australijsko centralnozapadno ljetno vrijeme#,
				'generic' => q#Australijsko centralno zapadno vrijeme#,
				'standard' => q#Australijsko centralnozapadno standardno vrijeme#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Istočnoaustralijsko ljetno vrijeme#,
				'generic' => q#Istočnoaustralijsko vrijeme#,
				'standard' => q#Istočnoaustralijsko standardno vrijeme#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Zapadnoaustralijsko ljetno vrijeme#,
				'generic' => q#Zapadnoaustralijsko vrijeme#,
				'standard' => q#Zapadnoaustralijsko standardno vrijeme#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbejdžansko ljetno vrijeme#,
				'generic' => q#Azerbejdžansko vrijeme#,
				'standard' => q#Azerbejdžansko standardno vrijeme#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorsko ljetno vrijeme#,
				'generic' => q#Azorsko vrijeme#,
				'standard' => q#Azorsko standardno vrijeme#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeško ljetno vrijeme#,
				'generic' => q#Bangladeško vrijeme#,
				'standard' => q#Bangladeško standardno vrijeme#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butansko vrijeme#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivijsko vrijeme#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brazilijsko ljetno vrijeme#,
				'generic' => q#Brazilijsko vrijeme#,
				'standard' => q#Brazilijsko standardno vrijeme#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunejsko vrijeme#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Zelenortsko ljetno vrijeme#,
				'generic' => q#Zelenortsko vrijeme#,
				'standard' => q#Zelenortsko standardno vrijeme#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Čamorsko standardno vrijeme#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Čatamsko ljetno vrijeme#,
				'generic' => q#Čatamsko vrijeme#,
				'standard' => q#Čatamsko standardno vrijeme#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Čileansko ljetno vrijeme#,
				'generic' => q#Čileansko vrijeme#,
				'standard' => q#Čileansko standardno vrijeme#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kinesko ljetno vrijeme#,
				'generic' => q#Kinesko vrijeme#,
				'standard' => q#Kinesko standardno vrijeme#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Čojbalsansko ljetno vrijeme#,
				'generic' => q#Čojbalsansko vrijeme#,
				'standard' => q#Čojbalsansko standardno vrijeme#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Vrijeme na Božićnom Ostrvu#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Vrijeme na Ostrvima Kokos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbijsko ljetno vrijeme#,
				'generic' => q#Kolumbijsko vrijeme#,
				'standard' => q#Kolumbijsko standardno vrijeme#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Poluljetno vrijeme na Kukovim ostrvima#,
				'generic' => q#Vrijeme na Kukovim ostrvima#,
				'standard' => q#Standardno vrijeme na Kukovim ostrvima#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubansko ljetno vrijeme#,
				'generic' => q#Kubansko vrijeme#,
				'standard' => q#Kubansko standardno vrijeme#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Vrijeme stanice Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Vrijeme stanice Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Istočnotimorsko vrijeme#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Uskršnjeostrvsko ljetno vrijeme#,
				'generic' => q#Uskršnjeostrvsko vrijeme#,
				'standard' => q#Uskršnjeostrvsko standardno vrijeme#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvadorsko vrijeme#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinirano svjetsko vrijeme#,
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
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atina#,
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
			exemplarCity => q#Brisel#,
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
			exemplarCity => q#Dablin#,
			long => {
				'daylight' => q#Irsko standardno vrijeme#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernzi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrvo Man#,
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
				'daylight' => q#Britansko ljetno vrijeme#,
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
			exemplarCity => q#Simferopolj#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skoplje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Štokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
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
			exemplarCity => q#Cirih#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Centralnoevropsko ljetno vrijeme#,
				'generic' => q#Centralnoevropsko vrijeme#,
				'standard' => q#Centralnoevropsko standardno vrijeme#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Istočnoevropsko ljetno vrijeme#,
				'generic' => q#Istočnoevropsko vrijeme#,
				'standard' => q#Istočnoevropsko standardno vrijeme#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Dalekoistočnoevropsko vrijeme#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Zapadnoevropsko ljetno vrijeme#,
				'generic' => q#Zapadnoevropsko vrijeme#,
				'standard' => q#Zapadnoevropsko standardno vrijeme#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklandsko ljetno vrijeme#,
				'generic' => q#Folklandsko vrijeme#,
				'standard' => q#Folklandsko standardno vrijeme#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidžijsko ljetno vrijeme#,
				'generic' => q#Vrijeme na Fidžiju#,
				'standard' => q#Standardno vrijeme na Fidžiju#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francuskogvajansko vrijeme#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Vrijeme na Francuskoj Južnoj Teritoriji i Antarktiku#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Griničko vrijeme#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagosko vrijeme#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambijersko vrijeme#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzijsko ljetno vrijeme#,
				'generic' => q#Gruzijsko vrijeme#,
				'standard' => q#Gruzijsko standardno vrijeme#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Vrijeme na Gilbertovim ostrvima#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Istočnogrenlandsko ljetno vrijeme#,
				'generic' => q#Istočnogrenlandsko vrijeme#,
				'standard' => q#Istočnogrenlandsko standardno vrijeme#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Zapadnogrenlandsko ljetno vrijeme#,
				'generic' => q#Zapadnogrenlandsko vrijeme#,
				'standard' => q#Zapadnogrenlandsko standardno vrijeme#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam standardno vreme#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Zalivsko standardno vrijeme#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gvajansko vrijeme#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havajsko-aleućansko ljetno vrijeme#,
				'generic' => q#Havajsko-aleućansko vrijeme#,
				'standard' => q#Havajsko-aleućansko standardno vrijeme#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkonško ljetno vrijeme#,
				'generic' => q#Hongkonško vrijeme#,
				'standard' => q#Hongkonško standardno vrijeme#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovdsko ljetno vrijeme#,
				'generic' => q#Hovdsko vrijeme#,
				'standard' => q#Hovdsko standardno vrijeme#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indijsko standardno vrijeme#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Božićno ostrvo#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosova ostrva#,
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
			exemplarCity => q#Maldivi#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricijus#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Vrijeme na Indijskom okeanu#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokinesko vrijeme#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Centralnoindonezijsko vrijeme#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Istočnoindonezijsko vrijeme#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Zapadnoindonezijsko vrijeme#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iransko ljetno vrijeme#,
				'generic' => q#Iransko vrijeme#,
				'standard' => q#Iransko standardno vrijeme#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsko ljetno vrijeme#,
				'generic' => q#Irkutsko vrijeme#,
				'standard' => q#Irkutsko standardno vrijeme#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izraelsko ljetno vrijeme#,
				'generic' => q#Izraelsko vrijeme#,
				'standard' => q#Izraelsko standardno vrijeme#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japansko ljetno vrijeme#,
				'generic' => q#Japansko vrijeme#,
				'standard' => q#Japansko standardno vrijeme#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamčatski letnje računanje vremena#,
				'generic' => q#Petropavlovsk-Kamčatski vreme#,
				'standard' => q#Petropavlovsk-Kamčatski standardno vreme#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Istočnokazahstansko vrijeme#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Zapadnokazahstansko vrijeme#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejsko ljetno vrijeme#,
				'generic' => q#Korejsko vrijeme#,
				'standard' => q#Korejsko standardno vrijeme#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsko ljetno vrijeme#,
				'generic' => q#Krasnojarsko vrijeme#,
				'standard' => q#Krasnojarsko standardno vrijeme#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistansko vrijeme#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lanka vreme#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Vrijeme na Ostrvima Lajn#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ljetno vrijeme na Ostrvu Lord Hau#,
				'generic' => q#Vrijeme na Ostrvu Lord Hau#,
				'standard' => q#Standardno vrijeme na Ostrvu Lord Hau#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Makao letnje računanje vremena#,
				'generic' => q#Makao vreme#,
				'standard' => q#Makao standardno vreme#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Makvori#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadansko ljetno vrijeme#,
				'generic' => q#Magadansko vrijeme#,
				'standard' => q#Magadansko standardno vrijeme#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malezijsko vrijeme#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivsko vrijeme#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Vrijeme na Ostrvima Markiz#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Vrijeme na Maršalovim ostrvima#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauricijsko ljetno vrijeme#,
				'generic' => q#Mauricijsko vrijeme#,
				'standard' => q#Mauricijsko standardno vrijeme#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Vrijeme stanice Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Sjeverozapadno meksičko ljetno vrijeme#,
				'generic' => q#Sjeverozapadno meksičko vrijeme#,
				'standard' => q#Sjeverozapadno meksičko standardno vrijeme#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksičko pacifičko ljetno vrijeme#,
				'generic' => q#Meksičko pacifičko vrijeme#,
				'standard' => q#Meksičko pacifičko standardno vrijeme#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulanbatorsko ljetno vrijeme#,
				'generic' => q#Ulanbatorsko vrijeme#,
				'standard' => q#Ulanbatorsko standardno vrijeme#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskovsko ljetno vrijeme#,
				'generic' => q#Moskovsko vrijeme#,
				'standard' => q#Moskovsko standardno vrijeme#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mijanmarsko vrijeme#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalsko vrijeme#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Novokaledonijsko ljetno vrijeme#,
				'generic' => q#Novokaledonijsko vrijeme#,
				'standard' => q#Novokaledonijsko standardno vrijeme#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Novozelandsko ljetno vrijeme#,
				'generic' => q#Novozelandsko vrijeme#,
				'standard' => q#Novozelandsko standardno vrijeme#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Njufaundlendsko ljetno vrijeme#,
				'generic' => q#Njufaundlendsko vrijeme#,
				'standard' => q#Njufaundlendsko standardno vrijeme#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolško vrijeme#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ljetno vrijeme na ostrvu Fernando di Noronja#,
				'generic' => q#Vrijeme na ostrvu Fernando di Noronja#,
				'standard' => q#Standardno vrijeme na ostrvu Fernando di Noronja#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Severna Marijanska Ostrva vreme#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsko ljetno vrijeme#,
				'generic' => q#Novosibirsko vrijeme#,
				'standard' => q#Novosibirsko standardno vrijeme#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsko ljetno vrijeme#,
				'generic' => q#Omsko vrijeme#,
				'standard' => q#Omsko standardno vrijeme#,
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
			exemplarCity => q#Easter#,
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
			exemplarCity => q#Pitkern#,
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
			exemplarCity => q#Valis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistansko ljetno vrijeme#,
				'generic' => q#Pakistansko vrijeme#,
				'standard' => q#Pakistansko standardno vrijeme#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Vrijeme na Papui Novoj Gvineji#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragvajsko ljetno vrijeme#,
				'generic' => q#Paragvajsko vrijeme#,
				'standard' => q#Paragvajsko standardno vrijeme#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruansko ljetno vrijeme#,
				'generic' => q#Peruansko vrijeme#,
				'standard' => q#Peruansko standardno vrijeme#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipinsko ljetno vrijeme#,
				'generic' => q#Filipinsko vrijeme#,
				'standard' => q#Filipinsko standardno vrijeme#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Vrijeme na Ostrvima Finiks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ljetno vrijeme na Ostrvima Sveti Petar i Mikelon#,
				'generic' => q#Vrijeme na Ostrvima Sveti Petar i Mikelon#,
				'standard' => q#Standardno vrijeme na Ostrvima Sveti Petar i Mikelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Vrijeme na Ostrvima Pitkern#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjongjanško vrijeme#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kizilorda letnje računanje vremena#,
				'generic' => q#Kizilorda vreme#,
				'standard' => q#Kizilorda standardno vreme#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunionsko vrijeme#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Vrijeme stanice Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalinsko ljetno vrijeme#,
				'generic' => q#Sahalinsko vrijeme#,
				'standard' => q#Sahalinsko standardno vrijeme#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara letnje računanje vremena#,
				'generic' => q#Samara vreme#,
				'standard' => q#Samara standardno vreme#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoansko ljetno vrijeme#,
				'generic' => q#Samoansko vrijeme#,
				'standard' => q#Samoansko standardno vrijeme#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Sejšelsko vrijeme#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapursko standardno vrijeme#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Vrijeme na Solomonskim ostrvima#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Južnodžordžijsko vrijeme#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamsko vrijeme#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Vrijeme stanice Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahićansko vrijeme#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tajpejsko ljetno vrijeme#,
				'generic' => q#Tajpejsko vrijeme#,
				'standard' => q#Tajpejsko standardno vrijeme#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistansko vrijeme#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongansko ljetno vrijeme#,
				'generic' => q#Tongansko vrijeme#,
				'standard' => q#Tongansko standardno vrijeme#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Čučko vrijeme#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistansko ljetno vrijeme#,
				'generic' => q#Turkmenistansko vrijeme#,
				'standard' => q#Turkmenistansko standardno vrijeme#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvaluansko vrijeme#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugvajsko ljetno vrijeme#,
				'generic' => q#Urugvajsko vrijeme#,
				'standard' => q#Urugvajsko standardno vrijeme#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistansko ljetno vrijeme#,
				'generic' => q#Uzbekistansko vrijeme#,
				'standard' => q#Uzbekistansko standardno vrijeme#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatuansko ljetno vrijeme#,
				'generic' => q#Vanuatuansko vrijeme#,
				'standard' => q#Vanuatuansko standardno vrijeme#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venecuelansko vrijeme#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostočko ljetno vrijeme#,
				'generic' => q#Vladivostočko vrijeme#,
				'standard' => q#Vladivostočko standardno vrijeme#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgogradsko ljetno vrijeme#,
				'generic' => q#Volgogradsko vrijeme#,
				'standard' => q#Volgogradsko standardno vrijeme#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vrijeme stanice Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Vrijeme na Ostrvu Vejk#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Vrijeme na Ostrvima Valis i Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsko ljetno vrijeme#,
				'generic' => q#Jakutsko vrijeme#,
				'standard' => q#Jakutsko standardno vrijeme#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburško ljetno vrijeme#,
				'generic' => q#Jekaterinburško vrijeme#,
				'standard' => q#Jekaterinburško standardno vrijeme#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
