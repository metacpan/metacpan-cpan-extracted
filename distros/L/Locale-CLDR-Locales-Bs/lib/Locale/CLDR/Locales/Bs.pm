=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bs - Package for language Bosnian

=cut

package Locale::CLDR::Locales::Bs;
# This file auto generated from Data\common\main\bs.xml
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
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arapski',
 				'ar_001' => 'moderni standardni arapski',
 				'arc' => 'aramejski',
 				'arn' => 'mapuški',
 				'arp' => 'arapaho',
 				'ars' => 'najdski arapski',
 				'arw' => 'aravak',
 				'as' => 'asamski',
 				'asa' => 'asu',
 				'ast' => 'asturijski',
 				'atj' => 'atikamekw',
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
 				'bgc' => 'harianvi',
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
 				'ccp' => 'čakma',
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
 				'chr' => 'čeroki',
 				'chy' => 'čejenski',
 				'ckb' => 'centralnokurdski',
 				'clc' => 'chilcotin',
 				'co' => 'korzikanski',
 				'cop' => 'koptski',
 				'cr' => 'kri',
 				'crg' => 'mičif',
 				'crh' => 'krimski turski',
 				'crj' => 'jugoistočni kri',
 				'crk' => 'ravničarski kri',
 				'crl' => 'sjeveroistočni kri',
 				'crm' => 'mus kri',
 				'crr' => 'sjevernokarolinški algonkvijski',
 				'crs' => 'seselva kreolski francuski',
 				'cs' => 'češki',
 				'csb' => 'kašubijanski',
 				'csw' => 'močvarni kri',
 				'cu' => 'staroslavenski',
 				'cv' => 'čuvaški',
 				'cy' => 'velški',
 				'da' => 'danski',
 				'dak' => 'dakota',
 				'dar' => 'dargva',
 				'dav' => 'taita',
 				'de' => 'njemački',
 				'de_CH' => 'visoki njemački (Švicarska)',
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
 				'enm' => 'srednjovjekovni engleski',
 				'eo' => 'esperanto',
 				'es' => 'španski',
 				'et' => 'estonski',
 				'eu' => 'baskijski',
 				'ewo' => 'evondo',
 				'fa' => 'perzijski',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finski',
 				'fil' => 'filipino',
 				'fj' => 'fidžijski',
 				'fo' => 'farski',
 				'fon' => 'fon',
 				'fr' => 'francuski',
 				'frc' => 'kajunski francuski',
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
 				'hax' => 'južni haida',
 				'he' => 'hebrejski',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hingleski',
 				'hil' => 'hiligajnon',
 				'hit' => 'hitite',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'hrvatski',
 				'hsb' => 'gornjolužičkosrpski',
 				'ht' => 'haićanski kreolski',
 				'hu' => 'mađarski',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
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
 				'ikt' => 'zapadnokanadski inuktitut',
 				'ilo' => 'iloko',
 				'inh' => 'ingušetski',
 				'io' => 'ido',
 				'is' => 'islandski',
 				'it' => 'italijanski',
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
 				'kgp' => 'kaingang',
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
 				'kwk' => 'kvakvala',
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
 				'lij' => 'ligurski',
 				'lil' => 'liluet',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardski',
 				'ln' => 'lingala',
 				'lo' => 'laoski',
 				'lol' => 'mongo',
 				'lou' => 'luizijanski kreolski',
 				'loz' => 'lozi',
 				'lrc' => 'sjeverni luri',
 				'lsm' => 'samia',
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
 				'moe' => 'innu-aimun',
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
 				'nl' => 'nizozemski',
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
 				'ojb' => 'sjeverozapadni ojibva',
 				'ojc' => 'centralni ojibva',
 				'ojs' => 'odži kri',
 				'ojw' => 'zapadni ojibva',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'odija',
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
 				'pis' => 'pidžin',
 				'pl' => 'poljski',
 				'pon' => 'ponpejski',
 				'pqm' => 'malisit-pasamakvodi',
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
 				'rhg' => 'rohindža',
 				'rm' => 'retoromanski',
 				'rn' => 'rundi',
 				'ro' => 'rumunski',
 				'ro_MD' => 'moldavski',
 				'rof' => 'rombo',
 				'rom' => 'romani',
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
 				'slh' => 'južni lašutsid',
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
 				'str' => 'ravničarski sališki',
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
 				'tce' => 'južni tučoni',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadžički',
 				'tgx' => 'tagiš',
 				'th' => 'tajlandski',
 				'tht' => 'tahltanski',
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
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turski',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimšian',
 				'tt' => 'tatarski',
 				'ttm' => 'sjeverni tučoni',
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
 				'vec' => 'venecijanski',
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
 				'wuu' => 'Wu kineski',
 				'xal' => 'kalmik',
 				'xh' => 'hosa',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japeški',
 				'yav' => 'jangben',
 				'ybb' => 'jemba',
 				'yi' => 'jidiš',
 				'yo' => 'jorubanski',
 				'yrl' => 'ningatu',
 				'yue' => 'kantonski',
 				'yue@alt=menu' => 'kineski, kantonski',
 				'za' => 'zuang',
 				'zap' => 'zapotečki',
 				'zbl' => 'blis simboli',
 				'zen' => 'zenaga',
 				'zgh' => 'standardni marokanski tamazigt',
 				'zh' => 'kineski',
 				'zh@alt=menu' => 'kineski (standardni)',
 				'zh_Hans' => 'kineski (pojednostavljeni)',
 				'zh_Hans@alt=long' => 'kineski (pojednostavljeni standardni)',
 				'zh_Hant' => 'kineski (tradicionalni)',
 				'zh_Hant@alt=long' => 'kineski (tradicionalni standardni)',
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
			'Adlm' => 'adlam pismo',
 			'Afak' => 'afaka pismo',
 			'Aghb' => 'kavkazijsko albansko pismo',
 			'Ahom' => 'ahom pismo',
 			'Arab' => 'arapsko pismo',
 			'Arab@alt=variant' => 'perzijsko-arapsko pismo',
 			'Aran' => 'nastalik pismo',
 			'Armi' => 'imperijsko aramejsko pismo',
 			'Armn' => 'armensko pismo',
 			'Avst' => 'avestansko pismo',
 			'Bali' => 'balijsko pismo',
 			'Bamu' => 'bamum pismo',
 			'Bass' => 'bassa vah pismo',
 			'Batk' => 'batak pismo',
 			'Beng' => 'bengalsko pismo',
 			'Bhks' => 'baiksuki pismo',
 			'Blis' => 'blisimbolično pismo',
 			'Bopo' => 'pismo bopomofo',
 			'Brah' => 'bramansko pismo',
 			'Brai' => 'brajevo pismo',
 			'Bugi' => 'buginsko pismo',
 			'Buhd' => 'buhidsko pismo',
 			'Cakm' => 'čakmansko pismo',
 			'Cans' => 'ujedinjeni kanadski aboridžinski slogovi',
 			'Cari' => 'karijsko pismo',
 			'Cham' => 'čamsko pismo',
 			'Cher' => 'čeroki pismo',
 			'Chrs' => 'korasmijansko pismo',
 			'Cirt' => 'cirt pismo',
 			'Copt' => 'koptičko pismo',
 			'Cpmn' => 'ciprominojsko pismo',
 			'Cprt' => 'kiparsko pismo',
 			'Cyrl' => 'ćirilica',
 			'Cyrs' => 'staroslovenska crkvena ćirilica',
 			'Deva' => 'pismo devanagari',
 			'Diak' => 'dives akuru pismo',
 			'Dogr' => 'dogra pismo',
 			'Dsrt' => 'dezeret pismo',
 			'Dupl' => 'duploaje stenografija',
 			'Egyd' => 'egipatsko narodno pismo',
 			'Egyh' => 'egipatsko hijeratsko pismo',
 			'Egyp' => 'egipatski hijeroglifi',
 			'Elba' => 'elbasansko pismo',
 			'Elym' => 'elimaično pismo',
 			'Ethi' => 'etiopsko pismo',
 			'Geok' => 'gruzijsko khutsuri pismo',
 			'Geor' => 'gruzijsko pismo',
 			'Glag' => 'glagoljica',
 			'Gong' => 'gundžala gondi pismo',
 			'Gonm' => 'masaram gondi pismo',
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
 			'Hatr' => 'hatran pismo',
 			'Hebr' => 'hebrejsko pismo',
 			'Hira' => 'pismo hiragana',
 			'Hluw' => 'anatolijski hijeroglifi',
 			'Hmng' => 'pahawh hmong pismo',
 			'Hmnp' => 'nijakeng puaču hmong pismo',
 			'Hrkt' => 'katakana ili hiragana',
 			'Hung' => 'staromađarsko pismo',
 			'Inds' => 'induško pismo',
 			'Ital' => 'staro italsko pismo',
 			'Jamo' => 'pismo jamo',
 			'Java' => 'javansko pismo',
 			'Jpan' => 'japansko pismo',
 			'Jurc' => 'jurchen pismo',
 			'Kali' => 'kajah li pismo',
 			'Kana' => 'pismo katakana',
 			'Kawi' => 'kavi pismo',
 			'Khar' => 'karošti pismo',
 			'Khmr' => 'kmersko pismo',
 			'Khoj' => 'khojki pismo',
 			'Kits' => 'kitansko pismo malim slovima',
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
 			'Mahj' => 'mahadžani pismo',
 			'Maka' => 'makasar pismo',
 			'Mand' => 'mandeansko pismo',
 			'Mani' => 'manihejsko pismo',
 			'Marc' => 'marčensko pismo',
 			'Maya' => 'majanski hijeroglifi',
 			'Medf' => 'medefaidrinsko pismo',
 			'Mend' => 'mende pismo',
 			'Merc' => 'meroitski kurziv',
 			'Mero' => 'meroitik pismo',
 			'Mlym' => 'malajalamsko pismo',
 			'Modi' => 'modi pismo',
 			'Mong' => 'mongolsko pismo',
 			'Moon' => 'munova azbuka',
 			'Mroo' => 'mro pismo',
 			'Mtei' => 'meitei majek pismo',
 			'Mult' => 'multani pismo',
 			'Mymr' => 'mijanmarsko pismo',
 			'Nagm' => 'nag mundari pismo',
 			'Nand' => 'nandinagari pismo',
 			'Narb' => 'staro sjevernoarapsko pismo',
 			'Nbat' => 'nabatejsko pismo',
 			'Newa' => 'neva pismo',
 			'Nkgb' => 'naxi geba pismo',
 			'Nkoo' => 'n’ko pismo',
 			'Nshu' => 'nushu pismo',
 			'Ogam' => 'ogham pismo',
 			'Olck' => 'ol čiki pismo',
 			'Orkh' => 'orkhon pismo',
 			'Orya' => 'pismo orija',
 			'Osge' => 'osage pismo',
 			'Osma' => 'osmanja pismo',
 			'Ougr' => 'starougursko pismo',
 			'Palm' => 'palmyrene pismo',
 			'Pauc' => 'pau cin hau pismo',
 			'Perm' => 'staro permiksko pismo',
 			'Phag' => 'phags-pa pismo',
 			'Phli' => 'pisani pahlavi',
 			'Phlp' => 'psalter pahlavi pismo',
 			'Phlv' => 'pahlavi pismo',
 			'Phnx' => 'feničansko pismo',
 			'Plrd' => 'polard fonetsko pismo',
 			'Prti' => 'pisani partian',
 			'Qaag' => 'zavgji pismo',
 			'Rjng' => 'rejang pismo',
 			'Rohg' => 'hanifi pismo',
 			'Roro' => 'rongorongo pismo',
 			'Runr' => 'runsko pismo',
 			'Samr' => 'samaritansko pismo',
 			'Sara' => 'sarati pismo',
 			'Sarb' => 'staro južnoarapsko pismo',
 			'Saur' => 'sauraštra pismo',
 			'Sgnw' => 'znakovno pismo',
 			'Shaw' => 'šavian pismo',
 			'Shrd' => 'sharada pismo',
 			'Sidd' => 'sidam pismo',
 			'Sind' => 'khudawadi pismo',
 			'Sinh' => 'pismo sinhala',
 			'Sogd' => 'sogdian psmo',
 			'Sogo' => 'staro sogdian pismo',
 			'Sora' => 'sora sompeng pismo',
 			'Soyo' => 'sojombo pismo',
 			'Sund' => 'sundansko pismo',
 			'Sylo' => 'siloti nagri pismo',
 			'Syrc' => 'sirijsko pismo',
 			'Syre' => 'sirijsko estrangelo pismo',
 			'Syrj' => 'zapadnosirijsko pismo',
 			'Syrn' => 'istočnosirijsko pismo',
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
 			'Tglg' => 'tagalog pismo',
 			'Thaa' => 'pismo tana',
 			'Thai' => 'tajlandsko pismo',
 			'Tibt' => 'tibetansko pismo',
 			'Tirh' => 'tirhuta pismo',
 			'Tnsa' => 'tangsa pismo',
 			'Toto' => 'toto pismo',
 			'Ugar' => 'ugaritsko pismo',
 			'Vaii' => 'vai pismo',
 			'Visp' => 'vidljivi govor',
 			'Vith' => 'vitkuki pismo',
 			'Wara' => 'varang kshiti pismo',
 			'Wcho' => 'vančo pismo',
 			'Wole' => 'woleai pismo',
 			'Xpeo' => 'staropersijsko pismo',
 			'Xsux' => 'sumersko-akadsko kuneiform pismo',
 			'Yezi' => 'jezidi pismo',
 			'Yiii' => 'ji pismo',
 			'Zanb' => 'zanabazar četvrtasto pismo',
 			'Zinh' => 'nasljedno pismo',
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
 			'CK' => 'Kukova ostrva',
 			'CL' => 'Čile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Kolumbija',
 			'CP' => 'Ostrvo Clipperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Zelenortska Ostrva',
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
 			'GB' => 'Ujedinjeno Kraljevstvo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzija',
 			'GF' => 'Francuska Gvajana',
 			'GG' => 'Guernsey',
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
 			'HM' => 'Ostrvo Heard i arhipelag McDonald',
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
 			'IO@alt=chagos' => 'arhipelag Chagos',
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
 			'MK' => 'Sjeverna Makedonija',
 			'ML' => 'Mali',
 			'MM' => 'Mijanmar',
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
 			'NL' => 'Nizozemska',
 			'NO' => 'Norveška',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Novi Zeland',
 			'NZ@alt=variant' => 'Novi Zeland Aotearoa',
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
 			'SJ' => 'Svalbard i Jan Mayen',
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
 			'SZ' => 'Esvatini',
 			'SZ@alt=variant' => 'Svazilend',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Ostrva Turks i Kaikos',
 			'TD' => 'Čad',
 			'TF' => 'Francuske Južne Teritorije',
 			'TG' => 'Togo',
 			'TH' => 'Tajland',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Istočni Timor',
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
 			'US' => 'Sjedinjene Države',
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
 			'XA' => 'Pseudo naglasci',
 			'XB' => 'Pseudo bidi',
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
			'1901' => 'tradicionalna njemačka ortografija',
 			'1994' => 'standardizirana rezijanska ortografija',
 			'1996' => 'njemačka ortografija iz 1996.',
 			'1606NICT' => 'francuski iz kasnog srednjeg vijeka do 1606.',
 			'1694ACAD' => 'rani moderni francuski',
 			'1959ACAD' => 'Akademski',
 			'ABL1943' => 'ortografska pravila iz 1943.',
 			'AKUAPEM' => 'akuapem',
 			'ALALC97' => 'ALA-LC romanizacija, izdanje iz 1997.',
 			'ALUKU' => 'Aluku dijalekt',
 			'AO1990' => 'Portugalski jezički ortografski sporazum iz 1990.',
 			'ARANES' => 'aranes',
 			'AREVELA' => 'Istočni jermenski',
 			'AREVMDA' => 'Zapadno-jermenski',
 			'ARKAIKA' => 'arkaika',
 			'ASANTE' => 'asante',
 			'AUVERN' => 'auvern',
 			'BAKU1926' => 'Ujedinjeni turski latinični alfabet',
 			'BALANKA' => 'balanka',
 			'BARLA' => 'barla',
 			'BASICENG' => 'osnovni engleski',
 			'BAUDDHA' => 'buda',
 			'BISCAYAN' => 'biskajanski',
 			'BISKE' => 'San Đorđijo/Bila dijalekt',
 			'BOHORIC' => 'bohoričica',
 			'BOONT' => 'Buntling',
 			'BORNHOLM' => 'Bornholm',
 			'CISAUP' => 'Cisaup',
 			'COLB1945' => 'Portugalsko-brazilski ortografski kongres iz 1945.',
 			'CORNU' => 'Cornu',
 			'CREISS' => 'Creiss',
 			'DAJNKO' => 'Dajnko abeceda',
 			'EKAVSK' => 'srpski s ekavskim izgovorom',
 			'EMODENG' => 'Rani moderni engleski',
 			'FONIPA' => 'IPA fonetika',
 			'FONKIRSH' => 'Fonkirsh',
 			'FONNAPA' => 'Fonnapa',
 			'FONUPA' => 'UPA fonetika',
 			'FONXSAMP' => 'Fonxsamp',
 			'GALLO' => 'Gallo',
 			'GASCON' => 'Gascon',
 			'GRCLASS' => 'Grclass',
 			'GRITAL' => 'Grital',
 			'GRMISTR' => 'Grmistr',
 			'HEPBURN' => 'Hepburnova romanizacija',
 			'HOGNORSK' => 'Hognorsk',
 			'HSISTEMO' => 'Hsistemo',
 			'IJEKAVSK' => 'srpski s ijekavskim izgovorom',
 			'ITIHASA' => 'Itihasa',
 			'IVANCHOV' => 'Ivanchov',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Uobičajena ortografija',
 			'KOCIEWIE' => 'Kociewie',
 			'KSCOR' => 'Standardna ortografija',
 			'LAUKIKA' => 'Laukika',
 			'LEMOSIN' => 'Lemosin',
 			'LENGADOC' => 'Lengadoc',
 			'LIPAW' => 'Lipovac dijalekt rezijanski',
 			'LUNA1918' => 'Luna1918',
 			'METELKO' => 'Metelčica',
 			'MONOTON' => 'Monotonik',
 			'NDYUKA' => 'Ndjuka dijalekt',
 			'NEDIS' => 'Natison dijalekt',
 			'NEWFOUND' => 'Newfound',
 			'NICARD' => 'Nicard',
 			'NJIVA' => 'Gnjiva/Njiva dijalekt',
 			'NULIK' => 'Moderni volapuk',
 			'OSOJS' => 'Oseako/Osojane dijalekt',
 			'OXENDICT' => 'Pravopis Oksforsdskog rječnika engleskog jezika',
 			'PAHAWH2' => 'Pahawh2',
 			'PAHAWH3' => 'Pahawh3',
 			'PAHAWH4' => 'Pahawh4',
 			'PAMAKA' => 'Pamaka dijalekt',
 			'PEANO' => 'Peano',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'Pinjinska romanizacija',
 			'POLYTON' => 'Politonik',
 			'POSIX' => 'Računarski jezik',
 			'PROVENC' => 'Provenc',
 			'PUTER' => 'Puter',
 			'REVISED' => 'Revidirana ortografija',
 			'RIGIK' => 'Rigik',
 			'ROZAJ' => 'Rezijan',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Škotski standardni engleski',
 			'SCOUSE' => 'Skauz',
 			'SIMPLE' => 'Simple',
 			'SOLBA' => 'Stolvica/Solbica dijalekt',
 			'SOTAV' => 'Grupa Sotavento dijalekata kabuverdianu jezika',
 			'SPANGLIS' => 'Spanglis',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilv',
 			'SUTSILV' => 'Sutsilv',
 			'SYNNEJYL' => 'Synnejyl',
 			'TARASK' => 'Taraskijevica ortografija',
 			'TONGYONG' => 'Tongyong',
 			'TUNUMIIT' => 'Tunumiit',
 			'UCCOR' => 'Ujedinjena ortografija',
 			'UCRCOR' => 'Ujedinjena revidirana ortografija',
 			'ULSTER' => 'Ulster',
 			'UNIFON' => 'Fonetska abeceda Unifon',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valencijski',
 			'VALLADER' => 'Vallader',
 			'VECDRUKA' => 'Vecdruka',
 			'VIVARAUP' => 'Vivaraup',
 			'WADEGILE' => 'Vejd-Žajl romanizacija',
 			'XSISTEMO' => 'Xsistemo',

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
 			'colalternate' => 'Zanemarivanje sortiranja simbola',
 			'colbackwards' => 'Obrnuto sortiranje po naglasku',
 			'colcasefirst' => 'Sortiranje po velikim/malim slovima',
 			'colcaselevel' => 'Sortiranje u skladu s veličinom slova',
 			'collation' => 'Sortiranje',
 			'colnormalization' => 'Normalizirano sortiranje',
 			'colnumeric' => 'Numeričko sortiranje',
 			'colstrength' => 'Jačina sortiranja',
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
 				'ethiopic-amete-alem' => q{etiopski kalendar "Amete Alem"},
 				'gregorian' => q{gregorijanski kalendar},
 				'hebrew' => q{hebrejski kalendar},
 				'indian' => q{indijski nacionalni kalendar},
 				'islamic' => q{islamski kalendar},
 				'islamic-civil' => q{islamski građanski kalendar, tabelarni},
 				'islamic-rgsa' => q{islamski kalendar za Saudijsku Arabiju},
 				'islamic-tbla' => q{islamski kalendar, tabelarni, astronomska epoha},
 				'islamic-umalqura' => q{islamski kalendar, Umm al-Qura},
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
 				'compat' => q{Prethodno sortiranje radi usklađenosti},
 				'dictionary' => q{Rječničko sortiranje},
 				'ducet' => q{standardno Unicode sortiranje},
 				'emoji' => q{Sortiranje po emoji sličicama},
 				'eor' => q{Evropska pravila sortiranja},
 				'gb2312han' => q{Pojednostavljeno kinesko sortiranje - GB2312},
 				'phonebook' => q{Sortiranje kao telefonski imenik},
 				'phonetic' => q{Fonetsko sortiranje},
 				'pinyin' => q{Pinjin sortiranje},
 				'reformed' => q{Reformirano sortiranje},
 				'search' => q{općenito pretraživanje},
 				'searchjl' => q{Pretraživanje po početnom suglasniku hangula},
 				'standard' => q{standardno sortiranje},
 				'stroke' => q{Sortiranje po broju crta},
 				'traditional' => q{Tradicionalno sortiranje},
 				'unihan' => q{sortiranje prema korijenu i potezu},
 				'zhuyin' => q{zhuyin sortiranje},
 			},
 			'colnormalization' => {
 				'no' => q{Poredaj bez normalizacije},
 				'yes' => q{Poredaj unikod normalizirano},
 			},
 			'colnumeric' => {
 				'no' => q{Poredaj cifre pojedinačno},
 				'yes' => q{Poredaj cifre numerički},
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
 				'h11' => q{12-satni format (0–11)},
 				'h12' => q{12-satni format (1–12)},
 				'h23' => q{24-satni format (0–23)},
 				'h24' => q{24-satni format (1–24)},
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
 				'ahom' => q{ahom cifre},
 				'arab' => q{arapsko-indijski brojevi},
 				'arabext' => q{prošireni arapsko-indijski brojevi},
 				'armn' => q{armenski brojevi},
 				'armnlow' => q{mali armenski brojevi},
 				'bali' => q{balijske cifre},
 				'beng' => q{bengalski brojevi},
 				'brah' => q{brahmi cifre},
 				'cakm' => q{čakma cifre},
 				'cham' => q{čam cifre},
 				'cyrl' => q{ćirilični brojevi},
 				'deva' => q{brojevi pisma devanagari},
 				'diak' => q{dives akuru cifre},
 				'ethi' => q{etiopski brojevi},
 				'finance' => q{Finansijski brojevi},
 				'fullwide' => q{široki brojevi},
 				'geor' => q{gruzijski brojevi},
 				'gong' => q{gundžala bondi cifre},
 				'gonm' => q{masaram gondi cifre},
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
 				'hmng' => q{pahav hmong brojevi},
 				'hmnp' => q{nijakeng punču hmnog brojevi},
 				'java' => q{javanski brojevi},
 				'jpan' => q{japanski brojevi},
 				'jpanfin' => q{japanski finansijski brojevi},
 				'kali' => q{kajah li brojevi},
 				'kawi' => q{kawi cifre},
 				'khmr' => q{kmerski brojevi},
 				'knda' => q{brojevi pisma kanada},
 				'lana' => q{tai tam hora brojevi},
 				'lanatham' => q{tai tam tam brojevi},
 				'laoo' => q{laoski brojevi},
 				'latn' => q{arapski brojevi},
 				'lepc' => q{lepča brojevi},
 				'limb' => q{limbu brojevi},
 				'mathbold' => q{matematički podebljani brojevi},
 				'mathdbl' => q{matematički dvostruko podebljani brojevi},
 				'mathmono' => q{matematičke monospace cifre},
 				'mathsanb' => q{matematičke sans-serif podebljane cifre},
 				'mathsans' => q{matematičke sans-serif cifre},
 				'mlym' => q{malajalamski brojevi},
 				'modi' => q{modi cifre},
 				'mong' => q{Mongolske cifre},
 				'mroo' => q{mro cifre},
 				'mtei' => q{mitei majek cifre},
 				'mymr' => q{mijanmarski brojevi},
 				'mymrshan' => q{mijanmarske šan cifre},
 				'mymrtlng' => q{mijanmarske tai laing cifre},
 				'nagm' => q{nag mundari cifre},
 				'native' => q{Izvorne cifre},
 				'nkoo' => q{n’ko cifre},
 				'olck' => q{ol čiki cifre},
 				'orya' => q{orijski brojevi},
 				'osma' => q{osmanjske cifre},
 				'rohg' => q{hanifi rohingaja cifre},
 				'roman' => q{rimski brojevi},
 				'romanlow' => q{mali rimski brojevi},
 				'saur' => q{sauraštra cifre},
 				'shrd' => q{šarada cifre},
 				'sind' => q{kudavade cifre},
 				'sinh' => q{sinhala lit cifre},
 				'sora' => q{sora sompeng cifre},
 				'sund' => q{sudanske cifre},
 				'takr' => q{takri cifre},
 				'talu' => q{nove tai lue cifre},
 				'taml' => q{tradicionalni tamilski brojevi},
 				'tamldec' => q{tamilski brojevi},
 				'telu' => q{brojevi pisma telugu},
 				'thai' => q{tajlandski brojevi},
 				'tibt' => q{tibetanski brojevi},
 				'tirh' => q{tirhutanske cifre},
 				'tnsa' => q{tangsa cifre},
 				'traditional' => q{Tradicionalni brojevi},
 				'vaii' => q{Vai cifre},
 				'wara' => q{warang citi cifre},
 				'wcho' => q{vančo cifre},
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
			punctuation => qr{[‐ – — , ; \: ! ? . … '‘’ "“”„ ( ) \[ \] @ * / ′ ″]},
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
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
		};
	},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(glavni pravac),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(glavni pravac),
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
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(kuekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kuekto{0}),
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
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} metra u sekundi na kvadrat),
						'name' => q(metri u sekundi na kvadrat),
						'one' => q({0} metar u sekundi na kvadrat),
						'other' => q({0} metara u sekundi na kvadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} metra u sekundi na kvadrat),
						'name' => q(metri u sekundi na kvadrat),
						'one' => q({0} metar u sekundi na kvadrat),
						'other' => q({0} metara u sekundi na kvadrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} ugaona minuta),
						'one' => q({0} ugaona minuta),
						'other' => q({0} ugaonih minuta),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} ugaona minuta),
						'one' => q({0} ugaona minuta),
						'other' => q({0} ugaonih minuta),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} ugaone sekunde),
						'one' => q({0} ugaona sekunda),
						'other' => q({0} ugaonih sekundi),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} ugaone sekunde),
						'one' => q({0} ugaona sekunda),
						'other' => q({0} ugaonih sekundi),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} stepena),
						'one' => q({0} stepen),
						'other' => q({0} stepeni),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} stepena),
						'one' => q({0} stepen),
						'other' => q({0} stepeni),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} radijana),
						'one' => q({0} radijan),
						'other' => q({0} radijana),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} radijana),
						'one' => q({0} radijan),
						'other' => q({0} radijana),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} okreta),
						'one' => q({0} okret),
						'other' => q({0} okreta),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} okreta),
						'one' => q({0} okret),
						'other' => q({0} okreta),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} katastarska jutra),
						'one' => q({0} katastarsko jutro),
						'other' => q({0} katastarskih jutara),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} katastarska jutra),
						'one' => q({0} katastarsko jutro),
						'other' => q({0} katastarskih jutara),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} hektara),
						'one' => q({0} hektar),
						'other' => q({0} hektara),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} hektara),
						'one' => q({0} hektar),
						'other' => q({0} hektara),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} kvadratna centimetra),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimetar),
						'other' => q({0} kvadratnih centimetara),
						'per' => q({0} po kvadratnom centimetru),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} kvadratna centimetra),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimetar),
						'other' => q({0} kvadratnih centimetara),
						'per' => q({0} po kvadratnom centimetru),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} kvadratne stope),
						'name' => q(kvadratne stope),
						'one' => q({0} kvadratna stopa),
						'other' => q({0} kvadratnih stopa),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} kvadratne stope),
						'name' => q(kvadratne stope),
						'one' => q({0} kvadratna stopa),
						'other' => q({0} kvadratnih stopa),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} kvadratna inča),
						'name' => q(kvadratni inči),
						'one' => q({0} kvadratni inč),
						'other' => q({0} kvadratnih inča),
						'per' => q({0} po kvadratnom inču),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} kvadratna inča),
						'name' => q(kvadratni inči),
						'one' => q({0} kvadratni inč),
						'other' => q({0} kvadratnih inča),
						'per' => q({0} po kvadratnom inču),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} kvadratna kilometra),
						'name' => q(kvadratni kilometri),
						'one' => q({0} kvadratni kilometar),
						'other' => q({0} kvadratnih kilometara),
						'per' => q({0} po kvadratnom kilometru),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} kvadratna kilometra),
						'name' => q(kvadratni kilometri),
						'one' => q({0} kvadratni kilometar),
						'other' => q({0} kvadratnih kilometara),
						'per' => q({0} po kvadratnom kilometru),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} kvadratna metra),
						'name' => q(kvadratni metri),
						'one' => q({0} kvadratni metar),
						'other' => q({0} kvadratnih metara),
						'per' => q({0} po kvadratnom metru),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} kvadratna metra),
						'name' => q(kvadratni metri),
						'one' => q({0} kvadratni metar),
						'other' => q({0} kvadratnih metara),
						'per' => q({0} po kvadratnom metru),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratne milje),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milja),
						'per' => q({0} po kvadratnoj milji),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratne milje),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milja),
						'per' => q({0} po kvadratnoj milji),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} kvadratna jarda),
						'name' => q(kvadratni jardi),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jarda),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} kvadratna jarda),
						'name' => q(kvadratni jardi),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jarda),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} karata),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} karata),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligrama po decilitru),
						'name' => q(miligrami po decilitru),
						'one' => q({0} miligram po decilitru),
						'other' => q({0} miligrama po decilitru),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligrama po decilitru),
						'name' => q(miligrami po decilitru),
						'one' => q({0} miligram po decilitru),
						'other' => q({0} miligrama po decilitru),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} milimola po litru),
						'name' => q(milimoli po litru),
						'one' => q({0} milimol po litru),
						'other' => q({0} milimola po litru),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} milimola po litru),
						'name' => q(milimoli po litru),
						'one' => q({0} milimol po litru),
						'other' => q({0} milimola po litru),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mola),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} mola),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mola),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} mola),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} procenta),
						'name' => q(procenat),
						'one' => q({0} procenat),
						'other' => q({0} procenata),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} procenta),
						'name' => q(procenat),
						'one' => q({0} procenat),
						'other' => q({0} procenata),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} promila),
						'name' => q(promil),
						'one' => q({0} promil),
						'other' => q({0} promila),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} promila),
						'name' => q(promil),
						'one' => q({0} promil),
						'other' => q({0} promila),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} dijela na milion),
						'name' => q(dijelovi na milion),
						'one' => q({0} dio na milion),
						'other' => q({0} dijelova na milion),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} dijela na milion),
						'name' => q(dijelovi na milion),
						'one' => q({0} dio na milion),
						'other' => q({0} dijelova na milion),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} permyriada),
						'name' => q(permyriad),
						'one' => q({0} permyriad),
						'other' => q({0} permyriada),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} permyriada),
						'name' => q(permyriad),
						'one' => q({0} permyriad),
						'other' => q({0} permyriada),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} litra na 100 kilometara),
						'name' => q(litri na 100 kilometara),
						'one' => q({0} litar na 100 kilometara),
						'other' => q({0} litara na 100 kilometara),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} litra na 100 kilometara),
						'name' => q(litri na 100 kilometara),
						'one' => q({0} litar na 100 kilometara),
						'other' => q({0} litara na 100 kilometara),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} litra po kilometru),
						'name' => q(litri po kilometru),
						'one' => q({0} litar po kilometru),
						'other' => q({0} litara po kilometru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} litra po kilometru),
						'name' => q(litri po kilometru),
						'one' => q({0} litar po kilometru),
						'other' => q({0} litara po kilometru),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} milje po galonu),
						'name' => q(milje po galonu),
						'one' => q({0} milja po galonu),
						'other' => q({0} milja po galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} milje po galonu),
						'name' => q(milje po galonu),
						'one' => q({0} milja po galonu),
						'other' => q({0} milja po galonu),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} milje po brit. galonu),
						'name' => q(milje po brit. galonu),
						'one' => q({0} milja po brit. galonu),
						'other' => q({0} milja po brit. galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} milje po brit. galonu),
						'name' => q(milje po brit. galonu),
						'one' => q({0} milja po brit. galonu),
						'other' => q({0} milja po brit. galonu),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} istok),
						'north' => q({0} sjever),
						'south' => q({0} jug),
						'west' => q({0} zapad),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} istok),
						'north' => q({0} sjever),
						'south' => q({0} jug),
						'west' => q({0} zapad),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} bita),
						'name' => q(biti),
						'one' => q({0} bit),
						'other' => q({0} bita),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} bita),
						'name' => q(biti),
						'one' => q({0} bit),
						'other' => q({0} bita),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} bajta),
						'name' => q(bajtovi),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bajta),
						'name' => q(bajtovi),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} gigabita),
						'name' => q(gigabiti),
						'one' => q({0} gigabit),
						'other' => q({0} gigabita),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} gigabita),
						'name' => q(gigabiti),
						'one' => q({0} gigabit),
						'other' => q({0} gigabita),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} gigabajta),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajta),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} gigabajta),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajta),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kilobita),
						'name' => q(kilobiti),
						'one' => q({0} kilobit),
						'other' => q({0} kilobita),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kilobita),
						'name' => q(kilobiti),
						'one' => q({0} kilobit),
						'other' => q({0} kilobita),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} kilobajta),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajta),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} kilobajta),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajta),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} megabita),
						'name' => q(megabiti),
						'one' => q({0} megabit),
						'other' => q({0} megabita),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} megabita),
						'name' => q(megabiti),
						'one' => q({0} megabit),
						'other' => q({0} megabita),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} megabajta),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajta),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} megabajta),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajta),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} petabajta),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajta),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} petabajta),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajta),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} terabita),
						'name' => q(terabiti),
						'one' => q({0} terabit),
						'other' => q({0} terabita),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} terabita),
						'name' => q(terabiti),
						'one' => q({0} terabit),
						'other' => q({0} terabita),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} terabajta),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajta),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} terabajta),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajta),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} stoljeća),
						'name' => q(stoljeća),
						'one' => q({0} stoljeće),
						'other' => q({0} stoljeća),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} stoljeća),
						'name' => q(stoljeća),
						'one' => q({0} stoljeće),
						'other' => q({0} stoljeća),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} dnevno),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} dnevno),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} decenije),
						'name' => q(decenije),
						'one' => q({0} decenija),
						'other' => q({0} decenija),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} decenije),
						'name' => q(decenije),
						'one' => q({0} decenija),
						'other' => q({0} decenija),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} sata),
						'one' => q({0} sat),
						'other' => q({0} sati),
						'per' => q({0} na sat),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} sata),
						'one' => q({0} sat),
						'other' => q({0} sati),
						'per' => q({0} na sat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} minute),
						'one' => q({0} minuta),
						'other' => q({0} minuta),
						'per' => q({0} po minuti),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} minute),
						'one' => q({0} minuta),
						'other' => q({0} minuta),
						'per' => q({0} po minuti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mjeseca),
						'one' => q({0} mjesec),
						'other' => q({0} mjeseci),
						'per' => q({0} mjesečno),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mjeseca),
						'one' => q({0} mjesec),
						'other' => q({0} mjeseci),
						'per' => q({0} mjesečno),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundi),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} četvrtine),
						'name' => q(četvrtine),
						'one' => q({0} četvrtina),
						'other' => q({0} četvrtina),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} četvrtine),
						'name' => q(četvrtine),
						'one' => q({0} četvrtina),
						'other' => q({0} četvrtina),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
						'per' => q({0} po sekundi),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
						'per' => q({0} po sekundi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} sedmice),
						'one' => q({0} sedmica),
						'other' => q({0} sedmica),
						'per' => q({0} sedmično),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} sedmice),
						'one' => q({0} sedmica),
						'other' => q({0} sedmica),
						'per' => q({0} sedmično),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} godine),
						'one' => q({0} godina),
						'other' => q({0} godina),
						'per' => q({0} godišnje),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} godine),
						'one' => q({0} godina),
						'other' => q({0} godina),
						'per' => q({0} godišnje),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} ampera),
						'one' => q({0} amper),
						'other' => q({0} ampera),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} ampera),
						'one' => q({0} amper),
						'other' => q({0} ampera),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} miliampera),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} miliampera),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} oma),
						'one' => q({0} om),
						'other' => q({0} oma),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} oma),
						'one' => q({0} om),
						'other' => q({0} oma),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} volta),
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} volta),
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} britanske termalne jedinice),
						'name' => q(britanske termalne jedinice),
						'one' => q({0} britanska termalna jedinica),
						'other' => q({0} britanskih termalnih jedinica),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} britanske termalne jedinice),
						'name' => q(britanske termalne jedinice),
						'one' => q({0} britanska termalna jedinica),
						'other' => q({0} britanskih termalnih jedinica),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektron volta),
						'name' => q(elektron volti),
						'one' => q({0} elektron volt),
						'other' => q({0} elektron volti),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektron volta),
						'name' => q(elektron volti),
						'one' => q({0} elektron volt),
						'other' => q({0} elektron volti),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kcal),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} džula),
						'one' => q({0} džul),
						'other' => q({0} džula),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} džula),
						'one' => q({0} džul),
						'other' => q({0} džula),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorija),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorija),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kilodžula),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kilodžula),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} kilovat-sata),
						'name' => q(kilovat-sat),
						'one' => q({0} kilovat-sat),
						'other' => q({0} kilovat-sati),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} kilovat-sata),
						'name' => q(kilovat-sat),
						'one' => q({0} kilovat-sat),
						'other' => q({0} kilovat-sati),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} njutna),
						'name' => q(njutni),
						'one' => q({0} njutn),
						'other' => q({0} njutna),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} njutna),
						'name' => q(njutni),
						'one' => q({0} njutn),
						'other' => q({0} njutna),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} funte sile),
						'name' => q(funte sile),
						'one' => q({0} funta sile),
						'other' => q({0} funti sile),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} funte sile),
						'name' => q(funte sile),
						'one' => q({0} funta sile),
						'other' => q({0} funti sile),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} gigaherca),
						'name' => q(gigaherci),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherca),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} gigaherca),
						'name' => q(gigaherci),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherca),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} herca),
						'name' => q(herci),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} herca),
						'name' => q(herci),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} kiloherca),
						'name' => q(kiloherci),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherca),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} kiloherca),
						'name' => q(kiloherci),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherca),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} megaherca),
						'name' => q(megaherci),
						'one' => q({0} megaherc),
						'other' => q({0} megaherca),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} megaherca),
						'name' => q(megaherci),
						'one' => q({0} megaherc),
						'other' => q({0} megaherca),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(tačaka po centimetru),
						'one' => q({0} tačka po centimetru),
						'other' => q({0} tačaka po centimetru),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(tačaka po centimetru),
						'one' => q({0} tačka po centimetru),
						'other' => q({0} tačaka po centimetru),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(tačaka po inču),
						'one' => q({0} tačka po inču),
						'other' => q({0} tačaka po inču),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(tačaka po inču),
						'one' => q({0} tačka po inču),
						'other' => q({0} tačaka po inču),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikseli),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikseli),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} px),
						'name' => q(pikseli),
						'one' => q({0} piksel),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} px),
						'name' => q(pikseli),
						'one' => q({0} piksel),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(pikseli po centimetru),
						'one' => q({0} piksel po centimetru),
						'other' => q({0} piksela po centimetru),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(pikseli po centimetru),
						'one' => q({0} piksel po centimetru),
						'other' => q({0} piksela po centimetru),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(pikseli po inču),
						'one' => q({0} piksel po inču),
						'other' => q({0} piksela po inču),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(pikseli po inču),
						'one' => q({0} piksel po inču),
						'other' => q({0} piksela po inču),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomske jedinice),
						'name' => q(astronomske jedinice),
						'one' => q({0} astronomska jedinica),
						'other' => q({0} astronomskih jedinica),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomske jedinice),
						'name' => q(astronomske jedinice),
						'one' => q({0} astronomska jedinica),
						'other' => q({0} astronomskih jedinica),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} centimetra),
						'name' => q(centimetri),
						'one' => q({0} centimetar),
						'other' => q({0} centimetara),
						'per' => q({0} po centimetru),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} centimetra),
						'name' => q(centimetri),
						'one' => q({0} centimetar),
						'other' => q({0} centimetara),
						'per' => q({0} po centimetru),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} decimetra),
						'name' => q(decimetri),
						'one' => q({0} decimetar),
						'other' => q({0} decimetara),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} decimetra),
						'name' => q(decimetri),
						'one' => q({0} decimetar),
						'other' => q({0} decimetara),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} radijusa zemlje),
						'name' => q(radijus zemlje),
						'one' => q({0} radijus zemlje),
						'other' => q({0} radijus zemlje),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} radijusa zemlje),
						'name' => q(radijus zemlje),
						'one' => q({0} radijus zemlje),
						'other' => q({0} radijus zemlje),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} stope),
						'one' => q({0} stopa),
						'other' => q({0} stopa),
						'per' => q({0} po stopi),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} stope),
						'one' => q({0} stopa),
						'other' => q({0} stopa),
						'per' => q({0} po stopi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} inča),
						'one' => q({0} inč),
						'other' => q({0} inča),
						'per' => q({0} po inču),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} inča),
						'one' => q({0} inč),
						'other' => q({0} inča),
						'per' => q({0} po inču),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} kilometra),
						'name' => q(kilometri),
						'one' => q({0} kilometar),
						'other' => q({0} kilometara),
						'per' => q({0} po kilometru),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} kilometra),
						'name' => q(kilometri),
						'one' => q({0} kilometar),
						'other' => q({0} kilometara),
						'per' => q({0} po kilometru),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} svjetlosne godine),
						'one' => q({0} svjetlosna godina),
						'other' => q({0} svjetlosnih godina),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} svjetlosne godine),
						'one' => q({0} svjetlosna godina),
						'other' => q({0} svjetlosnih godina),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} metra),
						'one' => q({0} metar),
						'other' => q({0} metara),
						'per' => q({0} po metru),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} metra),
						'one' => q({0} metar),
						'other' => q({0} metara),
						'per' => q({0} po metru),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} mikrometra),
						'name' => q(mikrometri),
						'one' => q({0} mikrometar),
						'other' => q({0} mikrometara),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} mikrometra),
						'name' => q(mikrometri),
						'one' => q({0} mikrometar),
						'other' => q({0} mikrometara),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavske milje),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milja),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavske milje),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milja),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} milimetra),
						'name' => q(milimetri),
						'one' => q({0} milimetar),
						'other' => q({0} milimetara),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} milimetra),
						'name' => q(milimetri),
						'one' => q({0} milimetar),
						'other' => q({0} milimetara),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nanometra),
						'name' => q(nanometri),
						'one' => q({0} nanometar),
						'other' => q({0} nanometara),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nanometra),
						'name' => q(nanometri),
						'one' => q({0} nanometar),
						'other' => q({0} nanometara),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} nautičke milje),
						'name' => q(nautičke milje),
						'one' => q({0} nautička milja),
						'other' => q({0} nautičkih milja),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} nautičke milje),
						'name' => q(nautičke milje),
						'one' => q({0} nautička milja),
						'other' => q({0} nautičkih milja),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parseka),
						'one' => q({0} parsek),
						'other' => q({0} parseka),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parseka),
						'one' => q({0} parsek),
						'other' => q({0} parseka),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} pikometra),
						'name' => q(pikometri),
						'one' => q({0} pikometar),
						'other' => q({0} pikometara),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} pikometra),
						'name' => q(pikometri),
						'one' => q({0} pikometar),
						'other' => q({0} pikometara),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} DTP tačke),
						'name' => q(DTP tačke),
						'one' => q({0} DTP tačka),
						'other' => q({0} DTP tačaka),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} DTP tačke),
						'name' => q(DTP tačke),
						'one' => q({0} DTP tačka),
						'other' => q({0} DTP tačaka),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} Sunčeva radijusa),
						'name' => q(Sunčevi radijusi),
						'one' => q({0} Sunčev radijus),
						'other' => q({0} Sunčevih radijusa),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} Sunčeva radijusa),
						'name' => q(Sunčevi radijusi),
						'one' => q({0} Sunčev radijus),
						'other' => q({0} Sunčevih radijusa),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} jarda),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} jarda),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} kandele),
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} kandele),
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lumena),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumena),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lumena),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumena),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} luksa),
						'name' => q(luksi),
						'one' => q({0} luks),
						'other' => q({0} luksa),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} luksa),
						'name' => q(luksi),
						'one' => q({0} luks),
						'other' => q({0} luksa),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} Sunčeva zračenja),
						'name' => q(Sunčeva zračenja),
						'one' => q({0} Sunčevo zračenje),
						'other' => q({0} Sunčevih zračenja),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} Sunčeva zračenja),
						'name' => q(Sunčeva zračenja),
						'one' => q({0} Sunčevo zračenje),
						'other' => q({0} Sunčevih zračenja),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} karata),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} karata),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltona),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} daltona),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltona),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} daltona),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} Zemljine mase),
						'name' => q(Zemljine mase),
						'one' => q({0} Zemljina masa),
						'other' => q({0} Zemljinih masa),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} Zemljine mase),
						'name' => q(Zemljine mase),
						'one' => q({0} Zemljina masa),
						'other' => q({0} Zemljinih masa),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} grama),
						'one' => q({0} gram),
						'other' => q({0} grama),
						'per' => q({0} po gramu),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} grama),
						'one' => q({0} gram),
						'other' => q({0} grama),
						'per' => q({0} po gramu),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kilograma),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilograma),
						'per' => q({0} po kilogramu),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kilograma),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilograma),
						'per' => q({0} po kilogramu),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} mikrograma),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrograma),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} mikrograma),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrograma),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} miligrama),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligrama),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} miligrama),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligrama),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
						'per' => q({0} po unci),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
						'per' => q({0} po unci),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} fine unce),
						'name' => q(fine unce),
						'one' => q({0} fina unca),
						'other' => q({0} finih unci),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} fine unce),
						'name' => q(fine unce),
						'one' => q({0} fina unca),
						'other' => q({0} finih unci),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} funte),
						'name' => q(funte),
						'one' => q({0} funta),
						'other' => q({0} funti),
						'per' => q({0} po funti),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} funte),
						'name' => q(funte),
						'one' => q({0} funta),
						'other' => q({0} funti),
						'per' => q({0} po funti),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} Sunčeve mase),
						'name' => q(Sunčeve mase),
						'one' => q({0} Sunčeva masa),
						'other' => q({0} Sunčevih masa),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} Sunčeve mase),
						'name' => q(Sunčeve mase),
						'one' => q({0} Sunčeva masa),
						'other' => q({0} Sunčevih masa),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} stone),
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} stone),
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} tone),
						'one' => q({0} tona),
						'other' => q({0} tona),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} tone),
						'one' => q({0} tona),
						'other' => q({0} tona),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} metričke tone),
						'name' => q(metričke tone),
						'one' => q({0} metrička tona),
						'other' => q({0} metričkih tona),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} metričke tone),
						'name' => q(metričke tone),
						'one' => q({0} metrička tona),
						'other' => q({0} metričkih tona),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} gigavata),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavata),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} gigavata),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavata),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} konjske snage),
						'name' => q(konjske snage),
						'one' => q({0} konjska snaga),
						'other' => q({0} konjskih snaga),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} konjske snage),
						'name' => q(konjske snage),
						'one' => q({0} konjska snaga),
						'other' => q({0} konjskih snaga),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} kilovata),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovata),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} kilovata),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovata),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} megavata),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavata),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} megavata),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavata),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} milivata),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivata),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} milivata),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivata),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} vata),
						'one' => q({0} vat),
						'other' => q({0} vati),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} vata),
						'one' => q({0} vat),
						'other' => q({0} vati),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q(kvadratna {0}),
						'one' => q(kvadratni {0}),
						'other' => q(kvadratnih {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q(kvadratna {0}),
						'one' => q(kvadratni {0}),
						'other' => q(kvadratnih {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q(kubna {0}),
						'one' => q(kubni {0}),
						'other' => q(kubnih {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q(kubna {0}),
						'one' => q(kubni {0}),
						'other' => q(kubnih {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bara),
						'one' => q({0} bar),
						'other' => q({0} bara),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bara),
						'one' => q({0} bar),
						'other' => q({0} bara),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hektopaskala),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskala),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hektopaskala),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskala),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inča živinog stuba),
						'name' => q(inči živinog stuba),
						'one' => q({0} inč živinog stuba),
						'other' => q({0} inča živinog stuba),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inča živinog stuba),
						'name' => q(inči živinog stuba),
						'one' => q({0} inč živinog stuba),
						'other' => q({0} inča živinog stuba),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} kilopaskala),
						'name' => q(kilopaskali),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskala),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} kilopaskala),
						'name' => q(kilopaskali),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskala),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} megapaskala),
						'name' => q(megapaskali),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskala),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} megapaskala),
						'name' => q(megapaskali),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskala),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} milibara),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} milibara),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetra živinog stuba),
						'name' => q(milimetri živinog stuba),
						'one' => q({0} milimetar živinog stuba),
						'other' => q({0} milimetara živinog stuba),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetra živinog stuba),
						'name' => q(milimetri živinog stuba),
						'one' => q({0} milimetar živinog stuba),
						'other' => q({0} milimetara živinog stuba),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} paskala),
						'name' => q(paskali),
						'one' => q({0} paskal),
						'other' => q({0} paskala),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} paskala),
						'name' => q(paskali),
						'one' => q({0} paskal),
						'other' => q({0} paskala),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} funte po kvadratnom inču),
						'name' => q(funte po kvadratnom inču),
						'one' => q({0} funta po kvadratnom inču),
						'other' => q({0} funti po kvadratnom inču),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} funte po kvadratnom inču),
						'name' => q(funte po kvadratnom inču),
						'one' => q({0} funta po kvadratnom inču),
						'other' => q({0} funti po kvadratnom inču),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Beafort),
						'one' => q(Beafort {0}),
						'other' => q(Beafort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Beafort),
						'one' => q(Beafort {0}),
						'other' => q(Beafort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} kilometra na sat),
						'name' => q(kilometri na sat),
						'one' => q({0} kilometar na sat),
						'other' => q({0} kilometara na sat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} kilometra na sat),
						'name' => q(kilometri na sat),
						'one' => q({0} kilometar na sat),
						'other' => q({0} kilometara na sat),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} čvora),
						'name' => q(čvorovi),
						'one' => q({0} čvor),
						'other' => q({0} čvorova),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} čvora),
						'name' => q(čvorovi),
						'one' => q({0} čvor),
						'other' => q({0} čvorova),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} metra u sekundi),
						'name' => q(metri u sekundi),
						'one' => q({0} metar u sekundi),
						'other' => q({0} metara u sekundi),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} metra u sekundi),
						'name' => q(metri u sekundi),
						'one' => q({0} metar u sekundi),
						'other' => q({0} metara u sekundi),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} milje na sat),
						'name' => q(milje na sat),
						'one' => q({0} milja na sat),
						'other' => q({0} milja na sat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} milje na sat),
						'name' => q(milje na sat),
						'one' => q({0} milja na sat),
						'other' => q({0} milja na sat),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} stepena Celzijusa),
						'name' => q(stepeni Celzijusa),
						'one' => q({0} stepen Celzijusa),
						'other' => q({0} stepeni Celzijusa),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} stepena Celzijusa),
						'name' => q(stepeni Celzijusa),
						'one' => q({0} stepen Celzijusa),
						'other' => q({0} stepeni Celzijusa),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stepena Farenhajta),
						'name' => q(stepeni Farenhajta),
						'one' => q({0} stepen Farenhajta),
						'other' => q({0} stepeni Farenhajta),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stepena Farenhajta),
						'name' => q(stepeni Farenhajta),
						'one' => q({0} stepen Farenhajta),
						'other' => q({0} stepeni Farenhajta),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} kelvina),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} kelvina),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} kelvina),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} kelvina),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} njutn-metra),
						'name' => q(njutn-metri),
						'one' => q({0} njutn-metar),
						'other' => q({0} njutn-metara),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} njutn-metra),
						'name' => q(njutn-metri),
						'one' => q({0} njutn-metar),
						'other' => q({0} njutn-metara),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} funte sile po stopi),
						'name' => q(funte sile po stopi),
						'one' => q({0} funta sile po stopi),
						'other' => q({0} funti sile po stopi),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} funte sile po stopi),
						'name' => q(funte sile po stopi),
						'one' => q({0} funta sile po stopi),
						'other' => q({0} funti sile po stopi),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} jutar-stope),
						'name' => q(jutar-stope),
						'one' => q({0} jutar-stopa),
						'other' => q({0} jutar-stopa),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} jutar-stope),
						'name' => q(jutar-stope),
						'one' => q({0} jutar-stopa),
						'other' => q({0} jutar-stopa),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barela),
						'name' => q(bareli),
						'one' => q({0} barel),
						'other' => q({0} barela),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barela),
						'name' => q(bareli),
						'one' => q({0} barel),
						'other' => q({0} barela),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušela),
						'name' => q(bušeli),
						'one' => q({0} bušel),
						'other' => q({0} bušela),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušela),
						'name' => q(bušeli),
						'one' => q({0} bušel),
						'other' => q({0} bušela),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} centilitra),
						'name' => q(centilitri),
						'one' => q({0} centilitar),
						'other' => q({0} centilitara),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} centilitra),
						'name' => q(centilitri),
						'one' => q({0} centilitar),
						'other' => q({0} centilitara),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} kubna centimetra),
						'name' => q(kubni centimetri),
						'one' => q({0} kubni centimetar),
						'other' => q({0} kubnih centimetara),
						'per' => q({0} po kubnom centimetru),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} kubna centimetra),
						'name' => q(kubni centimetri),
						'one' => q({0} kubni centimetar),
						'other' => q({0} kubnih centimetara),
						'per' => q({0} po kubnom centimetru),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} kubne stope),
						'name' => q(kubne stope),
						'one' => q({0} kubna stopa),
						'other' => q({0} kubnih stopa),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} kubne stope),
						'name' => q(kubne stope),
						'one' => q({0} kubna stopa),
						'other' => q({0} kubnih stopa),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} kubna inča),
						'name' => q(kubni inči),
						'one' => q({0} kubni inč),
						'other' => q({0} kubnih inča),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} kubna inča),
						'name' => q(kubni inči),
						'one' => q({0} kubni inč),
						'other' => q({0} kubnih inča),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} kubna kilometra),
						'name' => q(kubni kilometri),
						'one' => q({0} kubni kilometar),
						'other' => q({0} kubnih kilometara),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} kubna kilometra),
						'name' => q(kubni kilometri),
						'one' => q({0} kubni kilometar),
						'other' => q({0} kubnih kilometara),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} kubna metra),
						'name' => q(kubni metri),
						'one' => q({0} kubni metar),
						'other' => q({0} kubnih metara),
						'per' => q({0} po kubnom metru),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} kubna metra),
						'name' => q(kubni metri),
						'one' => q({0} kubni metar),
						'other' => q({0} kubnih metara),
						'per' => q({0} po kubnom metru),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} kubne milje),
						'name' => q(kubne milje),
						'one' => q({0} kubna milja),
						'other' => q({0} kubnih milja),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} kubne milje),
						'name' => q(kubne milje),
						'one' => q({0} kubna milja),
						'other' => q({0} kubnih milja),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} kubna jarda),
						'name' => q(kubni jardi),
						'one' => q({0} kubni jard),
						'other' => q({0} kubnih jarda),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} kubna jarda),
						'name' => q(kubni jardi),
						'one' => q({0} kubni jard),
						'other' => q({0} kubnih jarda),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} šolje),
						'one' => q({0} šolja),
						'other' => q({0} šolja),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} šolje),
						'one' => q({0} šolja),
						'other' => q({0} šolja),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} metričke šolje),
						'name' => q(metričke šolje),
						'one' => q({0} metrička šolja),
						'other' => q({0} metričkih šolja),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} metričke šolje),
						'name' => q(metričke šolje),
						'one' => q({0} metrička šolja),
						'other' => q({0} metričkih šolja),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} decilitra),
						'name' => q(decilitri),
						'one' => q({0} decilitar),
						'other' => q({0} decilitara),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} decilitra),
						'name' => q(decilitri),
						'one' => q({0} decilitar),
						'other' => q({0} decilitara),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} kašike za desert),
						'name' => q(kašika za desert),
						'one' => q({0} kašika za desert),
						'other' => q({0} kašika za desert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} kašike za desert),
						'name' => q(kašika za desert),
						'one' => q({0} kašika za desert),
						'other' => q({0} kašika za desert),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imperijalne kašike za desert),
						'name' => q(imperijalna kašika za desert),
						'one' => q({0} imperijalna kašika za desert),
						'other' => q({0} imperijalnih kašika za desert),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imperijalne kašike za desert),
						'name' => q(imperijalna kašika za desert),
						'one' => q({0} imperijalna kašika za desert),
						'other' => q({0} imperijalnih kašika za desert),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} tečna drama),
						'name' => q(tečni dram),
						'one' => q({0} tečni dram),
						'other' => q({0} tečnih drama),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} tečna drama),
						'name' => q(tečni dram),
						'one' => q({0} tečni dram),
						'other' => q({0} tečnih drama),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} tečne unce),
						'name' => q(tečne unce),
						'one' => q({0} tečna unca),
						'other' => q({0} tečnih unci),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} tečne unce),
						'name' => q(tečne unce),
						'one' => q({0} tečna unca),
						'other' => q({0} tečnih unci),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} imp. tekuće unce),
						'name' => q(imp. tekuće unce),
						'one' => q({0} imp. tekuća unca),
						'other' => q({0} imp. tekućih unci),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} imp. tekuće unce),
						'name' => q(imp. tekuće unce),
						'one' => q({0} imp. tekuća unca),
						'other' => q({0} imp. tekućih unci),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galona),
						'name' => q(galoni),
						'one' => q({0} galon),
						'other' => q({0} galona),
						'per' => q({0} po galonu),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galona),
						'name' => q(galoni),
						'one' => q({0} galon),
						'other' => q({0} galona),
						'per' => q({0} po galonu),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} brit. galona),
						'name' => q(Brit. galoni),
						'one' => q({0} brit. galon),
						'other' => q({0} brit. galona),
						'per' => q({0} po brit. galonu),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} brit. galona),
						'name' => q(Brit. galoni),
						'one' => q({0} brit. galon),
						'other' => q({0} brit. galona),
						'per' => q({0} po brit. galonu),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hektolitra),
						'name' => q(hektolitri),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitara),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hektolitra),
						'name' => q(hektolitri),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitara),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} litra),
						'one' => q({0} litar),
						'other' => q({0} litara),
						'per' => q({0} po litru),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} litra),
						'one' => q({0} litar),
						'other' => q({0} litara),
						'per' => q({0} po litru),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} megalitra),
						'name' => q(megalitri),
						'one' => q({0} megalitar),
						'other' => q({0} megalitara),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} megalitra),
						'name' => q(megalitri),
						'one' => q({0} megalitar),
						'other' => q({0} megalitara),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mililitra),
						'name' => q(mililitri),
						'one' => q({0} mililitar),
						'other' => q({0} mililitara),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mililitra),
						'name' => q(mililitri),
						'one' => q({0} mililitar),
						'other' => q({0} mililitara),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinti),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinti),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} metričke pinte),
						'name' => q(metričke pinte),
						'one' => q({0} metrička pinta),
						'other' => q({0} metričkih pinti),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} metričke pinte),
						'name' => q(metričke pinte),
						'one' => q({0} metrička pinta),
						'other' => q({0} metričkih pinti),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} četvrtine),
						'name' => q(četvrtine),
						'one' => q({0} četvrtina),
						'other' => q({0} četvrtina),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} četvrtine),
						'name' => q(četvrtine),
						'one' => q({0} četvrtina),
						'other' => q({0} četvrtina),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} imperijalna kvarca),
						'name' => q(imperijalni kvarc),
						'one' => q({0} imperijalni kvarc),
						'other' => q({0} imperijalnih kvarca),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} imperijalna kvarca),
						'name' => q(imperijalni kvarc),
						'one' => q({0} imperijalni kvarc),
						'other' => q({0} imperijalnih kvarca),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} kašike),
						'name' => q(kašike),
						'one' => q({0} kašika),
						'other' => q({0} kašika),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} kašike),
						'name' => q(kašike),
						'one' => q({0} kašika),
						'other' => q({0} kašika),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} kašičice),
						'name' => q(kašičice),
						'one' => q({0} kašičica),
						'other' => q({0} kašičica),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} kašičice),
						'name' => q(kašičice),
						'one' => q({0} kašičica),
						'other' => q({0} kašičica),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} bita),
						'one' => q({0} bit),
						'other' => q({0} bita),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} bita),
						'one' => q({0} bit),
						'other' => q({0} bita),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} d.),
						'name' => q(dan),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} d.),
						'name' => q(dan),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sat),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekunda),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekunda),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekunda),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekunda),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} m),
						'name' => q(minuta),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} m),
						'name' => q(minuta),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mjesec),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mjesec),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} s),
						'name' => q(sekunda),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} s),
						'name' => q(sekunda),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sedm.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sedm.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(god.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(god.),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} kal.),
						'one' => q({0} kal.),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} kal.),
						'one' => q({0} kal.),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100 km),
						'one' => q({0}kWh/100 km),
						'other' => q({0}kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100 km),
						'one' => q({0}kWh/100 km),
						'other' => q({0}kWh/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(tačka),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(tačka),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'one' => q({0}dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'one' => q({0}dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ppi),
						'one' => q({0}dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ppi),
						'one' => q({0}dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} ppi),
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} ppi),
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metar),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metar),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} ct),
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} ct),
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gram),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} °F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} °F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0}l),
						'name' => q(litar),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0}l),
						'name' => q(litar),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} kšk.),
						'name' => q(kšk.),
						'one' => q({0} kšk.),
						'other' => q({0} kšk.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} kšk.),
						'name' => q(kšk.),
						'one' => q({0} kšk.),
						'other' => q({0} kšk.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} kšč.),
						'name' => q(kšč.),
						'one' => q({0} kšč.),
						'other' => q({0} kšč.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} kšč.),
						'name' => q(kšč.),
						'one' => q({0} kšč.),
						'other' => q({0} kšč.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(pravac),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(pravac),
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
						'name' => q(ugaone minute),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ugaone minute),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ugaone sekunde),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ugaone sekunde),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(stepeni),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(stepeni),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radijani),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radijani),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} okr.),
						'name' => q(okret),
						'one' => q({0} okr.),
						'other' => q({0} okr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} okr.),
						'name' => q(okret),
						'one' => q({0} okr.),
						'other' => q({0} okr.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} kj),
						'name' => q(katastarska jutra),
						'one' => q({0} kj),
						'other' => q({0} kj),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} kj),
						'name' => q(katastarska jutra),
						'one' => q({0} kj),
						'other' => q({0} kj),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunuma),
						'name' => q(dunumi),
						'one' => q({0} dunum),
						'other' => q({0} dunuma),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunuma),
						'name' => q(dunumi),
						'one' => q({0} dunum),
						'other' => q({0} dunuma),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektari),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektari),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} stavke),
						'name' => q(stavka),
						'one' => q({0} stavka),
						'other' => q({0} stavki),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} stavke),
						'name' => q(stavka),
						'one' => q({0} stavka),
						'other' => q({0} stavki),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karati),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karati),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol/litar),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/litar),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(dijelovi/milion),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(dijelovi/milion),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} L/100 km),
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} L/100 km),
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mi/b. gal),
						'name' => q(milje/b. gal),
						'one' => q({0} mi/b. gal),
						'other' => q({0} mi/b. gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mi/b. gal),
						'name' => q(milje/b. gal),
						'one' => q({0} mi/b. gal),
						'other' => q({0} mi/b. gal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} I),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} I),
						'north' => q({0} S),
						'south' => q({0} J),
						'west' => q({0} Z),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} bajt),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bajt),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} st.),
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} st.),
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dana),
						'name' => q(dani),
						'one' => q({0} dan),
						'other' => q({0} dana),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dana),
						'name' => q(dani),
						'one' => q({0} dan),
						'other' => q({0} dana),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dec.),
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dec.),
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sati),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sati),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekunde),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekunde),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekunde),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekunde),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min.),
						'name' => q(minute),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min.),
						'name' => q(minute),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mj.),
						'name' => q(mjeseci),
						'one' => q({0} mj.),
						'other' => q({0} mj.),
						'per' => q({0} mj.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mj.),
						'name' => q(mjeseci),
						'one' => q({0} mj.),
						'other' => q({0} mj.),
						'per' => q({0} mj.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekunde),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekunde),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} čet.),
						'name' => q(čet.),
						'one' => q({0} čet.),
						'other' => q({0} čet.),
						'per' => q({0}/čet.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} čet.),
						'name' => q(čet.),
						'one' => q({0} čet.),
						'other' => q({0} čet.),
						'per' => q({0}/čet.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sek.),
						'name' => q(sekunde),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sekunde),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} sedm.),
						'name' => q(sedmice),
						'one' => q({0} sedm.),
						'other' => q({0} sedm.),
						'per' => q({0}/sedm.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} sedm.),
						'name' => q(sedmice),
						'one' => q({0} sedm.),
						'other' => q({0} sedm.),
						'per' => q({0}/sedm.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} god.),
						'name' => q(godine),
						'one' => q({0} god.),
						'other' => q({0} god.),
						'per' => q({0}/god.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} god.),
						'name' => q(godine),
						'one' => q({0} god.),
						'other' => q({0} god.),
						'per' => q({0}/god.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperi),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperi),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(omi),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(omi),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volti),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volti),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} BTU),
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} BTU),
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} kal.),
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} kal.),
						'name' => q(kal.),
						'one' => q({0} kal.),
						'other' => q({0} kal.),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(džuli),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(džuli),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilodžul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilodžul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-sat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-sat),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100 km),
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100 km),
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} px),
						'name' => q(tačke),
						'one' => q({0} tačka),
						'other' => q({0} tačaka),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} px),
						'name' => q(tačke),
						'one' => q({0} tačka),
						'other' => q({0} tačaka),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} aj),
						'name' => q(aj),
						'one' => q({0} aj),
						'other' => q({0} aj),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} aj),
						'name' => q(aj),
						'one' => q({0} aj),
						'other' => q({0} aj),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} hvata),
						'name' => q(hvat),
						'one' => q({0} hvat),
						'other' => q({0} hvata),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} hvata),
						'name' => q(hvat),
						'one' => q({0} hvat),
						'other' => q({0} hvata),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(stope),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(stope),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} osmine milje),
						'name' => q(osmina milje),
						'one' => q({0} osmina milje),
						'other' => q({0} osmina milje),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} osmine milje),
						'name' => q(osmina milje),
						'one' => q({0} osmina milje),
						'other' => q({0} osmina milje),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inči),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inči),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sg),
						'name' => q(svjetlosne godine),
						'one' => q({0} sg),
						'other' => q({0} sg),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sg),
						'name' => q(svjetlosne godine),
						'one' => q({0} sg),
						'other' => q({0} sg),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metri),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metri),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milje),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milje),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parseci),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parseci),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} DTP tč),
						'name' => q(DTP tč),
						'one' => q({0} DTP tč),
						'other' => q({0} DTP tč),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} DTP tč),
						'name' => q(DTP tč),
						'one' => q({0} DTP tč),
						'other' => q({0} DTP tč),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardi),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardi),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luks),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} ct),
						'name' => q(karati),
						'one' => q({0} ct),
						'other' => q({0} CD),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} ct),
						'name' => q(karati),
						'one' => q({0} ct),
						'other' => q({0} CD),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grami),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grami),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lbs),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} lb),
						'one' => q({0} lb),
						'other' => q({0} lbs),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tone),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tone),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} ks),
						'name' => q(ks),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} ks),
						'name' => q(ks),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vati),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vati),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} čv),
						'name' => q(čv),
						'one' => q({0} čv),
						'other' => q({0} čv),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} čv),
						'name' => q(čv),
						'one' => q({0} čv),
						'other' => q({0} čv),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(šolje),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(šolje),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} kš. des.),
						'name' => q(kš. des.),
						'one' => q({0} kš. des.),
						'other' => q({0} kš. des.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} kš. des.),
						'name' => q(kš. des.),
						'one' => q({0} kš. des.),
						'other' => q({0} kš. des.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imp. kš. des.),
						'name' => q(imp. kš. des.),
						'one' => q({0} imp. kš. des.),
						'other' => q({0} imp. kš. des.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imp. kš. des.),
						'name' => q(imp. kš. des.),
						'one' => q({0} imp. kš. des.),
						'other' => q({0} imp. kš. des.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} teč. drama),
						'name' => q(teč. dram),
						'one' => q({0} teč. dram),
						'other' => q({0} teč. drama),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} teč. drama),
						'name' => q(teč. dram),
						'one' => q({0} teč. dram),
						'other' => q({0} teč. drama),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kapi),
						'name' => q(kap),
						'one' => q({0} kap),
						'other' => q({0} kapi),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kapi),
						'name' => q(kap),
						'one' => q({0} kap),
						'other' => q({0} kapi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} imp. fl oz),
						'name' => q(imp. fl oz),
						'one' => q({0} imp. fl oz),
						'other' => q({0} imp. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} imp. fl oz),
						'name' => q(imp. fl oz),
						'one' => q({0} imp. fl oz),
						'other' => q({0} imp. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} b. gal),
						'name' => q(B. gal),
						'one' => q({0} b. gal),
						'other' => q({0} b. gal),
						'per' => q({0}/b. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} b. gal),
						'name' => q(B. gal),
						'one' => q({0} b. gal),
						'other' => q({0} b. gal),
						'per' => q({0}/b. gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} male čašice),
						'name' => q(mala čašica),
						'one' => q({0} mala čašica),
						'other' => q({0} malih čašica),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} male čašice),
						'name' => q(mala čašica),
						'one' => q({0} mala čašica),
						'other' => q({0} malih čašica),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litri),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litri),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} prstohvata),
						'name' => q(prstohvat),
						'one' => q({0} prstohvat),
						'other' => q({0} prstohvata),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} prstohvata),
						'name' => q(prstohvat),
						'one' => q({0} prstohvat),
						'other' => q({0} prstohvata),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinte),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinte),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} imp. kvarca),
						'name' => q(imp. kvarc),
						'one' => q({0} imp. kvarc),
						'other' => q({0} imp. kvarca),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} imp. kvarca),
						'name' => q(imp. kvarc),
						'one' => q({0} imp. kvarc),
						'other' => q({0} imp. kvarca),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} kšk.),
						'one' => q({0} kšk.),
						'other' => q({0} tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} kšk.),
						'one' => q({0} kšk.),
						'other' => q({0} tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} kšč.),
						'one' => q({0} kšč.),
						'other' => q({0} tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} kšč.),
						'one' => q({0} kšč.),
						'other' => q({0} tsp),
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
				end => q({0} i {1}),
				2 => q({0} i {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
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
					'one' => '0 hilj'.'',
					'other' => '0 hilj'.'',
				},
				'10000' => {
					'one' => '00 hilj'.'',
					'other' => '00 hilj'.'',
				},
				'100000' => {
					'one' => '000 hilj'.'',
					'other' => '000 hilj'.'',
				},
				'1000000' => {
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'one' => '0 mlrd'.'',
					'other' => '0 mlrd'.'',
				},
				'10000000000' => {
					'one' => '00 mlrd'.'',
					'other' => '00 mlrd'.'',
				},
				'100000000000' => {
					'one' => '000 mlrd'.'',
					'other' => '000 mlrd'.'',
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
			display_name => {
				'currency' => q(Albanski lek),
				'few' => q(albanska leka),
				'one' => q(albanski lek),
				'other' => q(albanskih leka),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenski dram),
				'few' => q(armenska drama),
				'one' => q(armenski dram),
				'other' => q(armenskih drama),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Holandskoantilski gulden),
				'few' => q(holandskoantilska guldena),
				'one' => q(holandskoantilski gulden),
				'other' => q(holandskoantilskih guldena),
			},
		},
		'AOA' => {
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
				'few' => q(argentinska pezosa leja),
				'one' => q(argentinski pezos lej),
				'other' => q(argentinskih pezosa leja),
			},
		},
		'ARM' => {
			display_name => {
				'few' => q(argentinska pezosa moned nacional),
				'one' => q(argentinski pezos monedo nacional),
				'other' => q(argentinskih pezosa monedo nacional),
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
			display_name => {
				'currency' => q(Azerbejdžanski manat),
				'few' => q(azerbejdžanska manata),
				'one' => q(azerbejdžanski manat),
				'other' => q(azerbejdžanskih manata),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosanskohercegovački dinar),
				'few' => q(Bosanskohercegovačka dinara),
				'one' => q(bosanskohercegovački dinar),
				'other' => q(bosanskohercegovačkih dinara),
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
				'currency' => q(Bosanskohercegovački novi dinar),
				'few' => q(bosanskohercegovački novi dinari),
				'one' => q(bosanskohercegovački novi dinar),
				'other' => q(bosanskohercegovački novi dinar),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadoski dolar),
				'few' => q(barbadoska dolara),
				'one' => q(barbadoski dolar),
				'other' => q(barbadoskih dolara),
			},
		},
		'BDT' => {
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
			display_name => {
				'currency' => q(Bahreinski dinar),
				'few' => q(bahreinska dinara),
				'one' => q(bahreinski dinar),
				'other' => q(bahreinskih dinara),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundski franak),
				'few' => q(burundska franka),
				'one' => q(burundski franak),
				'other' => q(burundskih franaka),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudski dolar),
				'few' => q(bermudska dolara),
				'one' => q(bermudski dolar),
				'other' => q(bermudskih dolara),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunejski dolar),
				'few' => q(brunejska dolara),
				'one' => q(brunejski dolar),
				'other' => q(brunejskih dolara),
			},
		},
		'BOB' => {
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
			display_name => {
				'currency' => q(Bahamski dolar),
				'few' => q(bahamska dolara),
				'one' => q(bahamski dolar),
				'other' => q(bahamskih dolara),
			},
		},
		'BTN' => {
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
			symbol => 'р.',
			display_name => {
				'currency' => q(Bjeloruska rublja),
				'few' => q(bjeloruske rublje),
				'one' => q(bjeloruska rublja),
				'other' => q(bjeloruskih rubalja),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Bjeloruska rublja \(2000–2016\)),
				'few' => q(bjeloruske rublje \(2000–2016\)),
				'one' => q(bjeloruska rublja \(2000–2016\)),
				'other' => q(bjeloruskih rubalja \(2000–2016\)),
			},
		},
		'BZD' => {
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
				'few' => q(dolara kineske narodne banke),
				'one' => q(dolar kineske narodne banke),
				'other' => q(dolara kineske narodne banke),
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
			display_name => {
				'currency' => q(Kolumbijski pezos),
				'few' => q(kolumbijska pezosa),
				'one' => q(kolumbijski pezos),
				'other' => q(kolumbijskih pezosa),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Kolumbijski Unidade real de valor),
				'few' => q(unidad de valor reala),
				'one' => q(unidad de valor real),
				'other' => q(unidad de valor reala),
			},
		},
		'CRC' => {
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
			display_name => {
				'currency' => q(Kubanski konvertibilni pezos),
				'few' => q(kubanska konvertibilna pezosa),
				'one' => q(kubanski konvertibilni pezos),
				'other' => q(kubanskih konvertibilnih pezosa),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubanski pezos),
				'few' => q(kubanska pezosa),
				'one' => q(kubanski pezos),
				'other' => q(kubanskih pezosa),
			},
		},
		'CVE' => {
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
			display_name => {
				'currency' => q(Džibutski franak),
				'few' => q(džibutska franka),
				'one' => q(džibutski franak),
				'other' => q(džibutskih franaka),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danska kruna),
				'few' => q(danske krune),
				'one' => q(danska kruna),
				'other' => q(danskih kruna),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikanski pezos),
				'few' => q(dominikanska pezosa),
				'one' => q(dominikanski pezos),
				'other' => q(dominikanskih pezosa),
			},
		},
		'DZD' => {
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
			display_name => {
				'currency' => q(Egipatska funta),
				'few' => q(egipatske funte),
				'one' => q(egipatska funta),
				'other' => q(egipatskih funti),
			},
		},
		'ERN' => {
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
			display_name => {
				'currency' => q(Etiopski bir),
				'few' => q(etiopska bira),
				'one' => q(etiopski bir),
				'other' => q(etiopskih bira),
			},
		},
		'EUR' => {
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
			display_name => {
				'currency' => q(Fidžijski dolar),
				'few' => q(fidžijska dolara),
				'one' => q(fidžijski dolar),
				'other' => q(fidžijskih dolara),
			},
		},
		'FKP' => {
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
			display_name => {
				'currency' => q(Ganski cedi),
				'few' => q(ganska cedija),
				'one' => q(ganski cedi),
				'other' => q(ganskih cedija),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltarska funta),
				'few' => q(gibraltarske funte),
				'one' => q(gibraltarska funta),
				'other' => q(gibraltarskih funti),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambijski dalasi),
				'few' => q(gambijska dalasija),
				'one' => q(gambijski dalasi),
				'other' => q(gambijskih dalasija),
			},
		},
		'GNF' => {
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
			display_name => {
				'currency' => q(Haićanski gurd),
				'few' => q(haićanska gurda),
				'one' => q(haićanski gurd),
				'other' => q(haićanskih gurda),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Mađarska forinta),
				'few' => q(mađarske forinte),
				'one' => q(mađarska forinta),
				'other' => q(mađarskih forinti),
			},
		},
		'IDR' => {
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
			display_name => {
				'currency' => q(Indijska rupija),
				'few' => q(indijske rupije),
				'one' => q(indijska rupija),
				'other' => q(indijskih rupija),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irački dinar),
				'few' => q(iračka dinara),
				'one' => q(irački dinar),
				'other' => q(iračkih dinara),
			},
		},
		'IRR' => {
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
			},
		},
		'ISK' => {
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
			display_name => {
				'currency' => q(Jamajčanski dolar),
				'few' => q(jamajčanska dolara),
				'one' => q(jamajčanski dolar),
				'other' => q(jamajčanskih dolara),
			},
		},
		'JOD' => {
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
			display_name => {
				'currency' => q(Kenijski šiling),
				'few' => q(kenijska šilinga),
				'one' => q(kenijski šiling),
				'other' => q(kenijskih šilinga),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgistanski som),
				'few' => q(kirgistanska soma),
				'one' => q(kirgistanski som),
				'other' => q(kirgistanskih soma),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodžanski rijel),
				'few' => q(kambodžanska rijela),
				'one' => q(kambodžanski rijel),
				'other' => q(kambodžanskih rijela),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komorski franak),
				'few' => q(komorska franka),
				'one' => q(komorski franak),
				'other' => q(komorskih franaka),
			},
		},
		'KPW' => {
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
			display_name => {
				'currency' => q(Južnokorejski von),
				'few' => q(južnokorejska vona),
				'one' => q(južnokorejski von),
				'other' => q(južnokorejskih vona),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuvajtski dinar),
				'few' => q(kuvajtska dinara),
				'one' => q(kuvajtski dinar),
				'other' => q(kuvajtskih dinara),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kajmanski dolar),
				'few' => q(kajmanska dolara),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanskih dolara),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazahstanski tenge),
				'few' => q(kazahstanska tenga),
				'one' => q(kazahstanski tenge),
				'other' => q(kazahstanskih tenga),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laoski kip),
				'few' => q(laoska kipa),
				'one' => q(laoski kip),
				'other' => q(laoskih kipa),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libanska funta),
				'few' => q(libanske funte),
				'one' => q(libanska funta),
				'other' => q(libanskih funti),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Šrilankanska rupija),
				'few' => q(šrilankanske rupije),
				'one' => q(šrilankanska rupija),
				'other' => q(šrilankanskih rupija),
			},
		},
		'LRD' => {
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
			display_name => {
				'currency' => q(Libijski dinar),
				'few' => q(libijska dinara),
				'one' => q(libijski dinar),
				'other' => q(libijskih dinara),
			},
		},
		'MAD' => {
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
				'currency' => q(Moldavski kupon),
				'few' => q(moldovanska kupona),
				'one' => q(moldovanski kupon),
				'other' => q(moldovanskih kupona),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldavski lej),
				'few' => q(moldavska leja),
				'one' => q(moldavski lej),
				'other' => q(moldavskih leja),
			},
		},
		'MGA' => {
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
			display_name => {
				'currency' => q(Mijanmarski kjat),
				'few' => q(mijanmarska kjata),
				'one' => q(mijanmarski kjat),
				'other' => q(mijanmarskih kjata),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolski tugrik),
				'few' => q(mongolska tugrika),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskih tugrika),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makaonska pataka),
				'few' => q(makaonske patake),
				'one' => q(makaonska pataka),
				'other' => q(makaonskih pataka),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritanijska ugvija \(1973–2017\)),
				'few' => q(mauritanijske ugvije \(1973–2017\)),
				'one' => q(mauritanijska ugvija \(1973–2017\)),
				'other' => q(mauritanijskih ugvija \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritanijska ugvija),
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
			display_name => {
				'currency' => q(Mauricijska rupija),
				'few' => q(mauricijske rupije),
				'one' => q(mauricijska rupija),
				'other' => q(mauricijskih rupija),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivska rufija),
				'few' => q(maldivske rufije),
				'one' => q(maldivska rufija),
				'other' => q(maldivskih rufija),
			},
		},
		'MWK' => {
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
			display_name => {
				'currency' => q(Mozambijski metikal),
				'few' => q(mozambijska metikala),
				'one' => q(mozambijski metikal),
				'other' => q(mozambijskih metikala),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibijski dolar),
				'few' => q(namibijska dolara),
				'one' => q(namibijski dolar),
				'other' => q(namibijskih dolara),
			},
		},
		'NGN' => {
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
			display_name => {
				'currency' => q(Norveška kruna),
				'few' => q(norveške krune),
				'one' => q(norveška kruna),
				'other' => q(norveških kruna),
			},
		},
		'NPR' => {
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
			display_name => {
				'currency' => q(Omanski rijal),
				'few' => q(omanska rijala),
				'one' => q(omanski rijal),
				'other' => q(omanskih rijala),
			},
		},
		'PAB' => {
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
			display_name => {
				'currency' => q(Pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskih rupija),
			},
		},
		'PLN' => {
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
			display_name => {
				'currency' => q(Paragvajski gvarani),
				'few' => q(paragvajska gvaranija),
				'one' => q(paragvajski gvarani),
				'other' => q(paragvajskih gvaranija),
			},
		},
		'QAR' => {
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
			display_name => {
				'currency' => q(Ruandski franak),
				'few' => q(ruandska franka),
				'one' => q(ruandski franak),
				'other' => q(ruandskih franaka),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudijski rijal),
				'few' => q(saudijska rijala),
				'one' => q(saudijski rijal),
				'other' => q(saudijskih rijala),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomonski dolar),
				'few' => q(solomonska dolara),
				'one' => q(solomonski dolar),
				'other' => q(solomonskih dolara),
			},
		},
		'SCR' => {
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
			display_name => {
				'currency' => q(Švedska kruna),
				'few' => q(švedske krune),
				'one' => q(švedska kruna),
				'other' => q(švedskih kruna),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapurski dolar),
				'few' => q(singapurska dolara),
				'one' => q(singapurski dolar),
				'other' => q(singapurskih dolara),
			},
		},
		'SHP' => {
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
		'SLE' => {
			display_name => {
				'currency' => q(Sijeraleonski leone),
				'few' => q(sijeraleonska leona),
				'one' => q(sijeraleonski leone),
				'other' => q(sijeraleonskih leona),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sijeraleonski leone \(1964—2022\)),
				'few' => q(sijeraleonska leona \(1964—2022\)),
				'one' => q(sijeraleonski leone \(1964—2022\)),
				'other' => q(sijeraleonskih leona \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalski šiling),
				'few' => q(somalska šilinga),
				'one' => q(somalski šiling),
				'other' => q(somalskih šilinga),
			},
		},
		'SRD' => {
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
			display_name => {
				'currency' => q(Južnosudanska funta),
				'few' => q(južnosudanske funte),
				'one' => q(južnosudanska funta),
				'other' => q(južnosudanskih funti),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra Sao Toma i Principa \(1977–2017\)),
				'few' => q(dobre Sao Toma i Principa \(1977–2017\)),
				'one' => q(dobra Sao Toma i Principa \(1977–2017\)),
				'other' => q(dobri Sao Toma i Principa \(1977–2017\)),
			},
		},
		'STN' => {
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
			display_name => {
				'currency' => q(Sirijska funta),
				'few' => q(sirijske funte),
				'one' => q(sirijska funta),
				'other' => q(sirijskih funti),
			},
		},
		'SZL' => {
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
			display_name => {
				'currency' => q(Turkmenistanski manat),
				'few' => q(turkmenistanska manata),
				'one' => q(turkmenistanski manat),
				'other' => q(turkmenistanskih manata),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tuniški dinar),
				'few' => q(tuniška dinara),
				'one' => q(tuniški dinar),
				'other' => q(tuniških dinara),
			},
		},
		'TOP' => {
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
			display_name => {
				'currency' => q(Turska lira),
				'few' => q(turske lire),
				'one' => q(turska lira),
				'other' => q(turskih lira),
			},
		},
		'TTD' => {
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
			display_name => {
				'currency' => q(Tanzanijski šiling),
				'few' => q(tanzanijska šilinga),
				'one' => q(tanzanijski šiling),
				'other' => q(tanzanijskih šilinga),
			},
		},
		'UAH' => {
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
			display_name => {
				'currency' => q(Urugvajski pezos),
				'few' => q(urugvajska pezosa),
				'one' => q(urugvajski pezos),
				'other' => q(urugvajskih pezosa),
			},
		},
		'UZS' => {
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
			display_name => {
				'currency' => q(venecuelanski bolivar \(2008–2018\)),
				'few' => q(venecuelanska bolivara \(2008–2018\)),
				'one' => q(venecuelanski bolivar \(2008–2018\)),
				'other' => q(venecuelanskih bolivara \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venecuelanski bolivar),
				'few' => q(venecuelanska bolivara),
				'one' => q(venecuelanski bolivar),
				'other' => q(venecuelanskih bolivara),
			},
		},
		'VND' => {
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
			display_name => {
				'currency' => q(Vanuatski vatu),
				'few' => q(vanuatska vatua),
				'one' => q(vanuatski vatu),
				'other' => q(vanuatskih vatua),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoanska tala),
				'few' => q(samoanske tale),
				'one' => q(samoanska tala),
				'other' => q(samoanskih tala),
			},
		},
		'XAF' => {
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
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'1. mjesec',
							'2. mjesec',
							'3. mjesec',
							'4. mjesec',
							'5. mjesec',
							'6. mjesec',
							'7. mjesec',
							'8. mjesec',
							'9. mjesec',
							'10. mjesec',
							'11. mjesec',
							'12. mjesec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Prvi mjesec',
							'Drugi mjesec',
							'Treći mjesec',
							'Četvrti mjesec',
							'Peti mjesec',
							'Šesti mjesec',
							'Sedmi mjesec',
							'Osmi mjesec',
							'Deveti mjesec',
							'Deseti mjesec',
							'Jedanaesti mjesec',
							'Dvanaesti mjesec'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1. mjesec',
							'2. mjesec',
							'3. mjesec',
							'4. mjesec',
							'5. mjesec',
							'6. mjesec',
							'7. mjesec',
							'8. mjesec',
							'9. mjesec',
							'10.. mjesec',
							'11. mjesec',
							'12. mjesec'
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
							'jan',
							'feb',
							'mar',
							'apr',
							'maj',
							'jun',
							'jul',
							'aug',
							'sep',
							'okt',
							'nov',
							'dec'
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
							'august',
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
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'muh.',
							'saf.',
							'Rab. I',
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
							'Shaʻban',
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
					narrow => {
						mon => 'p',
						tue => 'u',
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
					abbreviated => {0 => 'KV1',
						1 => 'KV2',
						2 => 'KV3',
						3 => 'KV4'
					},
					wide => {0 => 'Prvi kvartal',
						1 => 'Drugi kvartal',
						2 => 'Treći kvartal',
						3 => 'Četvrti kvartal'
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
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					'afternoon1' => q{poslijepodne},
					'evening1' => q{navečer},
					'midnight' => q{ponoć},
					'morning1' => q{ujutro},
					'night1' => q{po noći},
					'noon' => q{podne},
				},
				'narrow' => {
					'am' => q{prijepodne},
					'pm' => q{popodne},
				},
				'wide' => {
					'am' => q{prijepodne},
					'pm' => q{popodne},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{prijepodne},
					'pm' => q{popodne},
				},
				'wide' => {
					'am' => q{prijepodne},
					'pm' => q{popodne},
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
		'chinese' => {
		},
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'p. n. e.',
				'1' => 'n. e.'
			},
			narrow => {
				'0' => 'p.n.e.'
			},
			wide => {
				'0' => 'prije nove ere',
				'1' => 'nove ere'
			},
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'prije R.O.C.'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'full' => q{E, d.M.y.},
			'long' => q{d.M.y.},
			'medium' => q{d.M.y.},
			'short' => q{d.M.y.},
		},
		'dangi' => {
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
			'short' => q{d. M. y.},
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
		'chinese' => {
		},
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'chinese' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'dangi' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'islamic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
		'chinese' => {
			Ed => q{d E},
			Gy => q{r(U)},
		},
		'generic' => {
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{MMM y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			H => q{H},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			y => q{y. G},
			yyyy => q{y. G},
			yyyyM => q{MM/y G},
			yyyyMEd => q{E, d.M.y. G},
			yyyyMMM => q{MMM y. G},
			yyyyMMMEd => q{E, d. MMM y. G},
			yyyyMMMM => q{LLLL y. G},
			yyyyMMMd => q{d. MMM y. G},
			yyyyMd => q{d.M.y. G},
		},
		'gregorian' => {
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{MMM y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			GyMd => q{d/M/y. G},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{W. 'sedmica' 'mjesec' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d. M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
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
			yw => q{w. 'sedmica' 'u' Y.},
		},
		'islamic' => {
			Ed => q{E, dd.},
			MEd => q{E, dd.MM.},
			MMMEd => q{E, dd. MMM},
			MMMd => q{dd. MMM},
			Md => q{dd.MM.},
			yM => q{MM.y. G},
			yMEd => q{E, dd.MM.y. G},
			yMMM => q{MMM y. G},
			yMMMEd => q{E, dd. MMM y. G},
			yMMMd => q{dd. MMM y. G},
			yMd => q{dd.MM.y. G},
			yQQQ => q{y G QQQ},
			yQQQQ => q{y G QQQQ},
		},
		'japanese' => {
			Gy => q{y. GGG},
			MEd => q{E, d. M.},
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
		'roc' => {
			M => q{L.},
			d => q{d.},
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
		'dangi' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'generic' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
			H => {
				H => q{HH – HH'h'},
			},
			Hv => {
				H => q{HH – HH 'h' v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMMEd => {
				M => q{E, dd. MMM – E, dd. MMM},
				d => q{E, dd. – E, dd. MMM},
			},
			MMMd => {
				M => q{dd. MMM – dd. MMM},
				d => q{dd. – dd. MMM},
			},
			Md => {
				M => q{d.M. – d.M.},
				d => q{d.M. – d.M.},
			},
			d => {
				d => q{d. – d.},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h'h' a},
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
				h => q{h – h 'h' a v},
			},
			y => {
				y => q{y. – y. G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, d.M.y. – E, d.M.y. G},
				d => q{E, d.M.y. – E, d.M.y. G},
				y => q{E, d.M.y. – E, d.M.y. G},
			},
			yMMM => {
				M => q{LLL–LLL y. G},
				y => q{LLL y. – LLL y. G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y. G},
				d => q{E, dd. – E, dd. MMM y. G},
				y => q{E, d. MMM y. – E, d. MMM y. G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y. G},
				y => q{LLLL y. – LLLL y. G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y. G},
				d => q{d. – d. MMM y. G},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{d.M.y. – d.M.y. G},
				d => q{d.M.y. – d.M.y. G},
				y => q{d.M.y. – d.M.y. G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y. G – y. G},
				y => q{y – y. G},
			},
			GyM => {
				G => q{M. y. G – M. y. G},
				M => q{M. y – M. y. G},
				y => q{M. y – M. y. G},
			},
			GyMEd => {
				G => q{E, d. M. y. G – E, d. M. y. G},
				M => q{E, d. M. y – E, d. M. y. G},
				d => q{E, d. M. y – E, d. M. y. G},
				y => q{E, d. M. y – E, d. M. y. G},
			},
			GyMMM => {
				G => q{MMM y. G – MMM y. G},
				M => q{MMM – MMM y. G},
				y => q{MMM y – MMM y. G},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{E, d. MMM – E, d. MMM y. G},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{d. MMM y. G – d. MMM y. G},
				M => q{d. MMM – d. MMM y. G},
				d => q{d – d. MMM y. G},
				y => q{d. MMM y – d. MMM y. G},
			},
			GyMd => {
				G => q{d. M. y. G – d. M. y. G},
				M => q{d. M. y – d. M. y. G},
				d => q{d. M. y – d. M. y. G},
				y => q{d. M. y – d. M. y. G},
			},
			H => {
				H => q{HH – HH'h'},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH 'h' v},
			},
			M => {
				M => q{M–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d. M – d. M.},
				d => q{d. M – d. M.},
			},
			d => {
				d => q{d–d.},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h'h' a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h 'h' a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d.M.y. – E, d.M.y.},
				d => q{E, d.M.y. – E, d.M.y.},
				y => q{E, d.M.y. – E, d.M.y.},
			},
			yMMM => {
				M => q{LLL – LLL y.},
				y => q{LLL y. – LLL y.},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y.},
				d => q{E, d. – E, d. MMM y.},
				y => q{E, d. MMM y. – E, d. MMM y.},
			},
			yMMMM => {
				M => q{LLLL – LLLL y.},
				y => q{LLLL y. – LLLL y.},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y.},
				d => q{d. – d. MMM y.},
				y => q{d. MMM y. – d. MMM y.},
			},
			yMd => {
				M => q{d.M.y. – d.M.y.},
				d => q{d. M. y – d. M. y.},
				y => q{d.M.y. – d.M.y.},
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
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(kreće proljeće),
						1 => q(kišnica),
						2 => q(bude se insekti),
						3 => q(proljetna ravnodnevica),
						4 => q(vedro),
						5 => q(kiša zrna),
						6 => q(kreće ljeto),
						7 => q(puno zrno),
						8 => q(zrelo zrno),
						9 => q(ljetni solsticij),
						10 => q(blaga vrućina),
						11 => q(velika vrućina),
						12 => q(kreće jesen),
						13 => q(kraj vrućine),
						14 => q(bijela rosa),
						15 => q(jesenja ravnodnevnica),
						16 => q(hladna rosa),
						17 => q(spušta se mraz),
						18 => q(kreće zima),
						19 => q(blagi snijeg),
						20 => q(veliki snijeg),
						21 => q(zimski solsticij),
						22 => q(blaga hladnoća),
						23 => q(jaka hladnoća),
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
		gmtFormat => q(GMT {0}),
		regionFormat => q({0}, ljetno vrijeme),
		regionFormat => q({0}, standardno vrijeme),
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
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablanka#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiš#,
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
		'America/Anguilla' => {
			exemplarCity => q#Angvila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigva#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
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
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gvadalupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
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
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoriko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
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
			exemplarCity => q#Atiraj#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
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
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
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
		'Asia/Kuching' => {
			exemplarCity => q#Kučing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
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
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnom Pen#,
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
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šangaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
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
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vijentijan#,
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
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rejkjavik#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sveta Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
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
		'Europe/Brussels' => {
			exemplarCity => q#Brisel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukurešt#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budimpešta#,
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
		'Europe/Guernsey' => {
			exemplarCity => q#Gernzi#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrvo Man#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalinjingrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britansko ljetno vrijeme#,
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
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
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
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Beč#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
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
		'Indian/Christmas' => {
			exemplarCity => q#Božićno ostrvo#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosova ostrva#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivi#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricijus#,
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
				'daylight' => q#Norfolško ljetno vrijeme#,
				'generic' => q#Norfolško vrijeme#,
				'standard' => q#Norfolško standardno vrijeme#,
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
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
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
		'Yukon' => {
			long => {
				'standard' => q#Jukonsko vrijeme#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
