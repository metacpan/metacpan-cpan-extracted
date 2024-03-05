=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ro - Package for language Romanian

=cut

package Locale::CLDR::Locales::Ro;
# This file auto generated from Data\common\main\ro.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-neuter','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=a),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=a),
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgulă →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(două),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→sprezece),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-feminine←zeci[ şi →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(una sută[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← sute[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(una mie[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← mii[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← milion[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← milioane[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← miliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← miliarde[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← bilion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← bilioane[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← biliard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← biliarde[ →→]),
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgulă →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(unu),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(doi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trei),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(patru),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinci),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(şase),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(şapte),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(opt),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nouă),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(zece),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(unsprezece),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→sprezece),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-feminine←zeci[ şi →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(una sută[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← sute[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(una mie[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← mii[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← milion[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← milioane[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← miliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← miliarde[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← bilion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← bilioane[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← biliard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← biliarde[ →→]),
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgulă →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(unu),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-feminine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-feminine←zeci[ şi →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(una sută[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← sute[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(una mie[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← mii[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← milion[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-neuter← milioane[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← miliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-neuter← miliarde[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← bilion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-neuter← bilioane[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← biliard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-neuter← biliarde[ →→]),
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
				'aa' => 'afar',
 				'ab' => 'abhază',
 				'ace' => 'aceh',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adyghe',
 				'ae' => 'avestană',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkadiană',
 				'ale' => 'aleută',
 				'alt' => 'altaică meridională',
 				'am' => 'amharică',
 				'an' => 'aragoneză',
 				'ang' => 'engleză veche',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabă',
 				'ar_001' => 'arabă standard modernă',
 				'arc' => 'aramaică',
 				'arn' => 'mapuche',
 				'arp' => 'arapaho',
 				'ars' => 'arabă najdi',
 				'arw' => 'arawak',
 				'as' => 'asameză',
 				'asa' => 'asu',
 				'ast' => 'asturiană',
 				'atj' => 'atikamekw',
 				'av' => 'avară',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azeră',
 				'ba' => 'bașkiră',
 				'bal' => 'baluchi',
 				'ban' => 'balineză',
 				'bas' => 'basaa',
 				'bax' => 'bamun',
 				'bbj' => 'ghomala',
 				'be' => 'belarusă',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'bulgară',
 				'bgc' => 'haryanvi',
 				'bgn' => 'baluchi occidentală',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengaleză',
 				'bo' => 'tibetană',
 				'br' => 'bretonă',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosniacă',
 				'bss' => 'akoose',
 				'bua' => 'buriat',
 				'bug' => 'bugineză',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'catalană',
 				'cad' => 'caddo',
 				'car' => 'carib',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'cecenă',
 				'ceb' => 'cebuană',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'chagatai',
 				'chk' => 'chuukese',
 				'chm' => 'mari',
 				'chn' => 'jargon chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'kurdă centrală',
 				'ckb@alt=menu' => 'kurdă, centrală',
 				'ckb@alt=variant' => 'kurdă sorani',
 				'clc' => 'chilcotin',
 				'co' => 'corsicană',
 				'cop' => 'coptă',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'turcă crimeeană',
 				'crj' => 'cree de sud-est',
 				'crk' => 'cree (Prerii)',
 				'crl' => 'cree de nord-est',
 				'crm' => 'cree (Moose)',
 				'crr' => 'algonquiană Carolina',
 				'crs' => 'creolă franceză seselwa',
 				'cs' => 'cehă',
 				'csb' => 'cașubiană',
 				'csw' => 'cree (Mlaștini)',
 				'cu' => 'slavonă',
 				'cv' => 'ciuvașă',
 				'cy' => 'galeză',
 				'da' => 'daneză',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'germană',
 				'de_CH' => 'germană standard (Elveția)',
 				'del' => 'delaware',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'sorabă de jos',
 				'dua' => 'duala',
 				'dum' => 'neerlandeză medie',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'egipteană veche',
 				'eka' => 'ekajuk',
 				'el' => 'greacă',
 				'elx' => 'elamită',
 				'en' => 'engleză',
 				'en_US@alt=short' => 'engleză (S.U.A)',
 				'enm' => 'engleză medie',
 				'eo' => 'esperanto',
 				'es' => 'spaniolă',
 				'es_ES' => 'spaniolă (Europa)',
 				'et' => 'estonă',
 				'eu' => 'bască',
 				'ewo' => 'ewondo',
 				'fa' => 'persană',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finlandeză',
 				'fil' => 'filipineză',
 				'fj' => 'fijiană',
 				'fo' => 'feroeză',
 				'fon' => 'fon',
 				'fr' => 'franceză',
 				'frc' => 'franceză cajun',
 				'frm' => 'franceză medie',
 				'fro' => 'franceză veche',
 				'frr' => 'frizonă nordică',
 				'frs' => 'frizonă orientală',
 				'fur' => 'friulană',
 				'fy' => 'frizonă occidentală',
 				'ga' => 'irlandeză',
 				'gaa' => 'ga',
 				'gag' => 'găgăuză',
 				'gan' => 'chineză gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'gaelică scoțiană',
 				'gez' => 'geez',
 				'gil' => 'gilbertină',
 				'gl' => 'galiciană',
 				'gmh' => 'germană înaltă medie',
 				'gn' => 'guarani',
 				'goh' => 'germană înaltă veche',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotică',
 				'grb' => 'grebo',
 				'grc' => 'greacă veche',
 				'gsw' => 'germană (Elveția)',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'chineză hakka',
 				'haw' => 'hawaiiană',
 				'hax' => 'haida de sud',
 				'he' => 'ebraică',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'hiligaynon',
 				'hit' => 'hitită',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croată',
 				'hsb' => 'sorabă de sus',
 				'hsn' => 'chineză xiang',
 				'ht' => 'haitiană',
 				'hu' => 'maghiară',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armeană',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indoneziană',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yi din Sichuan',
 				'ik' => 'inupiak',
 				'ikt' => 'inuktitut canadiană occidentală',
 				'ilo' => 'iloko',
 				'inh' => 'ingușă',
 				'io' => 'ido',
 				'is' => 'islandeză',
 				'it' => 'italiană',
 				'iu' => 'inuktitut',
 				'ja' => 'japoneză',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'iudeo-persană',
 				'jrb' => 'iudeo-arabă',
 				'jv' => 'javaneză',
 				'ka' => 'georgiană',
 				'kaa' => 'karakalpak',
 				'kab' => 'kabyle',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardian',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koro',
 				'kg' => 'congoleză',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotaneză',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazahă',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalenjin',
 				'km' => 'khmeră',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'coreeană',
 				'koi' => 'komi-permiak',
 				'kok' => 'konkani',
 				'kos' => 'kosrae',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karaceai-balkar',
 				'krl' => 'kareliană',
 				'kru' => 'kurukh',
 				'ks' => 'cașmiră',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurdă',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'cornică',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'kârgâză',
 				'la' => 'latină',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgheză',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgheză',
 				'lij' => 'liguriană',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laoțiană',
 				'lol' => 'mongo',
 				'lou' => 'creolă (Louisiana)',
 				'loz' => 'lozi',
 				'lrc' => 'luri de nord',
 				'lsm' => 'saamia',
 				'lt' => 'lituaniană',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'letonă',
 				'mad' => 'madureză',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malgașă',
 				'mga' => 'irlandeză medie',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshalleză',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedoneană',
 				'ml' => 'malayalam',
 				'mn' => 'mongolă',
 				'mnc' => 'manciuriană',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'malaeză',
 				'mt' => 'malteză',
 				'mua' => 'mundang',
 				'mul' => 'mai multe limbi',
 				'mus' => 'creek',
 				'mwl' => 'mirandeză',
 				'mwr' => 'marwari',
 				'my' => 'birmană',
 				'mye' => 'myene',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nan' => 'chineză min nan',
 				'nap' => 'napolitană',
 				'naq' => 'nama',
 				'nb' => 'norvegiană bokmål',
 				'nd' => 'ndebele de nord',
 				'nds' => 'germana de jos',
 				'nds_NL' => 'saxona de jos',
 				'ne' => 'nepaleză',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueană',
 				'nl' => 'neerlandeză',
 				'nl_BE' => 'flamandă',
 				'nmg' => 'kwasio',
 				'nn' => 'norvegiană nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvegiană',
 				'nog' => 'nogai',
 				'non' => 'nordică veche',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele de sud',
 				'nso' => 'sotho de nord',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newari clasică',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitană',
 				'oj' => 'ojibwa',
 				'ojb' => 'ojibwa de nord-vest',
 				'ojc' => 'ojibwa centrală',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojibwa de vest',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'osetă',
 				'osa' => 'osage',
 				'ota' => 'turcă otomană',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauană',
 				'pcm' => 'pidgin nigerian',
 				'peo' => 'persană veche',
 				'phn' => 'feniciană',
 				'pi' => 'pali',
 				'pis' => 'pijin',
 				'pl' => 'poloneză',
 				'pon' => 'pohnpeiană',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'prusacă',
 				'pro' => 'provensală veche',
 				'ps' => 'paștună',
 				'ps@alt=variant' => 'pushto',
 				'pt' => 'portugheză',
 				'pt_PT' => 'portugheză (Europa)',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongan',
 				'rhg' => 'rohingya',
 				'rm' => 'romanșă',
 				'rn' => 'kirundi',
 				'ro' => 'română',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'ru' => 'rusă',
 				'rup' => 'aromână',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanscrită',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'sam' => 'aramaică samariteană',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardiniană',
 				'scn' => 'siciliană',
 				'sco' => 'scots',
 				'sd' => 'sindhi',
 				'sdh' => 'kurdă de sud',
 				'se' => 'sami de nord',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro Senni',
 				'sg' => 'sango',
 				'sga' => 'irlandeză veche',
 				'sh' => 'sârbo-croată',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'arabă ciadiană',
 				'si' => 'singhaleză',
 				'sid' => 'sidamo',
 				'sk' => 'slovacă',
 				'sl' => 'slovenă',
 				'slh' => 'lushootseed de usd',
 				'sm' => 'samoană',
 				'sma' => 'sami de sud',
 				'smj' => 'sami lule',
 				'smn' => 'sami inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somaleză',
 				'sog' => 'sogdien',
 				'sq' => 'albaneză',
 				'sr' => 'sârbă',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sesotho',
 				'str' => 'salish (Strâmtori)',
 				'su' => 'sundaneză',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeriană',
 				'sv' => 'suedeză',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili (R.D. Congo)',
 				'swb' => 'comoreză',
 				'syc' => 'siriacă clasică',
 				'syr' => 'siriacă',
 				'ta' => 'tamilă',
 				'tce' => 'tutchone de sud',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadjică',
 				'tgx' => 'tagish',
 				'th' => 'thailandeză',
 				'tht' => 'tahltan',
 				'ti' => 'tigrină',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turkmenă',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingoniană',
 				'tli' => 'tlingit',
 				'tmh' => 'tamashek',
 				'tn' => 'setswana',
 				'to' => 'tongană',
 				'tog' => 'nyasa tonga',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turcă',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tătară',
 				'ttm' => 'tutchone de nord',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiană',
 				'tyv' => 'tuvană',
 				'tzm' => 'tamazight din Atlasul Central',
 				'udm' => 'udmurt',
 				'ug' => 'uigură',
 				'uga' => 'ugaritică',
 				'uk' => 'ucraineană',
 				'umb' => 'umbundu',
 				'und' => 'limbă necunoscută',
 				'ur' => 'urdu',
 				'uz' => 'uzbecă',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'venetă',
 				'vi' => 'vietnameză',
 				'vo' => 'volapuk',
 				'vot' => 'votică',
 				'vun' => 'vunjo',
 				'wa' => 'valonă',
 				'wae' => 'walser',
 				'wal' => 'wolaita',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'chineză wu',
 				'xal' => 'calmucă',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapeză',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'idiș',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantoneză',
 				'yue@alt=menu' => 'chineză, cantoneză',
 				'za' => 'zhuang',
 				'zap' => 'zapotecă',
 				'zbl' => 'simboluri Bilss',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight standard marocană',
 				'zh' => 'chineză',
 				'zh@alt=menu' => 'chineză, mandarină',
 				'zh_Hans' => 'chineză simplificată',
 				'zh_Hans@alt=long' => 'chineză mandarină simplificată',
 				'zh_Hant' => 'chineză tradițională',
 				'zh_Hant@alt=long' => 'chineză mandarină tradițională',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'fară conținut lingvistic',
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
			'Adlm' => 'adlam',
 			'Aghb' => 'albaneză caucaziană',
 			'Ahom' => 'ahom',
 			'Arab' => 'arabă',
 			'Arab@alt=variant' => 'persano-arabă',
 			'Aran' => 'nastaaliq',
 			'Armi' => 'aramaică imperială',
 			'Armn' => 'armeană',
 			'Avst' => 'avestică',
 			'Bali' => 'balineză',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengaleză',
 			'Bhks' => 'bhaiksuki',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmanică',
 			'Brai' => 'braille',
 			'Bugi' => 'bugineză',
 			'Buhd' => 'buhidă',
 			'Cakm' => 'chakma',
 			'Cans' => 'silabică aborigenă canadiană unificată',
 			'Cari' => 'cariană',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Chrs' => 'khorezmiană',
 			'Copt' => 'coptă',
 			'Cpmn' => 'cipro-minoană',
 			'Cprt' => 'cipriotă',
 			'Cyrl' => 'chirilică',
 			'Cyrs' => 'chirilică slavonă bisericească veche',
 			'Deva' => 'devanagari',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogra',
 			'Dsrt' => 'mormonă',
 			'Dupl' => 'stenografie duployană',
 			'Egyd' => 'demotică egipteană',
 			'Egyh' => 'hieratică egipteană',
 			'Egyp' => 'hieroglife egiptene',
 			'Elba' => 'elbasan',
 			'Elym' => 'elimaică',
 			'Ethi' => 'etiopiană',
 			'Geok' => 'georgiană bisericească',
 			'Geor' => 'georgiană',
 			'Glag' => 'glagolitică',
 			'Gong' => 'gunjala gondi',
 			'Gonm' => 'masaram gondi',
 			'Goth' => 'gotică',
 			'Gran' => 'grantha',
 			'Grek' => 'greacă',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'simplificată',
 			'Hans@alt=stand-alone' => 'han simplificată',
 			'Hant' => 'tradițională',
 			'Hant@alt=stand-alone' => 'han tradițională',
 			'Hatr' => 'hatrană',
 			'Hebr' => 'ebraică',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hieroglife anatoliene',
 			'Hmng' => 'pahawh hmong',
 			'Hmnp' => 'nyiakeng puachue hmong',
 			'Hrkt' => 'silabică japoneză',
 			'Hung' => 'maghiară veche',
 			'Inds' => 'indus',
 			'Ital' => 'italică veche',
 			'Jamo' => 'jamo',
 			'Java' => 'javaneză',
 			'Jpan' => 'japoneză',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Kawi' => 'kawi',
 			'Khar' => 'kharosthi',
 			'Khmr' => 'khmeră',
 			'Khoj' => 'khojki',
 			'Kits' => 'litere mici khitane',
 			'Knda' => 'kannada',
 			'Kore' => 'coreeană',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laoțiană',
 			'Latf' => 'latină Fraktur',
 			'Latg' => 'latină gaelică',
 			'Latn' => 'latină',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineară A',
 			'Linb' => 'lineară B',
 			'Lisu' => 'fraser',
 			'Lyci' => 'liciană',
 			'Lydi' => 'lidiană',
 			'Mahj' => 'mahajani',
 			'Maka' => 'makasar',
 			'Mand' => 'mandeană',
 			'Mani' => 'maniheeană',
 			'Marc' => 'marchen',
 			'Maya' => 'hieroglife maya',
 			'Medf' => 'medefaidrin',
 			'Mend' => 'mende',
 			'Merc' => 'meroitică cursivă',
 			'Mero' => 'meroitică',
 			'Mlym' => 'malayalam',
 			'Modi' => 'modi',
 			'Mong' => 'mongolă',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei mayek',
 			'Mult' => 'multani',
 			'Mymr' => 'birmană',
 			'Nagm' => 'nag mundari',
 			'Nand' => 'nandinagari',
 			'Narb' => 'arabă veche din nord',
 			'Nbat' => 'nabateeană',
 			'Newa' => 'newa',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orhon',
 			'Orya' => 'oriya',
 			'Osge' => 'osage',
 			'Osma' => 'osmanya',
 			'Ougr' => 'uigură veche',
 			'Palm' => 'palmirenă',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'permică veche',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavi pentru inscripții',
 			'Phlp' => 'pahlavi pentru psaltire',
 			'Phnx' => 'feniciană',
 			'Plrd' => 'pollardă fonetică',
 			'Prti' => 'partă pentru inscripții',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Runr' => 'runică',
 			'Samr' => 'samariteană',
 			'Sarb' => 'arabă veche din sud',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'scrierea simbolică',
 			'Shaw' => 'savă',
 			'Shrd' => 'sharadă',
 			'Sidd' => 'siddham',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'singaleză',
 			'Sogd' => 'sogdiană',
 			'Sogo' => 'sogdiană veche',
 			'Sora' => 'sora sompeng',
 			'Soyo' => 'soyombo',
 			'Sund' => 'sundaneză',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siriacă',
 			'Syrj' => 'siriacă occidentală',
 			'Syrn' => 'siriacă orientală',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai le nouă',
 			'Taml' => 'tamilă',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandeză',
 			'Tibt' => 'tibetană',
 			'Tirh' => 'tirhuta',
 			'Tnsa' => 'tangsa',
 			'Toto' => 'toto',
 			'Ugar' => 'ugaritică',
 			'Vaii' => 'vai',
 			'Vith' => 'vithkuqi',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wancho',
 			'Xpeo' => 'persană veche',
 			'Xsux' => 'cuneiformă sumero-akkadiană',
 			'Yezi' => 'yazidită',
 			'Yiii' => 'yi',
 			'Zanb' => 'Piața Zanabazar',
 			'Zinh' => 'moștenită',
 			'Zmth' => 'notație matematică',
 			'Zsye' => 'emoji',
 			'Zsym' => 'simboluri',
 			'Zxxx' => 'nescrisă',
 			'Zyyy' => 'comună',
 			'Zzzz' => 'scriere necunoscută',

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
			'001' => 'Lume',
 			'002' => 'Africa',
 			'003' => 'America de Nord',
 			'005' => 'America de Sud',
 			'009' => 'Oceania',
 			'011' => 'Africa Occidentală',
 			'013' => 'America Centrală',
 			'014' => 'Africa Orientală',
 			'015' => 'Africa Septentrională',
 			'017' => 'Africa Centrală',
 			'018' => 'Africa Meridională',
 			'019' => 'Americi',
 			'021' => 'America Septentrională',
 			'029' => 'Caraibe',
 			'030' => 'Asia Orientală',
 			'034' => 'Asia Meridională',
 			'035' => 'Asia de Sud-Est',
 			'039' => 'Europa Meridională',
 			'053' => 'Australasia',
 			'054' => 'Melanezia',
 			'057' => 'Regiunea Micronezia',
 			'061' => 'Polinezia',
 			'142' => 'Asia',
 			'143' => 'Asia Centrală',
 			'145' => 'Asia Occidentală',
 			'150' => 'Europa',
 			'151' => 'Europa Orientală',
 			'154' => 'Europa Septentrională',
 			'155' => 'Europa Occidentală',
 			'202' => 'Africa Subsahariană',
 			'419' => 'America Latină',
 			'AC' => 'Insula Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratele Arabe Unite',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua și Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americană',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Insulele Åland',
 			'AZ' => 'Azerbaidjan',
 			'BA' => 'Bosnia și Herțegovina',
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
 			'BQ' => 'Insulele Caraibe Olandeze',
 			'BR' => 'Brazilia',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Insula Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Insulele Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (Republica Democrată Congo)',
 			'CF' => 'Republica Centrafricană',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republica)',
 			'CH' => 'Elveția',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Coasta de Fildeș',
 			'CK' => 'Insulele Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerun',
 			'CN' => 'China',
 			'CO' => 'Columbia',
 			'CP' => 'Insula Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Capul Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Insula Christmas',
 			'CY' => 'Cipru',
 			'CZ' => 'Cehia',
 			'CZ@alt=variant' => 'Republica Cehă',
 			'DE' => 'Germania',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danemarca',
 			'DM' => 'Dominica',
 			'DO' => 'Republica Dominicană',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta și Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipt',
 			'EH' => 'Sahara Occidentală',
 			'ER' => 'Eritreea',
 			'ES' => 'Spania',
 			'ET' => 'Etiopia',
 			'EU' => 'Uniunea Europeană',
 			'EZ' => 'Zona euro',
 			'FI' => 'Finlanda',
 			'FJ' => 'Fiji',
 			'FK' => 'Insulele Falkland',
 			'FK@alt=variant' => 'Insulele Falkland (Insulele Malvine)',
 			'FM' => 'Micronezia',
 			'FO' => 'Insulele Feroe',
 			'FR' => 'Franța',
 			'GA' => 'Gabon',
 			'GB' => 'Regatul Unit',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guyana Franceză',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlanda',
 			'GM' => 'Gambia',
 			'GN' => 'Guineea',
 			'GP' => 'Guadelupa',
 			'GQ' => 'Guineea Ecuatorială',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia de Sud și Insulele Sandwich de Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guineea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'R.A.S. Hong Kong, China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Insula Heard și Insulele McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croația',
 			'HT' => 'Haiti',
 			'HU' => 'Ungaria',
 			'IC' => 'Insulele Canare',
 			'ID' => 'Indonezia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Insula Man',
 			'IN' => 'India',
 			'IO' => 'Teritoriul Britanic din Oceanul Indian',
 			'IO@alt=chagos' => 'Arhipelagul Chagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Iordania',
 			'JP' => 'Japonia',
 			'KE' => 'Kenya',
 			'KG' => 'Kârgâzstan',
 			'KH' => 'Cambodgia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comore',
 			'KN' => 'Saint Kitts și Nevis',
 			'KP' => 'Coreea de Nord',
 			'KR' => 'Coreea de Sud',
 			'KW' => 'Kuweit',
 			'KY' => 'Insulele Cayman',
 			'KZ' => 'Kazahstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Sfânta Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburg',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Maroc',
 			'MC' => 'Monaco',
 			'MD' => 'Republica Moldova',
 			'ME' => 'Muntenegru',
 			'MF' => 'Sfântul Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Insulele Marshall',
 			'MK' => 'Macedonia de Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'R.A.S. Macao, China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Insulele Mariane de Nord',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldive',
 			'MW' => 'Malawi',
 			'MX' => 'Mexic',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambic',
 			'NA' => 'Namibia',
 			'NC' => 'Noua Caledonie',
 			'NE' => 'Niger',
 			'NF' => 'Insula Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Țările de Jos',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Noua Zeelandă',
 			'NZ@alt=variant' => 'Aotearoa Noua Zeelandă',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinezia Franceză',
 			'PG' => 'Papua-Noua Guinee',
 			'PH' => 'Filipine',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'Saint-Pierre și Miquelon',
 			'PN' => 'Insulele Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Teritoriile Palestiniene',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalia',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceania Periferică',
 			'RE' => 'Réunion',
 			'RO' => 'România',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arabia Saudită',
 			'SB' => 'Insulele Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Suedia',
 			'SG' => 'Singapore',
 			'SH' => 'Sfânta Elena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard și Jan Mayen',
 			'SK' => 'Slovacia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudanul de Sud',
 			'ST' => 'São Tomé și Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint-Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Insulele Turks și Caicos',
 			'TD' => 'Ciad',
 			'TF' => 'Teritoriile Australe și Antarctice Franceze',
 			'TG' => 'Togo',
 			'TH' => 'Thailanda',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timorul de Est',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turcia',
 			'TR@alt=variant' => 'Türkiye',
 			'TT' => 'Trinidad și Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Insulele Îndepărtate ale S.U.A.',
 			'UN' => 'Națiunile Unite',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Statele Unite ale Americii',
 			'US@alt=short' => 'S.U.A.',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Statul Cetății Vaticanului',
 			'VC' => 'Saint Vincent și Grenadinele',
 			'VE' => 'Venezuela',
 			'VG' => 'Insulele Virgine Britanice',
 			'VI' => 'Insulele Virgine Americane',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis și Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-accente',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Africa de Sud',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Regiune necunoscută',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografie germană tradițională',
 			'1994' => 'ortografie resiană standardizată',
 			'1996' => 'ortografie germană de la 1996',
 			'1606NICT' => 'franceză medievală târzie până la 1606',
 			'1694ACAD' => 'franceză modernă veche',
 			'1959ACAD' => 'belarusă academică',
 			'ABL1943' => 'formularea ortografică de la 1943',
 			'AKUAPEM' => 'Akuapem',
 			'ALALC97' => 'ALA-LC, ediția din 1997',
 			'ALUKU' => 'dialect aluku',
 			'AO1990' => 'Acordul de ortografie a limbii portugheze de la 1990',
 			'ARANES' => 'Aranes',
 			'AREVELA' => 'armeană orientală',
 			'AREVMDA' => 'armeană occidentală',
 			'ARKAIKA' => 'Arkaika',
 			'ASANTE' => 'Asante',
 			'AUVERN' => 'Auvern',
 			'BAKU1926' => 'alfabet latin altaic unificat',
 			'BALANKA' => 'dialectul balanka al limbii anii',
 			'BARLA' => 'grupul de dialecte barlavento al limbii kabuverdianu',
 			'BASICENG' => 'Basiceng',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Biscayan',
 			'BISKE' => 'dialect San Giorgio/Bila',
 			'BOHORIC' => 'alfabet Bohorič',
 			'BOONT' => 'boontling',
 			'BORNHOLM' => 'Bornholm',
 			'CISAUP' => 'Cisaup',
 			'COLB1945' => 'Convenția ortografică a limbii portugheze braziliene de la 1945',
 			'CORNU' => 'Cornu',
 			'CREISS' => 'Creiss',
 			'DAJNKO' => 'alfabet dajnko',
 			'EKAVSK' => 'sârbă cu pronunție ekaviană',
 			'EMODENG' => 'limba engleză modernă timpurie',
 			'FONIPA' => 'alfabet fonetic internațional',
 			'FONKIRSH' => 'Fonkirsh',
 			'FONNAPA' => 'Fonnapa',
 			'FONUPA' => 'alfabet fonetic uralic',
 			'FONXSAMP' => 'Fonxsamp',
 			'GALLO' => 'Gallo',
 			'GASCON' => 'Gascon',
 			'GRCLASS' => 'Grclass',
 			'GRITAL' => 'Grital',
 			'GRMISTR' => 'Grmistr',
 			'HEPBURN' => 'hepburn',
 			'HOGNORSK' => 'Hognorsk',
 			'HSISTEMO' => 'Hsistemo',
 			'IJEKAVSK' => 'sârbă cu pronunție ijekaviană',
 			'ITIHASA' => 'Itihasa',
 			'IVANCHOV' => 'Ivanchov',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'ortografie comuna cornish',
 			'KOCIEWIE' => 'Kociewie',
 			'KSCOR' => 'ortografie standard',
 			'LAUKIKA' => 'Laukika',
 			'LEMOSIN' => 'Lemosin',
 			'LENGADOC' => 'Lengadoc',
 			'LIPAW' => 'dialect lipovaz din resiană',
 			'LUNA1918' => 'Luna1918',
 			'METELKO' => 'alfabet metelko',
 			'MONOTON' => 'monotonică',
 			'NDYUKA' => 'dialect ndyuka',
 			'NEDIS' => 'dialect Natisone',
 			'NEWFOUND' => 'Newfound',
 			'NICARD' => 'Nicard',
 			'NJIVA' => 'dialect Gniva/Njiva',
 			'NULIK' => 'volapük modernă',
 			'OSOJS' => 'dialect Oseacco/Osojane',
 			'OXENDICT' => 'ortografia dicționarului Oxford de limbă engleză',
 			'PAHAWH2' => 'Pahawh2',
 			'PAHAWH3' => 'Pahawh3',
 			'PAHAWH4' => 'Pahawh4',
 			'PAMAKA' => 'dialect pamaka',
 			'PEANO' => 'Peano',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'politonică',
 			'POSIX' => 'informatică',
 			'PROVENC' => 'Provenc',
 			'PUTER' => 'Puter',
 			'REVISED' => 'ortografie revizuită',
 			'RIGIK' => 'volapük clasică',
 			'ROZAJ' => 'dialect resian',
 			'RUMGR' => 'Rumgr',
 			'SAAHO' => 'dialect saho',
 			'SCOTLAND' => 'engleză standard scoțiană',
 			'SCOUSE' => 'dialect scouse',
 			'SIMPLE' => 'Simple',
 			'SOLBA' => 'dialect Stolvizza/Solbica',
 			'SOTAV' => 'grupul de dialecte sotavento al limbii kabuverdianu',
 			'SPANGLIS' => 'Spanglis',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilv',
 			'SUTSILV' => 'Sutsilv',
 			'SYNNEJYL' => 'Synnejyl',
 			'TARASK' => 'ortografie taraskievica',
 			'TONGYONG' => 'Tongyong',
 			'TUNUMIIT' => 'Tunumiit',
 			'UCCOR' => 'ortografie unificată cornish',
 			'UCRCOR' => 'ortografie revizuită unificată cornish',
 			'ULSTER' => 'Ulster',
 			'UNIFON' => 'alfabet fonetic unifon',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'valenciană',
 			'VALLADER' => 'Vallader',
 			'VECDRUKA' => 'Vecdruka',
 			'VIVARAUP' => 'Vivaraup',
 			'WADEGILE' => 'Wade-Giles',
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
			'calendar' => 'tip calendar',
 			'cf' => 'Format monedă',
 			'colalternate' => 'sortare cu ignorarea simbolurilor',
 			'colbackwards' => 'sortare inversă după accent',
 			'colcasefirst' => 'sortare după majuscule/minuscule',
 			'colcaselevel' => 'sortare care ține seama de majuscule/minuscule',
 			'collation' => 'ordine de sortare',
 			'colnormalization' => 'sortare normalizată',
 			'colnumeric' => 'sortare numerică',
 			'colstrength' => 'puterea sortării',
 			'currency' => 'monedă',
 			'hc' => 'ciclu orar (12 sau 24)',
 			'lb' => 'stil de întrerupere a liniei',
 			'ms' => 'sistem de unități de măsură',
 			'numbers' => 'numere',
 			'timezone' => 'fus orar',
 			'va' => 'variantă locală',
 			'x' => 'utilizare privată',

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
 				'buddhist' => q{calendar budist},
 				'chinese' => q{calendar chinezesc},
 				'coptic' => q{calendar copt},
 				'dangi' => q{calendar dangi},
 				'ethiopic' => q{calendar etiopian},
 				'ethiopic-amete-alem' => q{calendar etiopian amete alem},
 				'gregorian' => q{calendar gregorian},
 				'hebrew' => q{calendar ebraic},
 				'indian' => q{calendar național indian},
 				'islamic' => q{calendarul hegirei},
 				'islamic-civil' => q{calendarul hegirei (tabular, civil)},
 				'islamic-rgsa' => q{calendar islamic (Arabia Saudită, lunar)},
 				'islamic-tbla' => q{calendar islamic (tabular, epocă astronomică)},
 				'islamic-umalqura' => q{calendarul hegirei (Umm al-Qura)},
 				'iso8601' => q{calendar ISO-8601},
 				'japanese' => q{calendar japonez},
 				'persian' => q{calendar persan},
 				'roc' => q{calendarul Republicii Chineze},
 			},
 			'cf' => {
 				'account' => q{Format monedă contabilitate},
 				'standard' => q{Format monedă standard},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ordonați simbolurile},
 				'shifted' => q{Ordonați ignorând simbolurile},
 			},
 			'colbackwards' => {
 				'no' => q{Ordonați accentele în mod normal},
 				'yes' => q{Ordonați după accente în ordine inversă},
 			},
 			'colcasefirst' => {
 				'lower' => q{Ordonați întâi minusculele},
 				'no' => q{Ordonați după dimensiunea normală a literei},
 				'upper' => q{Ordonați mai întâi majusculele},
 			},
 			'colcaselevel' => {
 				'no' => q{Ordonați neținând seama de diferența dintre majuscule/minuscule},
 				'yes' => q{Ordonați ținând seama de diferența dintre majuscule/minuscule},
 			},
 			'collation' => {
 				'big5han' => q{ordine de sortare a chinezei tradiționale - Big5},
 				'compat' => q{ordine de sortare anterioară, pentru compatibilitate},
 				'dictionary' => q{ordine de sortare a dicționarului},
 				'ducet' => q{ordine de sortare Unicode implicită},
 				'emoji' => q{ordine de sortare a emojiurilor},
 				'eor' => q{regulile europene de sortare},
 				'gb2312han' => q{ordine de sortare a chinezei simplificate - GB2312},
 				'phonebook' => q{ordine de sortare după cartea de telefon},
 				'phonetic' => q{ordine de sortare fonetică},
 				'pinyin' => q{ordine de sortare pinyin},
 				'reformed' => q{ordine de sortare reformată},
 				'search' => q{căutare cu scop general},
 				'searchjl' => q{Căutați în funcție de consoana inițială hangul},
 				'standard' => q{ordine de sortare standard},
 				'stroke' => q{ordine de sortare după trasare},
 				'traditional' => q{ordine de sortare tradițională},
 				'unihan' => q{ordine de sortare după radical și trasare},
 				'zhuyin' => q{ordine de sortare zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Ordonați fără normalizare},
 				'yes' => q{Ordonați caracterele unicode normalizat},
 			},
 			'colnumeric' => {
 				'no' => q{Ordonați cifrele individual},
 				'yes' => q{Ordonați cifrele în ordine numerică},
 			},
 			'colstrength' => {
 				'identical' => q{Ordonați-le pe toate},
 				'primary' => q{Ordonați numai literele de bază},
 				'quaternary' => q{Ordonați după accente/dimensiunea literei/lățime/kana},
 				'secondary' => q{Ordonați după accent},
 				'tertiary' => q{Ordonați după accente/dimensiunea literei/lățime},
 			},
 			'd0' => {
 				'fwidth' => q{Cu lățime întreagă},
 				'hwidth' => q{Cu jumătate de lățime},
 				'npinyin' => q{Numeric},
 			},
 			'hc' => {
 				'h11' => q{sistem cu 12 ore (0–11)},
 				'h12' => q{sistem cu 12 ore (1–12)},
 				'h23' => q{sistem cu 24 de ore (0–23)},
 				'h24' => q{sistem cu 24 de ore (1–24)},
 			},
 			'lb' => {
 				'loose' => q{stil liber de întrerupere a liniei},
 				'normal' => q{stil normal de întrerupere a liniei},
 				'strict' => q{stil strict de întrerupere a liniei},
 			},
 			'm0' => {
 				'bgn' => q{transliterare BGN SUA},
 				'ungegn' => q{transliterare GEGN ONU},
 			},
 			'ms' => {
 				'metric' => q{sistemul metric},
 				'uksystem' => q{sistemul imperial de unități de măsură},
 				'ussystem' => q{sistemul american de unități de măsură},
 			},
 			'numbers' => {
 				'ahom' => q{cifre ahom},
 				'arab' => q{cifre indo-arabe},
 				'arabext' => q{cifre indo-arabe extinse},
 				'armn' => q{numerale armenești},
 				'armnlow' => q{numerale armenești cu minuscule},
 				'bali' => q{cifre balineze},
 				'beng' => q{cifre bengaleze},
 				'brah' => q{cifre brahmi},
 				'cakm' => q{cifre chakma},
 				'cham' => q{cifre cham},
 				'cyrl' => q{cifre chirilice},
 				'deva' => q{cifre devanagari},
 				'diak' => q{cifre dives akuru},
 				'ethi' => q{numerale etiopiene},
 				'finance' => q{Sistemul numeric financiar},
 				'fullwide' => q{cifre cu lățimea întreagă},
 				'geor' => q{numerale georgiene},
 				'gong' => q{cifre gunjala gondi},
 				'gonm' => q{cifre masaram gondi},
 				'grek' => q{numerale grecești},
 				'greklow' => q{numerale grecești cu minuscule},
 				'gujr' => q{cifre gujarati},
 				'guru' => q{cifre gurmukhi},
 				'hanidec' => q{numerale zecimale chinezești},
 				'hans' => q{numerale chinezești simplificate},
 				'hansfin' => q{numerale financiare chinezești simplificate},
 				'hant' => q{numerale chinezești tradiționale},
 				'hantfin' => q{numerale financiare chinezești tradiționale},
 				'hebr' => q{numerale ebraice},
 				'hmng' => q{cifre pahawh hmong},
 				'hmnp' => q{cifre nyiakeng puachue hmong},
 				'java' => q{cifre javaneze},
 				'jpan' => q{numerale japoneze},
 				'jpanfin' => q{numerale financiare japoneze},
 				'kali' => q{cifre kayah li},
 				'kawi' => q{cifre kawi},
 				'khmr' => q{cifre khmere},
 				'knda' => q{cifre kannada},
 				'lana' => q{cifre tai tham hora},
 				'lanatham' => q{cifre tai tham tham},
 				'laoo' => q{cifre laoțiene},
 				'latn' => q{cifre occidentale},
 				'lepc' => q{cifre lepcha},
 				'limb' => q{cifre limbu},
 				'mathbold' => q{cifre matematice aldine},
 				'mathdbl' => q{cifre matematice cu două linii},
 				'mathmono' => q{cifre matematice cu un singur spațiu},
 				'mathsanb' => q{cifre matematice aldine sans serif},
 				'mathsans' => q{cifre matematice sans serif},
 				'mlym' => q{cifre malayalam},
 				'modi' => q{cifre modi},
 				'mong' => q{Cifre mongole},
 				'mroo' => q{cifre mro},
 				'mtei' => q{cifre meetei mayek},
 				'mymr' => q{cifre birmaneze},
 				'mymrshan' => q{cifre birmaneze shan},
 				'mymrtlng' => q{cifre birmaneze tai laing},
 				'nagm' => q{cifre nag mundari},
 				'native' => q{cifre native},
 				'nkoo' => q{cifre n’ko},
 				'olck' => q{cifre ol chiki},
 				'orya' => q{cifre oriya},
 				'osma' => q{cifre osmanya},
 				'rohg' => q{cifre hanifi rohingya},
 				'roman' => q{numerale romane},
 				'romanlow' => q{numerale romane cu minuscule},
 				'saur' => q{cifre saurashtra},
 				'shrd' => q{cifre sharada},
 				'sind' => q{cifre khudawadi},
 				'sinh' => q{cifre sinhala lith},
 				'sora' => q{cifre sora sompeng},
 				'sund' => q{cifre sundaneze},
 				'takr' => q{cifre takri},
 				'talu' => q{cifre tai lue noi},
 				'taml' => q{numerale tradiționale tamile},
 				'tamldec' => q{cifre tamile},
 				'telu' => q{cifre telugu},
 				'thai' => q{cifre thailandeze},
 				'tibt' => q{cifre tibetane},
 				'tirh' => q{cifre tirhuta},
 				'tnsa' => q{cifre tangsa},
 				'traditional' => q{Numere tradiționale},
 				'vaii' => q{cifre vai},
 				'wara' => q{cifre warang citi},
 				'wcho' => q{cifre wancho},
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
			'metric' => q{metric},
 			'UK' => q{britanic},
 			'US' => q{american},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Limbă: {0}',
 			'script' => 'Scriere: {0}',
 			'region' => 'Regiune: {0}',

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
			auxiliary => qr{[áàåä ç éèêë ñ ö ş ţ ü]},
			index => ['A', 'Ă', 'Â', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ș', 'T', 'Ț', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a ă â b c d e f g h i î j k l m n o p q r s ș t ț u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘ "“”„ « » ( ) \[ \] @ * /]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Ă', 'Â', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ș', 'T', 'Ț', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{...},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punct cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punct cardinal),
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
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
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
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
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
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
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
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
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
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
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
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
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
						'1' => q(feminine),
						'few' => q({0} forță g),
						'one' => q({0} forță g),
						'other' => q({0} forță g),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'few' => q({0} forță g),
						'one' => q({0} forță g),
						'other' => q({0} forță g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'few' => q({0} metri pe secundă la pătrat),
						'name' => q(metri pe secundă la pătrat),
						'one' => q({0} metru pe secundă la pătrat),
						'other' => q({0} de metri pe secundă la pătrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'few' => q({0} metri pe secundă la pătrat),
						'name' => q(metri pe secundă la pătrat),
						'one' => q({0} metru pe secundă la pătrat),
						'other' => q({0} de metri pe secundă la pătrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(neuter),
						'few' => q({0} minute de arc),
						'name' => q(minute de arc),
						'one' => q({0} minut de arc),
						'other' => q({0} de minute de arc),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(neuter),
						'few' => q({0} minute de arc),
						'name' => q(minute de arc),
						'one' => q({0} minut de arc),
						'other' => q({0} de minute de arc),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'few' => q({0} secunde de arc),
						'name' => q(secunde de arc),
						'one' => q({0} secundă de arc),
						'other' => q({0} de secunde de arc),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'few' => q({0} secunde de arc),
						'name' => q(secunde de arc),
						'one' => q({0} secundă de arc),
						'other' => q({0} de secunde de arc),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(neuter),
						'few' => q({0} grade),
						'one' => q({0} grad),
						'other' => q({0} de grade),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(neuter),
						'few' => q({0} grade),
						'one' => q({0} grad),
						'other' => q({0} de grade),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'few' => q({0} radiani),
						'name' => q(radiani),
						'one' => q({0} radian),
						'other' => q({0} de radiani),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'few' => q({0} radiani),
						'name' => q(radiani),
						'one' => q({0} radian),
						'other' => q({0} de radiani),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'few' => q({0} revoluții),
						'name' => q(revoluție),
						'one' => q({0} revoluție),
						'other' => q({0} de revoluții),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'few' => q({0} revoluții),
						'name' => q(revoluție),
						'one' => q({0} revoluție),
						'other' => q({0} de revoluții),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} acri),
						'one' => q({0} acru),
						'other' => q({0} de acri),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} acri),
						'one' => q({0} acru),
						'other' => q({0} de acri),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunami),
						'one' => q({0} dunam),
						'other' => q({0} de dunami),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunami),
						'one' => q({0} dunam),
						'other' => q({0} de dunami),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(neuter),
						'few' => q({0} hectare),
						'name' => q(hectare),
						'one' => q({0} hectar),
						'other' => q({0} de hectare),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(neuter),
						'few' => q({0} hectare),
						'name' => q(hectare),
						'one' => q({0} hectar),
						'other' => q({0} de hectare),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri pătrați),
						'name' => q(centimetri pătrați),
						'one' => q({0} centimetru pătrat),
						'other' => q({0} de centimetri pătrați),
						'per' => q({0} pe centimetru pătrat),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri pătrați),
						'name' => q(centimetri pătrați),
						'one' => q({0} centimetru pătrat),
						'other' => q({0} de centimetri pătrați),
						'per' => q({0} pe centimetru pătrat),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} picioare pătrate),
						'name' => q(picioare pătrate),
						'one' => q({0} picior pătrat),
						'other' => q({0} de picioare pătrate),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} picioare pătrate),
						'name' => q(picioare pătrate),
						'one' => q({0} picior pătrat),
						'other' => q({0} de picioare pătrate),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} inchi pătrați),
						'name' => q(inchi pătrați),
						'one' => q({0} inch pătrat),
						'other' => q({0} de inchi pătrați),
						'per' => q({0} pe inchi pătrat),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} inchi pătrați),
						'name' => q(inchi pătrați),
						'one' => q({0} inch pătrat),
						'other' => q({0} de inchi pătrați),
						'per' => q({0} pe inchi pătrat),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri pătrați),
						'name' => q(kilometri pătrați),
						'one' => q({0} kilometru pătrat),
						'other' => q({0} de kilometri pătrați),
						'per' => q({0} pe kilometru pătrat),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri pătrați),
						'name' => q(kilometri pătrați),
						'one' => q({0} kilometru pătrat),
						'other' => q({0} de kilometri pătrați),
						'per' => q({0} pe kilometru pătrat),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'few' => q({0} metri pătrați),
						'name' => q(metri pătrați),
						'one' => q({0} metru pătrat),
						'other' => q({0} de metri pătrați),
						'per' => q({0} pe metru pătrat),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'few' => q({0} metri pătrați),
						'name' => q(metri pătrați),
						'one' => q({0} metru pătrat),
						'other' => q({0} de metri pătrați),
						'per' => q({0} pe metru pătrat),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mile pătrate),
						'name' => q(mile pătrate),
						'one' => q({0} milă pătrată),
						'other' => q({0} de mile pătrate),
						'per' => q({0} pe milă pătrată),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mile pătrate),
						'name' => q(mile pătrate),
						'one' => q({0} milă pătrată),
						'other' => q({0} de mile pătrate),
						'per' => q({0} pe milă pătrată),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} iarzi pătrați),
						'name' => q(iarzi pătrați),
						'one' => q({0} iard pătrat),
						'other' => q({0} de iarzi pătrați),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} iarzi pătrați),
						'name' => q(iarzi pătrați),
						'one' => q({0} iard pătrat),
						'other' => q({0} de iarzi pătrați),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'few' => q({0} itemi),
						'one' => q({0} de itemi),
						'other' => q({0} de itemi),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'few' => q({0} itemi),
						'one' => q({0} de itemi),
						'other' => q({0} de itemi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(neuter),
						'few' => q({0} carate),
						'name' => q(carate),
						'one' => q({0} carat),
						'other' => q({0} de carate),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(neuter),
						'few' => q({0} carate),
						'name' => q(carate),
						'one' => q({0} carat),
						'other' => q({0} de carate),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligrame pe decilitru),
						'name' => q(miligrame pe decilitru),
						'one' => q({0} miligram pe decilitru),
						'other' => q({0} de miligrame pe decilitru),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligrame pe decilitru),
						'name' => q(miligrame pe decilitru),
						'one' => q({0} miligram pe decilitru),
						'other' => q({0} de miligrame pe decilitru),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'few' => q({0} milimoli pe litru),
						'name' => q(milimoli pe litru),
						'one' => q({0} milimol pe litru),
						'other' => q({0} de milimoli pe litru),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'few' => q({0} milimoli pe litru),
						'name' => q(milimoli pe litru),
						'one' => q({0} milimol pe litru),
						'other' => q({0} de milimoli pe litru),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(masculine),
						'few' => q({0} moli),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} de moli),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(masculine),
						'few' => q({0} moli),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} de moli),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(neuter),
						'few' => q({0} procente),
						'name' => q(procent),
						'one' => q({0} procent),
						'other' => q({0} de procente),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(neuter),
						'few' => q({0} procente),
						'name' => q(procent),
						'one' => q({0} procent),
						'other' => q({0} de procente),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(feminine),
						'few' => q({0} promile),
						'name' => q(promilă),
						'one' => q({0} promilă),
						'other' => q({0} de promile),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(feminine),
						'few' => q({0} promile),
						'name' => q(promilă),
						'one' => q({0} promilă),
						'other' => q({0} de promile),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'few' => q({0} părți pe milion),
						'name' => q(părți pe milion),
						'one' => q({0} parte pe milion),
						'other' => q({0} de părți pe milion),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'few' => q({0} părți pe milion),
						'name' => q(părți pe milion),
						'one' => q({0} parte pe milion),
						'other' => q({0} de părți pe milion),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(feminine),
						'few' => q({0} la zece mii),
						'one' => q({0} la zece mii),
						'other' => q({0} la zece mii),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(feminine),
						'few' => q({0} la zece mii),
						'one' => q({0} la zece mii),
						'other' => q({0} la zece mii),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri la suta de kilometri),
						'name' => q(litri la suta de kilometri),
						'one' => q({0} litru la suta de kilometri),
						'other' => q({0} de litri la suta de kilometri),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri la suta de kilometri),
						'name' => q(litri la suta de kilometri),
						'one' => q({0} litru la suta de kilometri),
						'other' => q({0} de litri la suta de kilometri),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri pe kilometru),
						'name' => q(litri pe kilometru),
						'one' => q({0} litru pe kilometru),
						'other' => q({0} de litri pe kilometru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} litri pe kilometru),
						'name' => q(litri pe kilometru),
						'one' => q({0} litru pe kilometru),
						'other' => q({0} de litri pe kilometru),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mile pe galon),
						'name' => q(mile pe galon),
						'one' => q({0} milă pe galon),
						'other' => q({0} de mile pe galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mile pe galon),
						'name' => q(mile pe galon),
						'one' => q({0} milă pe galon),
						'other' => q({0} de mile pe galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mile pe galon imperial),
						'name' => q(mile pe galon imperial),
						'one' => q({0} milă pe galon imperial),
						'other' => q({0} de mile pe galon imperial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mile pe galon imperial),
						'name' => q(mile pe galon imperial),
						'one' => q({0} milă pe galon imperial),
						'other' => q({0} de mile pe galon imperial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'few' => q({0} biți),
						'name' => q(biți),
						'one' => q({0} bit),
						'other' => q({0} de biți),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'few' => q({0} biți),
						'name' => q(biți),
						'one' => q({0} bit),
						'other' => q({0} de biți),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
						'few' => q({0} byți),
						'name' => q(byți),
						'one' => q({0} byte),
						'other' => q({0} de byți),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
						'few' => q({0} byți),
						'name' => q(byți),
						'one' => q({0} byte),
						'other' => q({0} de byți),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
						'few' => q({0} gigabiți),
						'name' => q(gigabiți),
						'one' => q({0} gigabit),
						'other' => q({0} de gigabiți),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'few' => q({0} gigabiți),
						'name' => q(gigabiți),
						'one' => q({0} gigabit),
						'other' => q({0} de gigabiți),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'few' => q({0} gigabyți),
						'name' => q(gigabyți),
						'one' => q({0} gigabyte),
						'other' => q({0} de gigabyți),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'few' => q({0} gigabyți),
						'name' => q(gigabyți),
						'one' => q({0} gigabyte),
						'other' => q({0} de gigabyți),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'few' => q({0} kilobiți),
						'name' => q(kilobiți),
						'one' => q({0} kilobit),
						'other' => q({0} de kilobiți),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'few' => q({0} kilobiți),
						'name' => q(kilobiți),
						'one' => q({0} kilobit),
						'other' => q({0} de kilobiți),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
						'few' => q({0} kilobyți),
						'name' => q(kilobyți),
						'one' => q({0} kilobyte),
						'other' => q({0} de kilobyți),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
						'few' => q({0} kilobyți),
						'name' => q(kilobyți),
						'one' => q({0} kilobyte),
						'other' => q({0} de kilobyți),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'few' => q({0} megabiți),
						'name' => q(megabiți),
						'one' => q({0} megabit),
						'other' => q({0} de megabiți),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'few' => q({0} megabiți),
						'name' => q(megabiți),
						'one' => q({0} megabit),
						'other' => q({0} de megabiți),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'few' => q({0} megabyți),
						'name' => q(megabyți),
						'one' => q({0} megabyte),
						'other' => q({0} de megabyți),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'few' => q({0} megabyți),
						'name' => q(megabyți),
						'one' => q({0} megabyte),
						'other' => q({0} de megabyți),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(masculine),
						'few' => q({0} petabyți),
						'name' => q(petabyți),
						'one' => q({0} petabyte),
						'other' => q({0} de petabyți),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
						'few' => q({0} petabyți),
						'name' => q(petabyți),
						'one' => q({0} petabyte),
						'other' => q({0} de petabyți),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'few' => q({0} terabiți),
						'name' => q(terabiți),
						'one' => q({0} terabit),
						'other' => q({0} de terabiți),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
						'few' => q({0} terabiți),
						'name' => q(terabiți),
						'one' => q({0} terabit),
						'other' => q({0} de terabiți),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
						'few' => q({0} terabyți),
						'name' => q(terabyți),
						'one' => q({0} terabyte),
						'other' => q({0} de terabyți),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
						'few' => q({0} terabyți),
						'name' => q(terabyți),
						'one' => q({0} terabyte),
						'other' => q({0} de terabyți),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'few' => q({0} secole),
						'name' => q(secole),
						'one' => q({0} secol),
						'other' => q({0} de secole),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'few' => q({0} secole),
						'name' => q(secole),
						'one' => q({0} secol),
						'other' => q({0} de secole),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(feminine),
						'few' => q({0} zile),
						'one' => q({0} zi),
						'other' => q({0} de zile),
						'per' => q({0} pe zi),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(feminine),
						'few' => q({0} zile),
						'one' => q({0} zi),
						'other' => q({0} de zile),
						'per' => q({0} pe zi),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'few' => q({0} decenii),
						'name' => q(decenii),
						'one' => q({0} deceniu),
						'other' => q({0} de decenii),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'few' => q({0} decenii),
						'name' => q(decenii),
						'one' => q({0} deceniu),
						'other' => q({0} de decenii),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'few' => q({0} ore),
						'one' => q({0} oră),
						'other' => q({0} de ore),
						'per' => q({0} pe oră),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'few' => q({0} ore),
						'one' => q({0} oră),
						'other' => q({0} de ore),
						'per' => q({0} pe oră),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'few' => q({0} microsecunde),
						'name' => q(microsecunde),
						'one' => q({0} microsecundă),
						'other' => q({0} de microsecunde),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'few' => q({0} microsecunde),
						'name' => q(microsecunde),
						'one' => q({0} microsecundă),
						'other' => q({0} de microsecunde),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisecunde),
						'name' => q(milisecunde),
						'one' => q({0} milisecundă),
						'other' => q({0} de milisecunde),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisecunde),
						'name' => q(milisecunde),
						'one' => q({0} milisecundă),
						'other' => q({0} de milisecunde),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(neuter),
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minut),
						'other' => q({0} de minute),
						'per' => q({0} pe minut),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(neuter),
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minut),
						'other' => q({0} de minute),
						'per' => q({0} pe minut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(feminine),
						'few' => q({0} luni),
						'one' => q({0} lună),
						'other' => q({0} de luni),
						'per' => q({0} pe lună),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(feminine),
						'few' => q({0} luni),
						'one' => q({0} lună),
						'other' => q({0} de luni),
						'per' => q({0} pe lună),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosecunde),
						'name' => q(nanosecunde),
						'one' => q({0} nanosecundă),
						'other' => q({0} de nanosecunde),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosecunde),
						'name' => q(nanosecunde),
						'one' => q({0} nanosecundă),
						'other' => q({0} de nanosecunde),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'few' => q({0} trimestre),
						'name' => q(trimestre),
						'one' => q({0} trimestru),
						'other' => q({0} de trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'few' => q({0} trimestre),
						'name' => q(trimestre),
						'one' => q({0} trimestru),
						'other' => q({0} de trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'few' => q({0} secunde),
						'name' => q(secunde),
						'one' => q({0} secundă),
						'other' => q({0} de secunde),
						'per' => q({0} pe secundă),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'few' => q({0} secunde),
						'name' => q(secunde),
						'one' => q({0} secundă),
						'other' => q({0} de secunde),
						'per' => q({0} pe secundă),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'few' => q({0} săptămâni),
						'one' => q({0} săptămână),
						'other' => q({0} de săptămâni),
						'per' => q({0} pe săptămână),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'few' => q({0} săptămâni),
						'one' => q({0} săptămână),
						'other' => q({0} de săptămâni),
						'per' => q({0} pe săptămână),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'few' => q({0} ani),
						'one' => q({0} an),
						'other' => q({0} de ani),
						'per' => q({0} pe an),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'few' => q({0} ani),
						'one' => q({0} an),
						'other' => q({0} de ani),
						'per' => q({0} pe an),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'few' => q({0} amperi),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} de amperi),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'few' => q({0} amperi),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} de amperi),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'few' => q({0} miliamperi),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} de miliamperi),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'few' => q({0} miliamperi),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} de miliamperi),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'few' => q({0} ohmi),
						'name' => q(ohmi),
						'one' => q({0} ohm),
						'other' => q({0} de ohmi),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'few' => q({0} ohmi),
						'name' => q(ohmi),
						'one' => q({0} ohm),
						'other' => q({0} de ohmi),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'few' => q({0} volți),
						'name' => q(volți),
						'one' => q({0} volt),
						'other' => q({0} de volți),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'few' => q({0} volți),
						'name' => q(volți),
						'one' => q({0} volt),
						'other' => q({0} de volți),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} unități termice britanice),
						'name' => q(unități termice britanice),
						'one' => q({0} unitate termică britanică),
						'other' => q({0} de unități termice britanice),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} unități termice britanice),
						'name' => q(unități termice britanice),
						'one' => q({0} unitate termică britanică),
						'other' => q({0} de unități termice britanice),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'few' => q({0} calorii),
						'name' => q(calorii),
						'one' => q({0} calorie),
						'other' => q({0} de calorii),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'few' => q({0} calorii),
						'name' => q(calorii),
						'one' => q({0} calorie),
						'other' => q({0} de calorii),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} electronvolți),
						'name' => q(electronvolți),
						'one' => q({0} electronvolt),
						'other' => q({0} de electronvolți),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} electronvolți),
						'name' => q(electronvolți),
						'one' => q({0} electronvolt),
						'other' => q({0} de electronvolți),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kilocalorii),
						'name' => q(kilocalorii),
						'one' => q({0} kilocalorie),
						'other' => q({0} de kilocalorii),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kilocalorii),
						'name' => q(kilocalorii),
						'one' => q({0} kilocalorie),
						'other' => q({0} de kilocalorii),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'few' => q({0} jouli),
						'name' => q(jouli),
						'one' => q({0} joule),
						'other' => q({0} de jouli),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'few' => q({0} jouli),
						'name' => q(jouli),
						'one' => q({0} joule),
						'other' => q({0} de jouli),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilocalorii),
						'name' => q(kilocalorii),
						'one' => q({0} kilocalorie),
						'other' => q({0} de kilocalorii),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilocalorii),
						'name' => q(kilocalorii),
						'one' => q({0} kilocalorie),
						'other' => q({0} de kilocalorii),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'few' => q({0} kilojouli),
						'name' => q(kilojouli),
						'one' => q({0} kilojoule),
						'other' => q({0} de kilojouli),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'few' => q({0} kilojouli),
						'name' => q(kilojouli),
						'one' => q({0} kilojoule),
						'other' => q({0} de kilojouli),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(masculine),
						'few' => q({0} kilowați-oră),
						'name' => q(kilowați-oră),
						'one' => q(kilowatt-oră),
						'other' => q({0} de kilowați-oră),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'few' => q({0} kilowați-oră),
						'name' => q(kilowați-oră),
						'one' => q(kilowatt-oră),
						'other' => q({0} de kilowați-oră),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} thermi S.U.A.),
						'name' => q(thermi S.U.A.),
						'one' => q({0} therm S.U.A.),
						'other' => q({0} de thermi S.U.A.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} thermi S.U.A.),
						'name' => q(thermi S.U.A.),
						'one' => q({0} therm S.U.A.),
						'other' => q({0} de thermi S.U.A.),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilowați-oră per 100 kilometri),
						'name' => q(kilowatt-oră per 100 kilometri),
						'one' => q({0} kilowatt-oră per 100 kilometri),
						'other' => q({0} kilowați-oră per 100 kilometri),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilowați-oră per 100 kilometri),
						'name' => q(kilowatt-oră per 100 kilometri),
						'one' => q({0} kilowatt-oră per 100 kilometri),
						'other' => q({0} kilowați-oră per 100 kilometri),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'few' => q({0} newtoni),
						'name' => q(newtoni),
						'one' => q({0} newton),
						'other' => q({0} de newtoni),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'few' => q({0} newtoni),
						'name' => q(newtoni),
						'one' => q({0} newton),
						'other' => q({0} de newtoni),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} livre-forță),
						'name' => q(livre-forță),
						'one' => q({0} livră-forță),
						'other' => q({0} de livre-forță),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} livre-forță),
						'name' => q(livre-forță),
						'one' => q({0} livră-forță),
						'other' => q({0} de livre-forță),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'few' => q({0} gigahertzi),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} de gigahertzi),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'few' => q({0} gigahertzi),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} de gigahertzi),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'few' => q({0} hertzi),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} de hertzi),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'few' => q({0} hertzi),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} de hertzi),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'few' => q({0} kilohertzi),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} de kilohertzi),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'few' => q({0} kilohertzi),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} de kilohertzi),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'few' => q({0} megahertzi),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} de megahertzi),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'few' => q({0} megahertzi),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} de megahertzi),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} puncte),
						'name' => q(puncte tipografice),
						'one' => q({0} punct),
						'other' => q({0} de puncte),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} puncte),
						'name' => q(puncte tipografice),
						'one' => q({0} punct),
						'other' => q({0} de puncte),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} puncte pe centimetru),
						'name' => q(puncte pe centimetru),
						'one' => q({0} punct pe centimetru),
						'other' => q({0} de puncte pe centimetru),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} puncte pe centimetru),
						'name' => q(puncte pe centimetru),
						'one' => q({0} punct pe centimetru),
						'other' => q({0} de puncte pe centimetru),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} puncte pe inch),
						'name' => q(puncte pe inch),
						'one' => q({0} punct pe inch),
						'other' => q({0} de puncte pe inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} puncte pe inch),
						'name' => q(puncte pe inch),
						'one' => q({0} punct pe inch),
						'other' => q({0} de puncte pe inch),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'name' => q(em tipografic),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'name' => q(em tipografic),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'few' => q({0} megapixeli),
						'one' => q({0} megapixel),
						'other' => q({0} de megapixeli),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'few' => q({0} megapixeli),
						'one' => q({0} megapixel),
						'other' => q({0} de megapixeli),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'few' => q({0} pixeli),
						'one' => q({0} pixel),
						'other' => q({0} de pixeli),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'few' => q({0} pixeli),
						'one' => q({0} pixel),
						'other' => q({0} de pixeli),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} pixeli pe centimetru),
						'name' => q(pixeli pe centimetru),
						'one' => q({0} pixel pe centimetru),
						'other' => q({0} de pixeli pe centimetru),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} pixeli pe centimetru),
						'name' => q(pixeli pe centimetru),
						'one' => q({0} pixel pe centimetru),
						'other' => q({0} de pixeli pe centimetru),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} pixeli pe inch),
						'name' => q(pixeli pe inch),
						'one' => q({0} pixel pe inch),
						'other' => q({0} de pixeli pe inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} pixeli pe inch),
						'name' => q(pixeli pe inch),
						'one' => q({0} pixel pe inch),
						'other' => q({0} de pixeli pe inch),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} unități astronomice),
						'name' => q(unități astronomice),
						'one' => q({0} unitate astronomică),
						'other' => q({0} de unități astronomice),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} unități astronomice),
						'name' => q(unități astronomice),
						'one' => q({0} unitate astronomică),
						'other' => q({0} de unități astronomice),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri),
						'name' => q(centimetri),
						'one' => q({0} centimetru),
						'other' => q({0} de centimetri),
						'per' => q({0} pe centimetru),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri),
						'name' => q(centimetri),
						'one' => q({0} centimetru),
						'other' => q({0} de centimetri),
						'per' => q({0} pe centimetru),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'few' => q({0} decimetri),
						'name' => q(decimetri),
						'one' => q({0} decimetru),
						'other' => q({0} de decimetri),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'few' => q({0} decimetri),
						'name' => q(decimetri),
						'one' => q({0} decimetru),
						'other' => q({0} de decimetri),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} raze terestre),
						'name' => q(rază terestră),
						'one' => q({0} rază terestră),
						'other' => q({0} de raze terestre),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} raze terestre),
						'name' => q(rază terestră),
						'one' => q({0} rază terestră),
						'other' => q({0} de raze terestre),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} fathomi),
						'one' => q({0} fathom),
						'other' => q({0} de fathomi),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} fathomi),
						'one' => q({0} fathom),
						'other' => q({0} de fathomi),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} picioare),
						'name' => q(picioare),
						'one' => q({0} picior),
						'other' => q({0} de picioare),
						'per' => q({0} pe picior),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} picioare),
						'name' => q(picioare),
						'one' => q({0} picior),
						'other' => q({0} de picioare),
						'per' => q({0} pe picior),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlongi),
						'one' => q({0} furlong),
						'other' => q({0} de furlongi),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlongi),
						'one' => q({0} furlong),
						'other' => q({0} de furlongi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} inchi),
						'name' => q(inchi),
						'one' => q({0} inch),
						'other' => q({0} de inchi),
						'per' => q({0} pe inch),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} inchi),
						'name' => q(inchi),
						'one' => q({0} inch),
						'other' => q({0} de inchi),
						'per' => q({0} pe inch),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri),
						'name' => q(kilometri),
						'one' => q({0} kilometru),
						'other' => q({0} de kilometri),
						'per' => q({0} pe kilometru),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri),
						'name' => q(kilometri),
						'one' => q({0} kilometru),
						'other' => q({0} de kilometri),
						'per' => q({0} pe kilometru),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} ani lumină),
						'name' => q(ani lumină),
						'one' => q({0} an lumină),
						'other' => q({0} de ani lumină),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} ani lumină),
						'name' => q(ani lumină),
						'one' => q({0} an lumină),
						'other' => q({0} de ani lumină),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'few' => q({0} metri),
						'one' => q({0} metru),
						'other' => q({0} de metri),
						'per' => q({0} pe metru),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'few' => q({0} metri),
						'one' => q({0} metru),
						'other' => q({0} de metri),
						'per' => q({0} pe metru),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'few' => q({0} micrometri),
						'name' => q(micrometri),
						'one' => q({0} micrometru),
						'other' => q({0} de micrometri),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'few' => q({0} micrometri),
						'name' => q(micrometri),
						'one' => q({0} micrometru),
						'other' => q({0} de micrometri),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} milă),
						'other' => q({0} de mile),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} milă),
						'other' => q({0} de mile),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} mile scandinave),
						'name' => q(milă scandinavă),
						'one' => q({0} milă scandinavă),
						'other' => q({0} de mile scandinave),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} mile scandinave),
						'name' => q(milă scandinavă),
						'one' => q({0} milă scandinavă),
						'other' => q({0} de mile scandinave),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'few' => q({0} milimetri),
						'name' => q(milimetri),
						'one' => q({0} milimetru),
						'other' => q({0} de milimetri),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'few' => q({0} milimetri),
						'name' => q(milimetri),
						'one' => q({0} milimetru),
						'other' => q({0} de milimetri),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'few' => q({0} nanometri),
						'name' => q(nanometri),
						'one' => q({0} nanometru),
						'other' => q({0} de nanometri),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'few' => q({0} nanometri),
						'name' => q(nanometri),
						'one' => q({0} nanometru),
						'other' => q({0} de nanometri),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} mile nautice),
						'name' => q(mile nautice),
						'one' => q({0} milă nautică),
						'other' => q({0} de mile nautice),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} mile nautice),
						'name' => q(mile nautice),
						'one' => q({0} milă nautică),
						'other' => q({0} de mile nautice),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parseci),
						'name' => q(parseci),
						'one' => q({0} parsec),
						'other' => q({0} de parseci),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parseci),
						'name' => q(parseci),
						'one' => q({0} parsec),
						'other' => q({0} de parseci),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'few' => q({0} picometri),
						'name' => q(picometri),
						'one' => q({0} picometru),
						'other' => q({0} de picometri),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'few' => q({0} picometri),
						'name' => q(picometri),
						'one' => q({0} picometru),
						'other' => q({0} de picometri),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} puncte tipografice),
						'name' => q(puncte),
						'one' => q({0} punct tipografic),
						'other' => q({0} de puncte tipografice),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} puncte tipografice),
						'name' => q(puncte),
						'one' => q({0} punct tipografic),
						'other' => q({0} de puncte tipografice),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} raze solare),
						'name' => q(raze solare),
						'one' => q({0} rază solară),
						'other' => q({0} de raze solare),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} raze solare),
						'name' => q(raze solare),
						'one' => q({0} rază solară),
						'other' => q({0} de raze solare),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} iarzi),
						'name' => q(iarzi),
						'one' => q({0} iard),
						'other' => q({0} de iarzi),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} iarzi),
						'name' => q(iarzi),
						'one' => q({0} iard),
						'other' => q({0} de iarzi),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'few' => q({0} candele),
						'name' => q(candelă),
						'one' => q({0} candelă),
						'other' => q({0} de candele),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'few' => q({0} candele),
						'name' => q(candelă),
						'one' => q({0} candelă),
						'other' => q({0} de candele),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'few' => q({0} lumeni),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} de lumeni),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'few' => q({0} lumeni),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} de lumeni),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'few' => q({0} lucși),
						'name' => q(lucși),
						'one' => q({0} lux),
						'other' => q({0} de lucși),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'few' => q({0} lucși),
						'name' => q(lucși),
						'one' => q({0} lux),
						'other' => q({0} de lucși),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} luminozități solare),
						'name' => q(luminozități solare),
						'one' => q({0} luminozitate solară),
						'other' => q({0} de luminozități solare),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} luminozități solare),
						'name' => q(luminozități solare),
						'one' => q({0} luminozitate solară),
						'other' => q({0} de luminozități solare),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(neuter),
						'few' => q({0} carate),
						'one' => q({0} carat),
						'other' => q({0} de carate),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(neuter),
						'few' => q({0} carate),
						'one' => q({0} carat),
						'other' => q({0} de carate),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltoni),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} de daltoni),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltoni),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} de daltoni),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} mase terestre),
						'name' => q(mase terestre),
						'one' => q({0} masă terestră),
						'other' => q({0} de mase terestre),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} mase terestre),
						'name' => q(mase terestre),
						'one' => q({0} masă terestră),
						'other' => q({0} de mase terestre),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} boabe),
						'one' => q({0} boabă),
						'other' => q({0} de boabe),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} boabe),
						'one' => q({0} boabă),
						'other' => q({0} de boabe),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(neuter),
						'few' => q({0} grame),
						'one' => q({0} gram),
						'other' => q({0} de grame),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'few' => q({0} grame),
						'one' => q({0} gram),
						'other' => q({0} de grame),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(neuter),
						'few' => q({0} kilograme),
						'name' => q(kilograme),
						'one' => q({0} kilogram),
						'other' => q({0} de kilograme),
						'per' => q({0} per kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(neuter),
						'few' => q({0} kilograme),
						'name' => q(kilograme),
						'one' => q({0} kilogram),
						'other' => q({0} de kilograme),
						'per' => q({0} per kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(neuter),
						'few' => q({0} micrograme),
						'name' => q(micrograme),
						'one' => q({0} microgram),
						'other' => q({0} de micrograme),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(neuter),
						'few' => q({0} micrograme),
						'name' => q(micrograme),
						'one' => q({0} microgram),
						'other' => q({0} de micrograme),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(neuter),
						'few' => q({0} miligrame),
						'name' => q(miligrame),
						'one' => q({0} miligram),
						'other' => q({0} de miligrame),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(neuter),
						'few' => q({0} miligrame),
						'name' => q(miligrame),
						'one' => q({0} miligram),
						'other' => q({0} de miligrame),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} uncii),
						'name' => q(uncii),
						'one' => q({0} uncie),
						'other' => q({0} de uncii),
						'per' => q({0} per uncie),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} uncii),
						'name' => q(uncii),
						'one' => q({0} uncie),
						'other' => q({0} de uncii),
						'per' => q({0} per uncie),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} uncii monetare),
						'name' => q(uncii monetare),
						'one' => q({0} uncie monetară),
						'other' => q({0} de uncii monetare),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} uncii monetare),
						'name' => q(uncii monetare),
						'one' => q({0} uncie monetară),
						'other' => q({0} de uncii monetare),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} livre),
						'name' => q(livre),
						'one' => q({0} livră),
						'other' => q({0} de livre),
						'per' => q({0} per livră),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} livre),
						'name' => q(livre),
						'one' => q({0} livră),
						'other' => q({0} de livre),
						'per' => q({0} per livră),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} mase solare),
						'name' => q(mase solare),
						'one' => q({0} masă solară),
						'other' => q({0} de mase solare),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} mase solare),
						'name' => q(mase solare),
						'one' => q({0} masă solară),
						'other' => q({0} de mase solare),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} stone),
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} de stone),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} stone),
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} de stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} tone scurte),
						'name' => q(tone scurte),
						'one' => q({0} tonă scurtă),
						'other' => q({0} de tone scurte),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} tone scurte),
						'name' => q(tone scurte),
						'one' => q({0} tonă scurtă),
						'other' => q({0} de tone scurte),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'few' => q({0} tone metrice),
						'name' => q(tone metrice),
						'one' => q({0} tonă metrică),
						'other' => q({0} de tone metrice),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'few' => q({0} tone metrice),
						'name' => q(tone metrice),
						'one' => q({0} tonă metrică),
						'other' => q({0} de tone metrice),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pe {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pe {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(masculine),
						'few' => q({0} gigawați),
						'name' => q(gigawați),
						'one' => q({0} gigawatt),
						'other' => q({0} de gigawați),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'few' => q({0} gigawați),
						'name' => q(gigawați),
						'one' => q({0} gigawatt),
						'other' => q({0} de gigawați),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} cai putere),
						'name' => q(cai putere),
						'one' => q({0} cal putere),
						'other' => q({0} de cai putere),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} cai putere),
						'name' => q(cai putere),
						'one' => q({0} cal putere),
						'other' => q({0} de cai putere),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'few' => q({0} kilowați),
						'name' => q(kilowați),
						'one' => q({0} kilowatt),
						'other' => q({0} de kilowați),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'few' => q({0} kilowați),
						'name' => q(kilowați),
						'one' => q({0} kilowatt),
						'other' => q({0} de kilowați),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'few' => q({0} megawați),
						'name' => q(megawați),
						'one' => q({0} megawatt),
						'other' => q({0} de megawați),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'few' => q({0} megawați),
						'name' => q(megawați),
						'one' => q({0} megawatt),
						'other' => q({0} de megawați),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
						'few' => q({0} miliwați),
						'name' => q(miliwați),
						'one' => q({0} miliwatt),
						'other' => q({0} de miliwați),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'few' => q({0} miliwați),
						'name' => q(miliwați),
						'one' => q({0} miliwatt),
						'other' => q({0} de miliwați),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'few' => q({0} wați),
						'name' => q(wați),
						'one' => q({0} watt),
						'other' => q({0} de wați),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'few' => q({0} wați),
						'name' => q(wați),
						'one' => q({0} watt),
						'other' => q({0} de wați),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q({0} pătrate),
						'one' => q({0} pătrat),
						'other' => q({0} pătrate),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q({0} pătrate),
						'one' => q({0} pătrat),
						'other' => q({0} pătrate),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q({0} cubice),
						'one' => q({0} cub),
						'other' => q({0} cubice),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q({0} cubice),
						'one' => q({0} cub),
						'other' => q({0} cubice),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosferă),
						'other' => q({0} de atmosfere),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosferă),
						'other' => q({0} de atmosfere),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
						'few' => q({0} bari),
						'name' => q(bari),
						'one' => q({0} bar),
						'other' => q({0} de bari),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
						'few' => q({0} bari),
						'name' => q(bari),
						'one' => q({0} bar),
						'other' => q({0} de bari),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(masculine),
						'few' => q({0} hectopascali),
						'name' => q(hectopascali),
						'one' => q({0} hectopascal),
						'other' => q({0} de hectopascali),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'few' => q({0} hectopascali),
						'name' => q(hectopascali),
						'one' => q({0} hectopascal),
						'other' => q({0} de hectopascali),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inchi coloană de mercur),
						'name' => q(inchi coloană de mercur),
						'one' => q({0} inch coloană de mercur),
						'other' => q({0} de inchi coloană de mercur),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inchi coloană de mercur),
						'name' => q(inchi coloană de mercur),
						'one' => q({0} inch coloană de mercur),
						'other' => q({0} de inchi coloană de mercur),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'few' => q({0} kilopascali),
						'name' => q(kilopascali),
						'one' => q({0} kilopascal),
						'other' => q({0} de kilopascali),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'few' => q({0} kilopascali),
						'name' => q(kilopascali),
						'one' => q({0} kilopascal),
						'other' => q({0} de kilopascali),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'few' => q({0} megapascali),
						'name' => q(megapascali),
						'one' => q({0} megapascal),
						'other' => q({0} de megapascali),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'few' => q({0} megapascali),
						'name' => q(megapascali),
						'one' => q({0} megapascal),
						'other' => q({0} de megapascali),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'few' => q({0} milibari),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} de milibari),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'few' => q({0} milibari),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} de milibari),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetri coloană de mercur),
						'name' => q(milimetri coloană de mercur),
						'one' => q({0} milimetru coloană de mercur),
						'other' => q({0} de milimetri coloană de mercur),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetri coloană de mercur),
						'name' => q(milimetri coloană de mercur),
						'one' => q({0} milimetru coloană de mercur),
						'other' => q({0} de milimetri coloană de mercur),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'few' => q({0} pascali),
						'name' => q(pascali),
						'one' => q({0} pascal),
						'other' => q({0} de pascali),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'few' => q({0} pascali),
						'name' => q(pascali),
						'one' => q({0} pascal),
						'other' => q({0} de pascali),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} livre pe inch pătrat),
						'name' => q(livre pe inch pătrat),
						'one' => q({0} livră pe inch pătrat),
						'other' => q({0} de livre pe inch pătrat),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} livre pe inch pătrat),
						'name' => q(livre pe inch pătrat),
						'one' => q({0} livră pe inch pătrat),
						'other' => q({0} de livre pe inch pătrat),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(Beaufort {0}),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(Beaufort {0}),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'few' => q({0} kilometri pe oră),
						'name' => q(kilometri pe oră),
						'one' => q({0} kilometru pe oră),
						'other' => q({0} de kilometri pe oră),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'few' => q({0} kilometri pe oră),
						'name' => q(kilometri pe oră),
						'one' => q({0} kilometru pe oră),
						'other' => q({0} de kilometri pe oră),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} noduri),
						'name' => q(nod),
						'one' => q({0} nod),
						'other' => q({0} de noduri),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} noduri),
						'name' => q(nod),
						'one' => q({0} nod),
						'other' => q({0} de noduri),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'few' => q({0} metri pe secundă),
						'name' => q(metri pe secundă),
						'one' => q({0} metru pe secundă),
						'other' => q({0} de metri pe secundă),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'few' => q({0} metri pe secundă),
						'name' => q(metri pe secundă),
						'one' => q({0} metru pe secundă),
						'other' => q({0} de metri pe secundă),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mile pe oră),
						'name' => q(mile pe oră),
						'one' => q({0} milă pe oră),
						'other' => q({0} de mile pe oră),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mile pe oră),
						'name' => q(mile pe oră),
						'one' => q({0} milă pe oră),
						'other' => q({0} de mile pe oră),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(neuter),
						'few' => q({0} grade Celsius),
						'name' => q(grade Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} de grade Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(neuter),
						'few' => q({0} grade Celsius),
						'name' => q(grade Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} de grade Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} grade Fahrenheit),
						'name' => q(grade Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} de grade Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} grade Fahrenheit),
						'name' => q(grade Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} de grade Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(neuter),
						'few' => q({0} grade),
						'one' => q({0} grad),
						'other' => q({0} de grade),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(neuter),
						'few' => q({0} grade),
						'one' => q({0} grad),
						'other' => q({0} de grade),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'few' => q({0} kelvini),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} de kelvini),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'few' => q({0} kelvini),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} de kelvini),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'few' => q({0} newton metri),
						'name' => q(newton-metri),
						'one' => q({0} newton metru),
						'other' => q({0} de newton metri),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'few' => q({0} newton metri),
						'name' => q(newton-metri),
						'one' => q({0} newton metru),
						'other' => q({0} de newton metri),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} livră-forță picioare),
						'name' => q(livră-forță picioare),
						'one' => q({0} livră-forță picior),
						'other' => q({0} de livră-forță picioare),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} livră-forță picioare),
						'name' => q(livră-forță picioare),
						'one' => q({0} livră-forță picior),
						'other' => q({0} de livră-forță picioare),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} acru-picioare),
						'name' => q(acru-picioare),
						'one' => q({0} acru-picior),
						'other' => q({0} de acru-picioare),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} acru-picioare),
						'name' => q(acru-picioare),
						'one' => q({0} acru-picior),
						'other' => q({0} de acru-picioare),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barili),
						'name' => q(barili),
						'one' => q({0} baril),
						'other' => q({0} de barili),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barili),
						'name' => q(barili),
						'one' => q({0} baril),
						'other' => q({0} de barili),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} banițe),
						'one' => q({0} baniță),
						'other' => q({0} de banițe),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} banițe),
						'one' => q({0} baniță),
						'other' => q({0} de banițe),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'few' => q({0} centilitri),
						'name' => q(centilitri),
						'one' => q({0} centilitru),
						'other' => q({0} de centilitri),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'few' => q({0} centilitri),
						'name' => q(centilitri),
						'one' => q({0} centilitru),
						'other' => q({0} de centilitri),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri cubi),
						'name' => q(centimetri cubi),
						'one' => q({0} centimetru cub),
						'other' => q({0} de centimetri cubi),
						'per' => q({0} pe centimetru cub),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} centimetri cubi),
						'name' => q(centimetri cubi),
						'one' => q({0} centimetru cub),
						'other' => q({0} de centimetri cubi),
						'per' => q({0} pe centimetru cub),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} picioare cubice),
						'name' => q(picioare cubice),
						'one' => q({0} picior cubic),
						'other' => q({0} de picioare cubice),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} picioare cubice),
						'name' => q(picioare cubice),
						'one' => q({0} picior cubic),
						'other' => q({0} de picioare cubice),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} inchi cubici),
						'name' => q(inchi cubici),
						'one' => q({0} inch cubic),
						'other' => q({0} de inchi cubici),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} inchi cubici),
						'name' => q(inchi cubici),
						'one' => q({0} inch cubic),
						'other' => q({0} de inchi cubici),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri cubi),
						'name' => q(kilometri cubi),
						'one' => q({0} kilometru cub),
						'other' => q({0} de kilometri cubi),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} kilometri cubi),
						'name' => q(kilometri cubi),
						'one' => q({0} kilometru cub),
						'other' => q({0} de kilometri cubi),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'few' => q({0} metri cubi),
						'name' => q(metri cubi),
						'one' => q({0} metru cub),
						'other' => q({0} de metri cubi),
						'per' => q({0} pe metru cub),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'few' => q({0} metri cubi),
						'name' => q(metri cubi),
						'one' => q({0} metru cub),
						'other' => q({0} de metri cubi),
						'per' => q({0} pe metru cub),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mile cubice),
						'name' => q(mile cubice),
						'one' => q({0} milă cubică),
						'other' => q({0} de mile cubice),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mile cubice),
						'name' => q(mile cubice),
						'one' => q({0} milă cubică),
						'other' => q({0} de mile cubice),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} iarzi cubici),
						'name' => q(iarzi cubici),
						'one' => q({0} iard cubic),
						'other' => q({0} de iarzi cubici),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} iarzi cubici),
						'name' => q(iarzi cubici),
						'one' => q({0} iard cubic),
						'other' => q({0} de iarzi cubici),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} căni),
						'one' => q({0} cană),
						'other' => q({0} de căni),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} căni),
						'one' => q({0} cană),
						'other' => q({0} de căni),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'few' => q({0} căni metrice),
						'name' => q(căni metrice),
						'one' => q({0} cană metrică),
						'other' => q({0} de căni metrice),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'few' => q({0} căni metrice),
						'name' => q(căni metrice),
						'one' => q({0} cană metrică),
						'other' => q({0} de căni metrice),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'few' => q({0} decilitri),
						'name' => q(decilitri),
						'one' => q({0} decilitru),
						'other' => q({0} de decilitri),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'few' => q({0} decilitri),
						'name' => q(decilitri),
						'one' => q({0} decilitru),
						'other' => q({0} de decilitri),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} linguri de desert),
						'name' => q(lingură de desert),
						'one' => q({0} lingură de desert),
						'other' => q({0} de linguri de desert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} linguri de desert),
						'name' => q(lingură de desert),
						'one' => q({0} lingură de desert),
						'other' => q({0} de linguri de desert),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} linguri de desert imperiale),
						'name' => q(lingură de desert imperială),
						'one' => q({0} lingură de desert imperială),
						'other' => q({0} de linguri de desert imperiale),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} linguri de desert imperiale),
						'name' => q(lingură de desert imperială),
						'one' => q({0} lingură de desert imperială),
						'other' => q({0} de linguri de desert imperiale),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} drami lichizi),
						'one' => q({0} dram lichid),
						'other' => q({0} de drami lichizi),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} drami lichizi),
						'one' => q({0} dram lichid),
						'other' => q({0} de drami lichizi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} uncii lichide),
						'name' => q(uncii lichide),
						'one' => q({0} uncie lichidă),
						'other' => q({0} de uncii lichide),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} uncii lichide),
						'name' => q(uncii lichide),
						'one' => q({0} uncie lichidă),
						'other' => q({0} de uncii lichide),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} uncii lichide imperiale),
						'name' => q(uncii lichide imperiale),
						'one' => q({0} uncie lichidă imperială),
						'other' => q({0} de uncii lichide imperiale),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} uncii lichide imperiale),
						'name' => q(uncii lichide imperiale),
						'one' => q({0} uncie lichidă imperială),
						'other' => q({0} de uncii lichide imperiale),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galoane),
						'name' => q(galoane),
						'one' => q({0} galon),
						'other' => q({0} de galoane),
						'per' => q({0} per galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galoane),
						'name' => q(galoane),
						'one' => q({0} galon),
						'other' => q({0} de galoane),
						'per' => q({0} per galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} galoane imperiale),
						'name' => q(galoane imperiale),
						'one' => q({0} galon imperial),
						'other' => q({0} de galoane imperiale),
						'per' => q({0} pe galon imperial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} galoane imperiale),
						'name' => q(galoane imperiale),
						'one' => q({0} galon imperial),
						'other' => q({0} de galoane imperiale),
						'per' => q({0} pe galon imperial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'few' => q({0} hectolitri),
						'name' => q(hectolitri),
						'one' => q({0} hectolitru),
						'other' => q({0} de hectolitri),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'few' => q({0} hectolitri),
						'name' => q(hectolitri),
						'one' => q({0} hectolitru),
						'other' => q({0} de hectolitri),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} jiggere),
						'one' => q({0} jigger),
						'other' => q({0} de jiggere),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} jiggere),
						'one' => q({0} jigger),
						'other' => q({0} de jiggere),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'few' => q({0} litri),
						'one' => q({0} litru),
						'other' => q({0} de litri),
						'per' => q({0} pe litru),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'few' => q({0} litri),
						'one' => q({0} litru),
						'other' => q({0} de litri),
						'per' => q({0} pe litru),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'few' => q({0} megalitri),
						'name' => q(megalitri),
						'one' => q({0} megalitru),
						'other' => q({0} de megalitri),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'few' => q({0} megalitri),
						'name' => q(megalitri),
						'one' => q({0} megalitru),
						'other' => q({0} de megalitri),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'few' => q({0} mililitri),
						'name' => q(mililitri),
						'one' => q({0} mililitru),
						'other' => q({0} de mililitri),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'few' => q({0} mililitri),
						'name' => q(mililitri),
						'one' => q({0} mililitru),
						'other' => q({0} de mililitri),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} vârfuri de cuțit),
						'name' => q(vârf de cuțit),
						'one' => q({0} vârf de cuțit),
						'other' => q({0} de vârfuri de cuțit),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} vârfuri de cuțit),
						'name' => q(vârf de cuțit),
						'one' => q({0} vârf de cuțit),
						'other' => q({0} de vârfuri de cuțit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinte),
						'one' => q({0} pintă),
						'other' => q({0} de pinte),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinte),
						'one' => q({0} pintă),
						'other' => q({0} de pinte),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} pinte metrice),
						'name' => q(pinte metrice),
						'one' => q({0} pintă metrică),
						'other' => q({0} de pinte metrice),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} pinte metrice),
						'name' => q(pinte metrice),
						'one' => q({0} pintă metrică),
						'other' => q({0} de pinte metrice),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} quarte),
						'name' => q(quarte),
						'one' => q({0} quart),
						'other' => q({0} de quarte),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} quarte),
						'name' => q(quarte),
						'one' => q({0} quart),
						'other' => q({0} de quarte),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} quarte imperiale),
						'name' => q(quart imperial),
						'one' => q({0} quart imperial),
						'other' => q({0} de quarte imperiale),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} quarte imperiale),
						'name' => q(quart imperial),
						'one' => q({0} quart imperial),
						'other' => q({0} de quarte imperiale),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} linguri),
						'name' => q(linguri),
						'one' => q({0} lingură),
						'other' => q({0} de linguri),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} linguri),
						'name' => q(linguri),
						'one' => q({0} lingură),
						'other' => q({0} de linguri),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} lingurițe),
						'name' => q(lingurițe),
						'one' => q({0} linguriță),
						'other' => q({0} de lingurițe),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} lingurițe),
						'name' => q(lingurițe),
						'one' => q({0} linguriță),
						'other' => q({0} de lingurițe),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grad),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acru),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acru),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} itemi),
						'one' => q({0} item),
						'other' => q({0} itemi),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} itemi),
						'one' => q({0} item),
						'other' => q({0} itemi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(carat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carat),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mi/gal),
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mi/gal),
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} z),
						'name' => q(zi),
						'one' => q({0} z),
						'other' => q({0} z),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} z),
						'name' => q(zi),
						'one' => q({0} z),
						'other' => q({0} z),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} h),
						'name' => q(oră),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} h),
						'name' => q(oră),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(săpt.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(săpt.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} a),
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} a),
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
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
					'force-pound-force' => {
						'name' => q(lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
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
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0}″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0}″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(baniță),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(baniță),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cană),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cană),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp im),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp im),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dr fl),
						'name' => q(dr fl),
						'one' => q({0} dr fl),
						'other' => q({0} dr fl),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dr fl),
						'name' => q(dr fl),
						'one' => q({0} dr fl),
						'other' => q({0} dr fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} pic.),
						'one' => q({0} pic.),
						'other' => q({0} pic.),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} pic.),
						'one' => q({0} pic.),
						'other' => q({0} pic.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz im),
						'one' => q({0} fl oz im),
						'other' => q({0} fl oz im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz im),
						'one' => q({0} fl oz im),
						'other' => q({0} fl oz im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal im),
						'one' => q({0} gal im),
						'other' => q({0} gal im),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal im),
						'one' => q({0} gal im),
						'other' => q({0} gal im),
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
					'volume-pinch' => {
						'few' => q({0} vf.),
						'name' => q(vf.),
						'one' => q({0} vf.),
						'other' => q({0} vf.),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} vf.),
						'name' => q(vf.),
						'one' => q({0} vf.),
						'other' => q({0} vf.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintă),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintă),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} qt im),
						'name' => q(qt im),
						'one' => q({0} qt im),
						'other' => q({0} qt im),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} qt im),
						'name' => q(qt im),
						'one' => q({0} qt im),
						'other' => q({0} qt im),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direcție),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direcție),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(forță g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(forță g),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} arcmin),
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} arcmin),
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} arcsec),
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} arcsec),
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grade),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grade),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} rev.),
						'name' => q(rev.),
						'one' => q({0} rev.),
						'other' => q({0} rev.),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} rev.),
						'name' => q(rev.),
						'one' => q({0} rev.),
						'other' => q({0} rev.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} ac.),
						'name' => q(acri),
						'one' => q({0} ac.),
						'other' => q({0} ac.),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} ac.),
						'name' => q(acri),
						'one' => q({0} ac.),
						'other' => q({0} ac.),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunami),
						'name' => q(dunami),
						'one' => q({0} dunam),
						'other' => q({0} dunami),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunami),
						'name' => q(dunami),
						'one' => q({0} dunam),
						'other' => q({0} dunami),
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
					'area-square-centimeter' => {
						'per' => q({0} pe cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0} pe cm²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0} pe m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0} pe m²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} itemi),
						'one' => q({0} de itemi),
						'other' => q({0} de itemi),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} itemi),
						'one' => q({0} de itemi),
						'other' => q({0} de itemi),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} moli),
						'one' => q({0} mol),
						'other' => q({0} moli),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} moli),
						'one' => q({0} mol),
						'other' => q({0} moli),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mile/gal.),
						'name' => q(mile/gal.),
						'one' => q({0} milă/gal.),
						'other' => q({0} mile/gal.),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mile/gal.),
						'name' => q(mile/gal.),
						'one' => q({0} milă/gal.),
						'other' => q({0} mile/gal.),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mi/gal imp.),
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mi/gal imp.),
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'west' => q({0}V),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} b),
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} b),
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} B),
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} B),
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} sec.),
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} sec.),
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} zile),
						'name' => q(zile),
						'one' => q({0} zi),
						'other' => q({0} zile),
						'per' => q({0}/zi),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} zile),
						'name' => q(zile),
						'one' => q({0} zi),
						'other' => q({0} zile),
						'per' => q({0}/zi),
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
						'few' => q({0} ore),
						'name' => q(ore),
						'one' => q({0} oră),
						'other' => q({0} ore),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} ore),
						'name' => q(ore),
						'one' => q({0} oră),
						'other' => q({0} ore),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} luni),
						'name' => q(luni),
						'one' => q({0} lună),
						'other' => q({0} luni),
						'per' => q({0}/lună),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} luni),
						'name' => q(luni),
						'one' => q({0} lună),
						'other' => q({0} luni),
						'per' => q({0}/lună),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} trim.),
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} trim.),
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} săpt.),
						'name' => q(săptămâni),
						'one' => q({0} săpt.),
						'other' => q({0} săpt.),
						'per' => q({0}/săpt.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} săpt.),
						'name' => q(săptămâni),
						'one' => q({0} săpt.),
						'other' => q({0} săpt.),
						'per' => q({0}/săpt.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} ani),
						'name' => q(ani),
						'one' => q({0} an),
						'other' => q({0} ani),
						'per' => q({0}/an),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} ani),
						'name' => q(ani),
						'one' => q({0} an),
						'other' => q({0} ani),
						'per' => q({0}/an),
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
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} thm),
						'name' => q(thm),
						'one' => q({0} thm),
						'other' => q({0} thm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} thm),
						'name' => q(thm),
						'one' => q({0} thm),
						'other' => q({0} thm),
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
					'force-pound-force' => {
						'name' => q(livră-forță),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(livră-forță),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} pct.),
						'name' => q(pct.),
						'one' => q({0} pct),
						'other' => q({0} pct.),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} pct.),
						'name' => q(pct.),
						'one' => q({0} pct),
						'other' => q({0} pct.),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} dpc),
						'name' => q(dpc),
						'one' => q({0} dpc),
						'other' => q({0} dpc),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} dpc),
						'name' => q(dpc),
						'one' => q({0} dpc),
						'other' => q({0} dpc),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixeli),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixeli),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixeli),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixeli),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} ppc),
						'name' => q(ppc),
						'one' => q({0} ppc),
						'other' => q({0} ppc),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} ppc),
						'name' => q(ppc),
						'one' => q({0} ppc),
						'other' => q({0} ppc),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} ua),
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} ua),
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathomi),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathomi),
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
						'few' => q({0} a.l.),
						'name' => q(a.l.),
						'one' => q({0} a.l.),
						'other' => q({0} a.l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} a.l.),
						'name' => q(a.l.),
						'one' => q({0} a.l.),
						'other' => q({0} a.l.),
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
					'length-nautical-mile' => {
						'few' => q({0} mn),
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} mn),
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} ct),
						'name' => q(carate),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} ct),
						'name' => q(carate),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} boabe),
						'name' => q(boabă),
						'one' => q({0} boabă),
						'other' => q({0} boabe),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} boabe),
						'name' => q(boabă),
						'one' => q({0} boabă),
						'other' => q({0} boabe),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grame),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grame),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} t.s.),
						'name' => q(t.s.),
						'one' => q({0} t.s.),
						'other' => q({0} t.s.),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} t.s.),
						'name' => q(t.s.),
						'one' => q({0} t.s.),
						'other' => q({0} t.s.),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} CP),
						'name' => q(CP),
						'one' => q({0} CP),
						'other' => q({0} CP),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} CP),
						'name' => q(CP),
						'one' => q({0} CP),
						'other' => q({0} CP),
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
					'pressure-inch-ofhg' => {
						'few' => q({0} in Hg),
						'name' => q(in Hg),
						'one' => q({0} in Hg),
						'other' => q({0} in Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} in Hg),
						'name' => q(in Hg),
						'one' => q({0} in Hg),
						'other' => q({0} in Hg),
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
					'times' => {
						'1' => q({0} {1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0} {1}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(livră-forță picior),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(livră-forță picior),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(baril),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(baril),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(banițe),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(banițe),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(căni),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(căni),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} dsp im),
						'one' => q({0} dsp im),
						'other' => q({0} dsp im),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} dsp im),
						'one' => q({0} dsp im),
						'other' => q({0} dsp im),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram lichid),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram lichid),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} picături),
						'name' => q(picătură),
						'one' => q({0} picătură),
						'other' => q({0} de picături),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} picături),
						'name' => q(picătură),
						'one' => q({0} picătură),
						'other' => q({0} de picături),
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
						'few' => q({0} fl oz imp.),
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz imp.),
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
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
						'few' => q({0} gal imp.),
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0} gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal imp.),
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0} gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
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
					'volume-megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} vârfuri),
						'name' => q(vârf),
						'one' => q({0} vârf),
						'other' => q({0} de vârfuri),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} vârfuri),
						'name' => q(vârf),
						'one' => q({0} vârf),
						'other' => q({0} de vârfuri),
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
						'few' => q({0} qt imp.),
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} qt imp.),
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
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
	default		=> sub { qr'^(?i:nu|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} și {1}),
				2 => q({0} și {1}),
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
					'few' => '0 mii',
					'one' => '0 mie',
					'other' => '0 de mii',
				},
				'10000' => {
					'few' => '00 mii',
					'one' => '00 mie',
					'other' => '00 de mii',
				},
				'100000' => {
					'few' => '000 mii',
					'one' => '000 mie',
					'other' => '000 de mii',
				},
				'1000000' => {
					'few' => '0 milioane',
					'one' => '0 milion',
					'other' => '0 de milioane',
				},
				'10000000' => {
					'few' => '00 milioane',
					'one' => '00 milion',
					'other' => '00 de milioane',
				},
				'100000000' => {
					'few' => '000 milioane',
					'one' => '000 milion',
					'other' => '000 de milioane',
				},
				'1000000000' => {
					'few' => '0 miliarde',
					'one' => '0 miliard',
					'other' => '0 de miliarde',
				},
				'10000000000' => {
					'few' => '00 miliarde',
					'one' => '00 miliard',
					'other' => '00 de miliarde',
				},
				'100000000000' => {
					'few' => '000 miliarde',
					'one' => '000 miliard',
					'other' => '000 de miliarde',
				},
				'1000000000000' => {
					'few' => '0 trilioane',
					'one' => '0 trilion',
					'other' => '0 de trilioane',
				},
				'10000000000000' => {
					'few' => '00 trilioane',
					'one' => '00 trilion',
					'other' => '00 de trilioane',
				},
				'100000000000000' => {
					'few' => '000 trilioane',
					'one' => '000 trilion',
					'other' => '000 de trilioane',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 K',
					'other' => '0 K',
				},
				'10000' => {
					'one' => '00 K',
					'other' => '00 K',
				},
				'100000' => {
					'one' => '000 K',
					'other' => '000 K',
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
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'one' => '0 tril'.'',
					'other' => '0 tril'.'',
				},
				'10000000000000' => {
					'one' => '00 tril'.'',
					'other' => '00 tril'.'',
				},
				'100000000000000' => {
					'one' => '000 tril'.'',
					'other' => '000 tril'.'',
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
				'currency' => q(pesetă andorrană),
				'few' => q(pesete andorrane),
				'one' => q(pesetă andorrană),
				'other' => q(pesete andorrane),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham din Emiratele Arabe Unite),
				'few' => q(dirhami din Emiratele Arabe Unite),
				'one' => q(dirham din Emiratele Arabe Unite),
				'other' => q(dirhami din Emiratele Arabe Unite),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani afgan),
				'few' => q(afgani afgani),
				'one' => q(afgani afgan),
				'other' => q(afgani afgani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armenesc),
				'few' => q(drami armenești),
				'one' => q(dram armenesc),
				'other' => q(drami armenești),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(gulden neerlandez antilez),
				'few' => q(guldeni neerlandezi antilezi),
				'one' => q(gulden neerlandez antilez),
				'other' => q(guldeni neerlandezi antilezi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angoleză),
				'few' => q(kwanze angoleze),
				'one' => q(kwanza angoleză),
				'other' => q(kwanze angoleze),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentinian \(1983–1985\)),
				'few' => q(pesos argentinieni \(1983–1985\)),
				'one' => q(peso argentinian \(1983–1985\)),
				'other' => q(pesos argentinieni \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentinian),
				'few' => q(pesos argentinieni),
				'one' => q(peso argentinian),
				'other' => q(pesos argentinieni),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(șiling austriac),
				'few' => q(șilingi austrieci),
				'one' => q(șiling austriac),
				'other' => q(șilingi austrieci),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(dolar australian),
				'few' => q(dolari australieni),
				'one' => q(dolar australian),
				'other' => q(dolari australieni),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florin aruban),
				'few' => q(florini arubani),
				'one' => q(florin aruban),
				'other' => q(florini arubani),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azer \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azer),
				'few' => q(manați azeri),
				'one' => q(manat azer),
				'other' => q(manați azeri),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar Bosnia-Herțegovina \(1992–1994\)),
				'few' => q(dinari Bosnia-Herțegovina),
				'one' => q(dinar Bosnia-Herțegovina \(1992–1994\)),
				'other' => q(dinari Bosnia-Herțegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marcă convertibilă),
				'few' => q(mărci convertibile),
				'one' => q(marcă convertibilă),
				'other' => q(mărci convertibile),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dolar din Barbados),
				'few' => q(dolari din Barbados),
				'one' => q(dolar din Barbados),
				'other' => q(dolari din Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka din Bangladesh),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franc belgian \(convertibil\)),
				'few' => q(franci belgieni \(convertibili\)),
				'one' => q(franc belgian \(convertibil\)),
				'other' => q(franci belgieni \(convertibili\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franc belgian),
				'few' => q(franci belgieni),
				'one' => q(franc belgian),
				'other' => q(franci belgieni),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franc belgian \(financiar\)),
				'few' => q(franci belgieni \(financiari\)),
				'one' => q(franc belgian \(financiar\)),
				'other' => q(franci belgieni \(financiari\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(leva),
				'few' => q(leve),
				'one' => q(leva),
				'other' => q(leve),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar din Bahrain),
				'few' => q(dinari din Bahrain),
				'one' => q(dinar din Bahrain),
				'other' => q(dinari din Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franc burundez),
				'few' => q(franci burundezi),
				'one' => q(franc burundez),
				'other' => q(franci burundezi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dolar din Bermuda),
				'few' => q(dolari din Bermuda),
				'one' => q(dolar din Bermuda),
				'other' => q(dolari din Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dolar din Brunei),
				'few' => q(dolari din Brunei),
				'one' => q(dolar din Brunei),
				'other' => q(dolari Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso bolivian),
				'few' => q(pesos bolivieni),
				'one' => q(peso bolivian),
				'other' => q(pesos bolivieni),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(mvdol bolivian),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzeiro brazilian \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real),
				'few' => q(reali),
				'one' => q(real),
				'other' => q(reali),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro brazilian \(1993–1994\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dolar din Bahamas),
				'few' => q(dolari din Bahamas),
				'one' => q(dolar din Bahamas),
				'other' => q(dolari din Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum din Bhutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birman),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula Botswana),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(rublă belarusă),
				'few' => q(ruble belaruse),
				'one' => q(rublă belarusă),
				'other' => q(ruble belaruse),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(rublă belarusă \(2000–2016\)),
				'few' => q(ruble belaruse \(2000–2016\)),
				'one' => q(rublă belarusă \(2000–2016\)),
				'other' => q(ruble belaruse \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dolar din Belize),
				'few' => q(dolari din Belize),
				'one' => q(dolar din Belize),
				'other' => q(dolari din Belize),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(dolar canadian),
				'few' => q(dolari canadieni),
				'one' => q(dolar canadian),
				'other' => q(dolari canadieni),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolez),
				'few' => q(franci congolezi),
				'one' => q(franc congolez),
				'other' => q(franci congolezi),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franc elvețian),
				'few' => q(franci elvețieni),
				'one' => q(franc elvețian),
				'other' => q(franci elvețieni),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso chilian),
				'few' => q(pesos chilieni),
				'one' => q(peso chilian),
				'other' => q(pesos chilieni),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan chinezesc \(offshore\)),
				'few' => q(yuani chinezești \(offshore\)),
				'one' => q(yuan chinezesc \(offshore\)),
				'other' => q(yuani chinezești \(offshore\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(yuan chinezesc),
				'few' => q(yuani chinezești),
				'one' => q(yuan chinezesc),
				'other' => q(yuani chinezești),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso columbian),
				'few' => q(pesos columbieni),
				'one' => q(peso columbian),
				'other' => q(pesos columbieni),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colón costarican),
				'few' => q(colóni costaricani),
				'one' => q(colón costarican),
				'other' => q(colóni costaricani),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar Serbia și Muntenegru \(2002–2006\)),
				'few' => q(dinari Serbia și Muntenegru \(2002–2006\)),
				'one' => q(dinar Serbia și Muntenegru \(2002–2006\)),
				'other' => q(dinari Serbia și Muntenegru \(2002–2006\)),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cubanez convertibil),
				'few' => q(pesos cubanezi convertibili),
				'one' => q(peso cubanez convertibil),
				'other' => q(pesos cubanezi convertibili),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cubanez),
				'few' => q(pesos cubanezi),
				'one' => q(peso cubanez),
				'other' => q(pesos cubanezi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo caboverdian),
				'few' => q(escudo caboverdieni),
				'one' => q(escudo caboverdian),
				'other' => q(escudo caboverdieni),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(liră cipriotă),
				'few' => q(lire cipriote),
				'one' => q(liră cipriotă),
				'other' => q(lire cipriote),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(coroană cehă),
				'few' => q(coroane cehe),
				'one' => q(coroană cehă),
				'other' => q(coroane cehe),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(marcă est-germană),
				'few' => q(mărci est-germane),
				'one' => q(marcă est-germană),
				'other' => q(mărci est-germane),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marcă germană),
				'few' => q(mărci germane),
				'one' => q(marcă germană),
				'other' => q(mărci germane),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franc djiboutian),
				'few' => q(franci djiboutieni),
				'one' => q(franc djiboutian),
				'other' => q(franci djiboutieni),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(coroană daneză),
				'few' => q(coroane daneze),
				'one' => q(coroană daneză),
				'other' => q(coroane daneze),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominican),
				'few' => q(pesos dominicani),
				'one' => q(peso dominican),
				'other' => q(pesos dominicani),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerian),
				'few' => q(dinari algerieni),
				'one' => q(dinar algerian),
				'other' => q(dinari algerieni),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(coroană estoniană),
				'few' => q(coroane estoniene),
				'one' => q(coroană estoniană),
				'other' => q(coroane estoniene),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(liră egipteană),
				'few' => q(lire egiptene),
				'one' => q(liră egipteană),
				'other' => q(lire egiptene),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritreeană),
				'few' => q(nakfa eritreene),
				'one' => q(nakfa eritreeană),
				'other' => q(nakfa eritreene),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta spaniolă \(cont A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta spaniolă \(cont convertibil\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(pesetă spaniolă),
				'few' => q(pesete spaniole),
				'one' => q(pesetă spaniolă),
				'other' => q(pesete spaniole),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etiopian),
				'few' => q(birri etiopieni),
				'one' => q(birr etiopian),
				'other' => q(birri etiopieni),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(marcă finlandeză),
				'few' => q(mărci finlandeze),
				'one' => q(mărci finlandeze),
				'other' => q(mărci finlandeze),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dolar fijian),
				'few' => q(dolari fijieni),
				'one' => q(dolar fijian),
				'other' => q(dolari fijieni),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(liră din Insulele Falkland),
				'few' => q(lire din Insulele Falkland),
				'one' => q(liră din Insulele Falkland),
				'other' => q(lire din Insulele Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franc francez),
				'few' => q(franci francezi),
				'one' => q(franc francez),
				'other' => q(franci francezi),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(liră sterlină),
				'few' => q(lire sterline),
				'one' => q(liră sterlină),
				'other' => q(lire sterline),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari georgian),
				'few' => q(lari georgieni),
				'one' => q(lari georgian),
				'other' => q(lari georgieni),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi Ghana \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanez),
				'few' => q(cedi ghanezi),
				'one' => q(cedi ghanez),
				'other' => q(cedi ghanezi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(liră din Gibraltar),
				'few' => q(lire din Gibraltar),
				'one' => q(liră din Gibraltar),
				'other' => q(lire Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi din Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franc guineean),
				'few' => q(franci guineeni),
				'one' => q(franc guineean),
				'other' => q(franci guineeni),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(drahmă grecească),
				'few' => q(drahme grecești),
				'one' => q(drahmă grecească),
				'other' => q(drahme grecești),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatemalez),
				'few' => q(quetzali guatemalezi),
				'one' => q(quetzal guatemalez),
				'other' => q(quetzali guatemalezi),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso Guineea-Bissau),
				'few' => q(pesos Guineea-Bissau),
				'one' => q(peso Guineea-Bissau),
				'other' => q(pesos Guineea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dolar guyanez),
				'few' => q(dolari guyanezi),
				'one' => q(dolar guyanez),
				'other' => q(dolari guyanezi),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dolar din Hong Kong),
				'few' => q(dolari din Hong Kong),
				'one' => q(dolar din Hong Kong),
				'other' => q(dolari din Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira honduriană),
				'few' => q(lempire honduriene),
				'one' => q(lempiră honduriană),
				'other' => q(lempire honduriene),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croat),
				'few' => q(dinari croați),
				'one' => q(dinar croat),
				'other' => q(dinari croați),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde din Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint),
				'few' => q(forinți),
				'one' => q(forint),
				'other' => q(forinți),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupie indoneziană),
				'few' => q(rupii indoneziene),
				'one' => q(rupie indoneziană),
				'other' => q(rupii indoneziene),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(liră irlandeză),
				'few' => q(lire irlandeze),
				'one' => q(liră irlandeză),
				'other' => q(lire irlandeze),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(liră israeliană),
				'few' => q(lire israeliene),
				'one' => q(liră israeliană),
				'other' => q(lire israeliene),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(shekel israelian nou),
				'few' => q(shekeli israelieni noi),
				'one' => q(shekel israelian nou),
				'other' => q(shekeli israelieni noi),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(rupie indiană),
				'few' => q(rupii indiene),
				'one' => q(rupie indiană),
				'other' => q(rupii indiene),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar irakian),
				'few' => q(dinari irakieni),
				'one' => q(dinar irakian),
				'other' => q(dinari irakieni),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranian),
				'few' => q(riali iranieni),
				'one' => q(rial iranian),
				'other' => q(riali iranieni),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(coroană islandeză),
				'few' => q(coroane islandeze),
				'one' => q(coroană islandeză),
				'other' => q(coroane islandeze),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(liră italiană),
				'few' => q(lire italiene),
				'one' => q(liră italiană),
				'other' => q(lire italiene),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dolar jamaican),
				'few' => q(dolari jamaicani),
				'one' => q(dolar jamaican),
				'other' => q(dolari jamaicani),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar iordanian),
				'few' => q(dinari iordanieni),
				'one' => q(dinar iordanian),
				'other' => q(dinari iordanieni),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen japonez),
				'few' => q(yeni japonezi),
				'one' => q(yen japonez),
				'other' => q(yeni japonezi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(șiling kenyan),
				'few' => q(șilingi kenyeni),
				'one' => q(șiling kenyan),
				'other' => q(șilingi kenyeni),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kârgâz),
				'few' => q(somi kârgâzi),
				'one' => q(som kârgâz),
				'other' => q(somi kârgâzi),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambodgian),
				'few' => q(rieli cambodgieni),
				'one' => q(riel cambodgian),
				'other' => q(rieli cambodgieni),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franc comorian),
				'few' => q(franci comorieni),
				'one' => q(franc comorian),
				'other' => q(franci comorieni),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nord-coreean),
				'few' => q(woni nord-coreeni),
				'one' => q(won nord-coreean),
				'other' => q(woni nord-coreeni),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(won sud-coreean),
				'few' => q(woni sud-coreeni),
				'one' => q(won sud-coreean),
				'other' => q(woni sud-coreeni),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar kuweitian),
				'few' => q(dinari kuweitieni),
				'one' => q(dinar kuweitian),
				'other' => q(dinari kuweitieni),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dolar din Insulele Cayman),
				'few' => q(dolari din Insulele Cayman),
				'one' => q(dolar din Insulele Cayman),
				'other' => q(dolari din Insulele Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazahă),
				'few' => q(tenge kazahe),
				'one' => q(tenge kazahă),
				'other' => q(tenge kazahe),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laoțian),
				'few' => q(kipi laoțieni),
				'one' => q(kip laoțian),
				'other' => q(kipi laoțieni),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(liră libaneză),
				'few' => q(lire libaneze),
				'one' => q(liră libaneză),
				'other' => q(lire libaneze),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupie srilankeză),
				'few' => q(rupii srilankeze),
				'one' => q(rupie srilankeză),
				'other' => q(rupii srilankeze),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dolar liberian),
				'few' => q(dolari liberieni),
				'one' => q(dolar liberian),
				'other' => q(dolari liberieni),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesothian),
				'few' => q(maloti lesothieni),
				'one' => q(loti lesothian),
				'other' => q(maloti lesothieni),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litu lituanian),
				'few' => q(lite lituaniene),
				'one' => q(litu lituanian),
				'other' => q(lite lituaniene),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franc convertibil luxemburghez),
				'few' => q(franci convertibili luxemburghezi),
				'one' => q(franc convertibil luxemburghez),
				'other' => q(franci convertibili luxemburghezi),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franc luxemburghez),
				'few' => q(franci luxemburghezi),
				'one' => q(franc luxemburghez),
				'other' => q(franci luxemburghezi),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franc financiar luxemburghez),
				'few' => q(franci financiari luxemburghezi),
				'one' => q(franc financiar luxemburghez),
				'other' => q(franci financiari luxemburghezi),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats letonian),
				'few' => q(lats letonieni),
				'one' => q(lats letonian),
				'other' => q(lats letonieni),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rublă Letonia),
				'few' => q(ruble Letonia),
				'one' => q(rublă Letonia),
				'other' => q(ruble Letonia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libian),
				'few' => q(dinari libieni),
				'one' => q(dinar libian),
				'other' => q(dinari libieni),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocan),
				'few' => q(dirhami marocani),
				'one' => q(dirham marocan),
				'other' => q(dirhami marocani),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franc marocan),
				'few' => q(franci marocani),
				'one' => q(franc marocan),
				'other' => q(franci marocani),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldovenesc),
				'few' => q(lei moldovenești),
				'one' => q(leu moldovenesc),
				'other' => q(lei moldovenești),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgaș),
				'few' => q(ariary malgași),
				'one' => q(ariary malgaș),
				'other' => q(ariary malgași),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franc Madagascar),
				'few' => q(franci Madagascar),
				'one' => q(franc Madagascar),
				'other' => q(franci Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(denar),
				'few' => q(denari),
				'one' => q(denar),
				'other' => q(denari),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franc Mali),
				'few' => q(franci Mali),
				'one' => q(franc Mali),
				'other' => q(franci Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat din Myanmar),
				'few' => q(kyați din Myanmar),
				'one' => q(kyat din Myanmar),
				'other' => q(kyați din Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongol),
				'few' => q(tugrici mongoli),
				'one' => q(tugrik mongol),
				'other' => q(tugrici mongoli),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca din Macao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya mauritană \(1973–2017\)),
				'few' => q(ouguiya mauritane \(1973–2017\)),
				'one' => q(ouguiya mauritană \(1973–2017\)),
				'other' => q(ouguiya mauritane \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya mauritană),
				'few' => q(ouguiya mauritane),
				'one' => q(ouguiya mauritană),
				'other' => q(ouguiya mauritane),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(liră malteză),
				'few' => q(lire malteze),
				'one' => q(liră malteză),
				'other' => q(lire malteze),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupie mauritiană),
				'few' => q(rupii mauritiene),
				'one' => q(rupie mauritiană),
				'other' => q(rupii mauritiene),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa maldiviană),
				'few' => q(rufiyaa maldiviene),
				'one' => q(rufiyaa maldiviană),
				'other' => q(rufiyaa maldiviene),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawiană),
				'few' => q(kwache malawiene),
				'one' => q(kwacha malawiană),
				'other' => q(kwache malawiene),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(peso mexican),
				'few' => q(pesos mexicani),
				'one' => q(peso mexican),
				'other' => q(pesos mexicani),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso mexican de argint \(1861–1992\)),
				'few' => q(pesos mexicani de argint \(1861–1992),
				'one' => q(peso mexican de argint \(1861–1992\)),
				'other' => q(pesos mexicani de argint \(1861–1992\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malaiezian),
				'few' => q(ringgit malaiezieni),
				'one' => q(ringgit malaiezian),
				'other' => q(ringgit malaiezieni),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo Mozambic),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metical Mozambic vechi),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozambican),
				'few' => q(meticali mozambicani),
				'one' => q(metical mozambican),
				'other' => q(meticali mozambicani),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dolar namibian),
				'few' => q(dolari namibieni),
				'one' => q(dolar namibian),
				'other' => q(dolari namibieni),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriană),
				'few' => q(naire nigeriene),
				'one' => q(naira nigeriană),
				'other' => q(naire nigeriene),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba nicaraguană \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba oro),
				'few' => q(córdobe oro),
				'one' => q(córdoba oro),
				'other' => q(córdobe oro),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(gulden olandez),
				'few' => q(guldeni olandezi),
				'one' => q(gulden olandez),
				'other' => q(guldeni olandezi),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(coroană norvegiană),
				'few' => q(coroane norvegiene),
				'one' => q(coroană norvegiană),
				'other' => q(coroane norvegiene),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupie nepaleză),
				'few' => q(rupii nepaleze),
				'one' => q(rupie nepaleză),
				'other' => q(rupii nepaleze),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(dolar neozeelandez),
				'few' => q(dolari neozeelandezi),
				'one' => q(dolar neozeelandez),
				'other' => q(dolari neozeelandezi),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omanez),
				'few' => q(riali omanezi),
				'one' => q(rial omanez),
				'other' => q(riali omanezi),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panameză),
				'few' => q(balboa panameze),
				'one' => q(balboa panameză),
				'other' => q(balboa panameze),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruvian),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol),
				'few' => q(soli),
				'one' => q(sol),
				'other' => q(soli),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruvian \(1863–1965\)),
				'few' => q(soli peruvieni \(1863–1965\)),
				'one' => q(sol peruvian \(1863–1965\)),
				'other' => q(soli peruvieni \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina din Papua-Noua Guinee),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filipinez),
				'few' => q(pesos filipinezi),
				'one' => q(peso filipinez),
				'other' => q(pesos filipinezi),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupie pakistaneză),
				'few' => q(rupii pakistaneze),
				'one' => q(rupie pakistaneză),
				'other' => q(rupii pakistaneze),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zlot),
				'few' => q(zloți),
				'one' => q(zlot),
				'other' => q(zloți),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zlot polonez \(1950–1995\)),
				'few' => q(zloți polonezi \(1950–1995\)),
				'one' => q(zlot polonez \(1950–1995\)),
				'other' => q(zloți polonezi \(1950–1995\)),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial qatarian),
				'few' => q(riali qatarieni),
				'one' => q(rial qatarian),
				'other' => q(riali qatarieni),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dolar rhodesian),
				'few' => q(dolari rhodesieni),
				'one' => q(dolar rhodesian),
				'other' => q(dolari rhodesieni),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(leu românesc \(1952–2006\)),
				'few' => q(lei românești \(1952–2006\)),
				'one' => q(leu românesc \(1952–2006\)),
				'other' => q(lei românești \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu românesc),
				'few' => q(lei românești),
				'one' => q(leu românesc),
				'other' => q(lei românești),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar sârbesc),
				'few' => q(dinari sârbești),
				'one' => q(dinar sârbesc),
				'other' => q(dinari sârbești),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublă rusească),
				'few' => q(ruble rusești),
				'one' => q(rublă rusească),
				'other' => q(ruble rusești),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franc rwandez),
				'few' => q(franci rwandezi),
				'one' => q(franc rwandez),
				'other' => q(franci rwandezi),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saudit),
				'few' => q(riali saudiți),
				'one' => q(rial saudit),
				'other' => q(riali saudiți),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dolar din Insulele Solomon),
				'few' => q(dolari din Insulele Solomon),
				'one' => q(dolar din Insulele Solomon),
				'other' => q(dolari din Insulele Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupie seychelleză),
				'few' => q(rupii seychelleze),
				'one' => q(rupie seychelleză),
				'other' => q(rupii seychelleze),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanez),
				'few' => q(dinari sudanezi),
				'one' => q(dinar sudanez),
				'other' => q(dinari sudanezi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(liră sudaneză),
				'few' => q(lire sudaneze),
				'one' => q(liră sudaneză),
				'other' => q(lire sudaneze),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(liră sudaneză \(1957–1998\)),
				'few' => q(lire sudaneze \(1957–1998\)),
				'one' => q(liră sudaneză \(1957–1998\)),
				'other' => q(lire sudaneze \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(coroană suedeză),
				'few' => q(coroane suedeze),
				'one' => q(coroană suedeză),
				'other' => q(coroane suedeze),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dolar singaporez),
				'few' => q(dolari singaporezi),
				'one' => q(dolar singaporez),
				'other' => q(dolari singaporezi),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(liră din Sfânta Elena \(Sfânta Elena și Ascension\)),
				'few' => q(lire din Sfânta Elena \(Sfânta Elena și Ascension\)),
				'one' => q(liră din Sfânta Elena \(Sfânta Elena și Ascension\)),
				'other' => q(lire din Sfânta Elena \(Sfânta Elena și Ascension\)),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar sloven),
				'few' => q(tolari sloveni),
				'one' => q(tolar sloven),
				'other' => q(tolari sloveni),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(coroană slovacă),
				'few' => q(coroane slovace),
				'one' => q(coroană slovacă),
				'other' => q(coroane slovace),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone din Sierra Leone),
				'few' => q(leoni din Sierra Leone),
				'one' => q(leone din Sierra Leone),
				'other' => q(leoni din Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone din Sierra Leone \(1964—2022\)),
				'few' => q(leoni din Sierra Leone \(1964—2022\)),
				'one' => q(leone din Sierra Leone \(1964—2022\)),
				'other' => q(leoni din Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(șiling somalez),
				'few' => q(șilingi somalezi),
				'one' => q(șiling somalez),
				'other' => q(șilingi somalezi),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dolar surinamez),
				'few' => q(dolari surinamezi),
				'one' => q(dolar surinamez),
				'other' => q(dolari surinamezi),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(gulden Surinam),
				'few' => q(guldeni Surinam),
				'one' => q(gulden Surinam),
				'other' => q(guldeni Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(liră din Sudanul de Sud),
				'few' => q(lire din Sudanul de Sud),
				'one' => q(liră din Sudanul de Sud),
				'other' => q(lire din Sudanul de Sud),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra Sao Tome și Principe \(1977–2017\)),
				'few' => q(dobre Sao Tome și Principe \(1977–2017\)),
				'one' => q(dobra Sao Tome și Principe \(1977–2017\)),
				'other' => q(dobre Sao Tome și Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra din São Tomé și Príncipe),
				'few' => q(dobre din São Tomé și Príncipe),
				'one' => q(dobra din São Tomé și Príncipe),
				'other' => q(dobre din São Tomé și Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rublă sovietică),
				'few' => q(ruble sovietice),
				'one' => q(rublă sovietică),
				'other' => q(ruble sovietice),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colon El Salvador),
				'few' => q(coloni El Salvador),
				'one' => q(colon El Salvador),
				'other' => q(coloni El Salvador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(liră siriană),
				'few' => q(lire siriene),
				'one' => q(liră siriană),
				'other' => q(lire siriene),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni din Swaziland),
				'few' => q(emalangeni din Swaziland),
				'one' => q(lilangeni din Swaziland),
				'other' => q(emalangeni din Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht thailandez),
				'few' => q(bahți thailandezi),
				'one' => q(baht thailandez),
				'other' => q(bahți thailandezi),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rublă Tadjikistan),
				'few' => q(ruble Tadjikistan),
				'one' => q(rublă Tadjikistan),
				'other' => q(ruble Tadjikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tadjic),
				'few' => q(somoni tadjici),
				'one' => q(somoni tajdic),
				'other' => q(somoni tadjici),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turkmen \(1993–2009\)),
				'few' => q(manat turkmeni \(1993–2009\)),
				'one' => q(manat turkmen \(1993–2009\)),
				'other' => q(manat turkmeni \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turkmen),
				'few' => q(manat turkmeni),
				'one' => q(manat turkmen),
				'other' => q(manat turkmeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisian),
				'few' => q(dinari tunisieni),
				'one' => q(dinar tunisian),
				'other' => q(dinari tunisieni),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(pa’anga tongană),
				'few' => q(pa’anga tongane),
				'one' => q(pa’anga tongană),
				'other' => q(pa’anga tongane),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(liră turcească \(1922–2005\)),
				'few' => q(liră turcească \(1922–2005\)),
				'one' => q(liră turcească \(1922–2005\)),
				'other' => q(lire turcești \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(liră turcească),
				'few' => q(lire turcești),
				'one' => q(liră turcească),
				'other' => q(lire turcești),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dolar din Trinidad și Tobago),
				'few' => q(dolari din Trinidad și Tobago),
				'one' => q(dolar din Trinidad și Tobago),
				'other' => q(dolari din Trinidad și Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(dolar nou din Taiwan),
				'few' => q(dolari noi din Taiwan),
				'one' => q(dolar nou din Taiwan),
				'other' => q(dolari noi Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(șiling tanzanian),
				'few' => q(șilingi tanzanieni),
				'one' => q(șiling tanzanian),
				'other' => q(șilingi tanzanieni),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(grivnă),
				'few' => q(grivne),
				'one' => q(grivnă),
				'other' => q(grivne),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(carboavă ucraineană),
				'few' => q(carboave ucrainiene),
				'one' => q(carboavă ucraineană),
				'other' => q(carboave ucrainiene),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(șiling ugandez \(1966–1987\)),
				'few' => q(șilingi ugandezi \(1966–1987\)),
				'one' => q(șiling ugandez \(1966–1987\)),
				'other' => q(șilingi ugandezi \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(șiling ugandez),
				'few' => q(șilingi ugandezi),
				'one' => q(șiling ugandez),
				'other' => q(șilingi ugandezi),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(dolar american),
				'few' => q(dolari americani),
				'one' => q(dolar american),
				'other' => q(dolari americani),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dolar american \(ziua următoare\)),
				'few' => q(dolari americani \(ziua următoare\)),
				'one' => q(dolar american \(ziua următoare\)),
				'other' => q(dolari americani \(ziua următoare\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dolar american \(aceeași zi\)),
				'few' => q(dolari americani \(aceeași zi\)),
				'one' => q(dolar american \(aceeași zi\)),
				'other' => q(dolari americani \(aceeași zi\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso Uruguay \(1975–1993\)),
				'few' => q(pesos Uruguay \(1975–1993\)),
				'one' => q(peso Uruguay \(1975–1993\)),
				'other' => q(pesos Uruguay \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguayan),
				'few' => q(pesos uruguayeni),
				'one' => q(peso uruguayan),
				'other' => q(pesos uruguayeni),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum Uzbekistan),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar Venezuela \(1871–2008\)),
				'few' => q(bolivari Venezuela \(1871–2008\)),
				'one' => q(bolivar Venezuela \(1871–2008\)),
				'other' => q(bolivari Venezuela \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar venezuelean \(2008–2018\)),
				'few' => q(bolivari venezueleni \(2008–2018\)),
				'one' => q(bolivar venezuelean \(2008–2018\)),
				'other' => q(bolivari venezueleni \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar soberano),
				'few' => q(bolívari soberano),
				'one' => q(bolívar soberano),
				'other' => q(bolívari soberano),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(dong vietnamez),
				'few' => q(dongi vietnamezi),
				'one' => q(dong vietnamez),
				'other' => q(dongi vietnamezi),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu din Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoană),
				'few' => q(tala samoane),
				'one' => q(tala samoană),
				'other' => q(tala samoană),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franc CFA BEAC),
				'few' => q(franci CFA BEAC),
				'one' => q(franc CFA BEAC),
				'other' => q(franci CFA central-africani),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(argint),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(aur),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unitate compusă europeană),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unitate monetară europeană),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unitate de cont europeană \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unitate de cont europeană \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dolar est-caraib),
				'few' => q(dolari est-caraibi),
				'one' => q(dolar est-caraib),
				'other' => q(dolari est-caraibi),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(drepturi speciale de tragere),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unitate de monedă europeană),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franc francez de aur),
				'few' => q(franci francezi de aur),
				'one' => q(franc francez de aur),
				'other' => q(franci francezi de aur),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franc UIC francez),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franc CFA BCEAO),
				'few' => q(franci CFA BCEAO),
				'one' => q(franc CFA BCEAO),
				'other' => q(franci CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladiu),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franc CFP),
				'few' => q(franci CFP),
				'one' => q(franc CFP),
				'other' => q(franci CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platină),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(cod monetar de test),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(monedă necunoscută),
				'few' => q(\(monedă necunoscută\)),
				'one' => q(\(unitate monetară necunoscută\)),
				'other' => q(\(monedă necunoscută\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar Yemen),
				'few' => q(dinari Yemen),
				'one' => q(dinar Yemen),
				'other' => q(dinari Yemen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial yemenit),
				'few' => q(riali yemeniți),
				'one' => q(rial yemenit),
				'other' => q(riali yemeniți),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar iugoslav greu),
				'few' => q(dinari iugoslavi grei),
				'one' => q(dinar iugoslav greu),
				'other' => q(dinari iugoslavi grei),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(dinar iugoslav nou),
				'few' => q(dinari iugoslavi noi),
				'one' => q(dinar iugoslav nou),
				'other' => q(dinari iugoslavi noi),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar iugoslav convertibil),
				'few' => q(dinari iugoslavi convertibili),
				'one' => q(dinar iugoslav convertibil),
				'other' => q(dinari iugoslavi convertibili),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sud-african \(financiar\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sud-african),
				'few' => q(ranzi sud-africani),
				'one' => q(rand sud-african),
				'other' => q(ranzi sud-africani),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha zambian \(1968–2012\)),
				'few' => q(kwache zambiene \(1968–2012\)),
				'one' => q(kwacha zambiană \(1968–2012\)),
				'other' => q(kwache zambiene \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambian),
				'few' => q(kwache zambiene),
				'one' => q(kwacha zambian),
				'other' => q(kwache zambiene),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zair nou),
				'few' => q(zairi noi),
				'one' => q(zair nou),
				'other' => q(zairi noi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dolar Zimbabwe \(1980–2008\)),
				'few' => q(dolari Zimbabwe \(1980–2008\)),
				'one' => q(dolar Zimbabwe \(1980–2008\)),
				'other' => q(dolari Zimbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dolar Zimbabwe \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dolar Zimbabwe \(2008\)),
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
				},
				'stand-alone' => {
					wide => {
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
				},
			},
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'Thout',
							'Paopi',
							'Hathor',
							'Koiak',
							'Tobi',
							'Meshir',
							'Paremhat',
							'Paremoude',
							'Pashons',
							'Paoni',
							'Epip',
							'Mesori',
							'Pi Kogi Enavot'
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
							'meskerem',
							'taqemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehase',
							'pagumen'
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
							'ian.',
							'feb.',
							'mar.',
							'apr.',
							'mai',
							'iun.',
							'iul.',
							'aug.',
							'sept.',
							'oct.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ianuarie',
							'februarie',
							'martie',
							'aprilie',
							'mai',
							'iunie',
							'iulie',
							'august',
							'septembrie',
							'octombrie',
							'noiembrie',
							'decembrie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'I',
							'F',
							'M',
							'A',
							'M',
							'I',
							'I',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'Tișrei',
							'Heșvan',
							'Kislev',
							'Tevet',
							'Șevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tammuz',
							'Av',
							'Elul'
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
							'Chaitra',
							'Vaisakha',
							'Jyeshta',
							'Aashaadha',
							'Shraavana',
							'Bhadrapada',
							'Ashwin',
							'Kartik',
							'Margashirsha',
							'Pausha',
							'Magh',
							'Phalguna'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'A-Mordad',
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
						mon => 'lun.',
						tue => 'mar.',
						wed => 'mie.',
						thu => 'joi',
						fri => 'vin.',
						sat => 'sâm.',
						sun => 'dum.'
					},
					short => {
						mon => 'lu.',
						tue => 'ma.',
						wed => 'mi.',
						thu => 'joi',
						fri => 'vi.',
						sat => 'sâ.',
						sun => 'du.'
					},
					wide => {
						mon => 'luni',
						tue => 'marți',
						wed => 'miercuri',
						thu => 'joi',
						fri => 'vineri',
						sat => 'sâmbătă',
						sun => 'duminică'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					abbreviated => {0 => 'trim. I',
						1 => 'trim. II',
						2 => 'trim. III',
						3 => 'trim. IV'
					},
					wide => {0 => 'trimestrul I',
						1 => 'trimestrul al II-lea',
						2 => 'trimestrul al III-lea',
						3 => 'trimestrul al IV-lea'
					},
				},
				'stand-alone' => {
					narrow => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
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
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
					'afternoon1' => q{după-amiaza},
					'am' => q{a.m.},
					'evening1' => q{seara},
					'midnight' => q{miezul nopții},
					'morning1' => q{dimineața},
					'night1' => q{noaptea},
					'noon' => q{amiază},
					'pm' => q{p.m.},
				},
				'wide' => {
					'afternoon1' => q{după-amiaza},
					'evening1' => q{seara},
					'midnight' => q{la miezul nopții},
					'morning1' => q{dimineața},
					'night1' => q{noaptea},
					'noon' => q{la amiază},
				},
			},
			'stand-alone' => {
				'wide' => {
					'midnight' => q{la miezul nopții},
					'noon' => q{la amiază},
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
				'0' => 'e.b.'
			},
			wide => {
				'0' => 'era budistă'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'î.A.M.',
				'1' => 'A.M.'
			},
			wide => {
				'0' => 'înainte de Anno Martyrum',
				'1' => 'după Anno Martyrum'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'î.Într.',
				'1' => 'd.Într.'
			},
			wide => {
				'0' => 'înainte de Întrupare',
				'1' => 'după Întrupare'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'î.Hr.',
				'1' => 'd.Hr.'
			},
			wide => {
				'0' => 'înainte de Hristos',
				'1' => 'după Hristos'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'A.M.'
			},
		},
		'indian' => {
		},
		'islamic' => {
			wide => {
				'0' => 'A.H.'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'A.P.'
			},
			wide => {
				'0' => 'Anno Persico'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'î.R.C.',
				'1' => 'R.C.'
			},
			wide => {
				'0' => 'înainte de Republica China',
				'1' => 'Republica China'
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
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.y},
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
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
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
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd.MM.y G},
			MEd => q{E, dd.MM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y},
			yyyy => q{y G},
			yyyyM => q{MM.y G},
			yyyyMEd => q{E, dd.MM.y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd.MM.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd.MM.y G},
			MEd => q{E, dd.MM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'săptămâna' W 'din' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd.MM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'săptămâna' w 'din' Y},
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
		'buddhist' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y – MM.y GGGGG},
				y => q{MM.y – MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y – dd.MM.y GGGGG},
				d => q{dd.MM.y – dd.MM.y GGGGG},
				y => q{dd.MM.y – dd.MM.y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
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
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
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
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y – MM.y GGGGG},
				y => q{MM.y – MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y – dd.MM.y GGGGG},
				d => q{dd.MM.y – dd.MM.y GGGGG},
				y => q{dd.MM.y – dd.MM.y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
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
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
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
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Ora din {0}),
		regionFormat => q(Ora de vară din {0}),
		regionFormat => q(Ora standard din {0}),
		'Acre' => {
			long => {
				'daylight' => q#Ora de vară Acre#,
				'generic' => q#Ora Acre#,
				'standard' => q#Ora standard Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Ora Afganistanului#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ora Africii Centrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora Africii Orientale#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora Africii Meridionale#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora de vară a Africii Occidentale#,
				'generic' => q#Ora Africii Occidentale#,
				'standard' => q#Ora standard a Africii Occidentale#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora de vară din Alaska#,
				'generic' => q#Ora din Alaska#,
				'standard' => q#Ora standard din Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Ora de vară Almaty#,
				'generic' => q#Ora Almaty#,
				'standard' => q#Ora standard Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ora de vară a Amazonului#,
				'generic' => q#Ora Amazonului#,
				'standard' => q#Ora standard a Amazonului#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadelupa#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de Mexico#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota de Nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota de Nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota de Nord#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora de vară centrală nord-americană#,
				'generic' => q#Ora centrală nord-americană#,
				'standard' => q#Ora standard centrală nord-americană#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora de vară orientală nord-americană#,
				'generic' => q#Ora orientală nord-americană#,
				'standard' => q#Ora standard orientală nord-americană#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora de vară în zona montană nord-americană#,
				'generic' => q#Ora zonei montane nord-americane#,
				'standard' => q#Ora standard în zona montană nord-americană#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora de vară în zona Pacific nord-americană#,
				'generic' => q#Ora zonei Pacific nord-americane#,
				'standard' => q#Ora standard în zona Pacific nord-americană#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Ora de vară din Anadyr#,
				'generic' => q#Ora din Anadyr#,
				'standard' => q#Ora standard din Anadyr#,
			},
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Showa#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Ora de vară din Apia#,
				'generic' => q#Ora din Apia#,
				'standard' => q#Ora standard din Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Ora de vară a zonei Aqtau#,
				'generic' => q#Ora Aqtau#,
				'standard' => q#Ora standard Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Ora de vară a zonei Aqtobe#,
				'generic' => q#Ora Aqtobe#,
				'standard' => q#Ora standard Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ora de vară arabă#,
				'generic' => q#Ora arabă#,
				'standard' => q#Ora standard arabă#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ora de vară a Argentinei#,
				'generic' => q#Ora Argentinei#,
				'standard' => q#Ora standard a Argentinei#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ora de vară a Argentinei Occidentale#,
				'generic' => q#Ora Argentinei Occidentale#,
				'standard' => q#Ora standard a Argentinei Occidentale#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ora de vară a Armeniei#,
				'generic' => q#Ora Armeniei#,
				'standard' => q#Ora standard a Armeniei#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatî#,
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
			exemplarCity => q#Așgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atîrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bișkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Cita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasc#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dușanbe#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkuțk#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ierusalim#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamciatka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoiarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuweit#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznețk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Phenian#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Și Min#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tașkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Iakuțk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora de vară în zona Atlantic nord-americană#,
				'generic' => q#Ora zonei Atlantic nord-americane#,
				'standard' => q#Ora standard în zona Atlantic nord-americană#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azore#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canare#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Capul Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Feroe#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia de Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sf. Elena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora de vară a Australiei Centrale#,
				'generic' => q#Ora Australiei Centrale#,
				'standard' => q#Ora standard a Australiei Centrale#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora de vară a Australiei Central Occidentale#,
				'generic' => q#Ora Australiei Central Occidentale#,
				'standard' => q#Ora standard a Australiei Central Occidentale#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora de vară a Australiei Orientale#,
				'generic' => q#Ora Australiei Orientale#,
				'standard' => q#Ora standard a Australiei Orientale#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora de vară a Australiei Occidentale#,
				'generic' => q#Ora Australiei Occidentale#,
				'standard' => q#Ora standard a Australiei Occidentale#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ora de vară a Azerbaidjanului#,
				'generic' => q#Ora Azerbaidjanului#,
				'standard' => q#Ora standard a Azerbaidjanului#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora de vară din Azore#,
				'generic' => q#Ora din Azore#,
				'standard' => q#Ora standard din Azore#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ora de vară din Bangladesh#,
				'generic' => q#Ora din Bangladesh#,
				'standard' => q#Ora standard din Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ora Bhutanului#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ora Boliviei#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ora de vară a Brasiliei#,
				'generic' => q#Ora Brasiliei#,
				'standard' => q#Ora standard a Brasiliei#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ora din Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora de vară din Capul Verde#,
				'generic' => q#Ora din Capul Verde#,
				'standard' => q#Ora standard din Capul Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ora din Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ora de vară din Chatham#,
				'generic' => q#Ora din Chatham#,
				'standard' => q#Ora standard din Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ora de vară din Chile#,
				'generic' => q#Ora din Chile#,
				'standard' => q#Ora standard din Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ora de vară a Chinei#,
				'generic' => q#Ora Chinei#,
				'standard' => q#Ora standard a Chinei#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Ora de vară din Choibalsan#,
				'generic' => q#Ora din Choibalsan#,
				'standard' => q#Ora standard din Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ora din Insula Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ora Insulelor Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ora de vară a Columbiei#,
				'generic' => q#Ora Columbiei#,
				'standard' => q#Ora standard a Columbiei#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ora de vară a Insulelor Cook#,
				'generic' => q#Ora Insulelor Cook#,
				'standard' => q#Ora standard a Insulelor Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora de vară a Cubei#,
				'generic' => q#Ora Cubei#,
				'standard' => q#Ora standard a Cubei#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ora din Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ora din Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ora Timorului de Est#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ora de vară din Insula Paștelui#,
				'generic' => q#Ora din Insula Paștelui#,
				'standard' => q#Ora standard din Insula Paștelui#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ora Ecuadorului#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Timpul universal coordonat#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Oraș necunoscut#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#București#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapesta#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chișinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhaga#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ora de vară a Irlandei#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Insula Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabona#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#Ora de vară britanică#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscova#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorița#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ujhorod#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varșovia#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporoje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora de vară a Europei Centrale#,
				'generic' => q#Ora Europei Centrale#,
				'standard' => q#Ora standard a Europei Centrale#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora de vară a Europei de Est#,
				'generic' => q#Ora Europei de Est#,
				'standard' => q#Ora standard a Europei de Est#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ora Europei de Est îndepărtate#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora de vară a Europei de Vest#,
				'generic' => q#Ora Europei de Vest#,
				'standard' => q#Ora standard a Europei de Vest#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ora de vară din Insulele Falkland#,
				'generic' => q#Ora din Insulele Falkland#,
				'standard' => q#Ora standard din Insulele Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ora de vară din Fiji#,
				'generic' => q#Ora din Fiji#,
				'standard' => q#Ora standard din Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ora din Guyana Franceză#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ora din Teritoriile Australe și Antarctice Franceze#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora de Greenwhich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ora din Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ora din Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ora de vară a Georgiei#,
				'generic' => q#Ora Georgiei#,
				'standard' => q#Ora standard a Georgiei#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ora Insulelor Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora de vară a Groenlandei orientale#,
				'generic' => q#Ora Groenlandei orientale#,
				'standard' => q#Ora standard a Groenlandei orientale#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora de vară a Groenlandei occidentale#,
				'generic' => q#Ora Groenlandei occidentale#,
				'standard' => q#Ora standard a Groenlandei occidentale#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ora standard a Golfului#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ora din Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora de vară din Hawaii-Aleutine#,
				'generic' => q#Ora din Hawaii-Aleutine#,
				'standard' => q#Ora standard din Hawaii-Aleutine#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ora de vară din Hong Kong#,
				'generic' => q#Ora din Hong Kong#,
				'standard' => q#Ora standard din Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ora de vară din Hovd#,
				'generic' => q#Ora din Hovd#,
				'standard' => q#Ora standard din Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ora Indiei#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comore#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldive#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ora Oceanului Indian#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ora Indochinei#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ora Indoneziei Centrale#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ora Indoneziei de Est#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ora Indoneziei de Vest#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ora de vară a Iranului#,
				'generic' => q#Ora Iranului#,
				'standard' => q#Ora standard a Iranului#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ora de vară din Irkuțk#,
				'generic' => q#Ora din Irkuțk#,
				'standard' => q#Ora standard din Irkuțk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ora de vară a Israelului#,
				'generic' => q#Ora Israelului#,
				'standard' => q#Ora standard a Israelului#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ora de vară a Japoniei#,
				'generic' => q#Ora Japoniei#,
				'standard' => q#Ora standard a Japoniei#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Ora de vară din Petropavlovsk-Kamciațki#,
				'generic' => q#Ora din Petropavlovsk-Kamciațki#,
				'standard' => q#Ora standard din Petropavlovsk-Kamciațki#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ora din Kazahstanul de Est#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ora din Kazahstanul de Vest#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ora de vară a Coreei#,
				'generic' => q#Ora Coreei#,
				'standard' => q#Ora standard a Coreei#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ora din Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ora de vară din Krasnoiarsk#,
				'generic' => q#Ora din Krasnoiarsk#,
				'standard' => q#Ora standard din Krasnoiarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ora din Kârgâzstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ora din Insulele Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ora de vară din Lord Howe#,
				'generic' => q#Ora din Lord Howe#,
				'standard' => q#Ora standard din Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Ora din Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ora de vară din Magadan#,
				'generic' => q#Ora din Magadan#,
				'standard' => q#Ora standard din Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ora din Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ora din Maldive#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ora Insulelor Marchize#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ora Insulelor Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ora de vară din Mauritius#,
				'generic' => q#Ora din Mauritius#,
				'standard' => q#Ora standard din Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ora din Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ora de vară a Mexicului de nord-vest#,
				'generic' => q#Ora Mexicului de nord-vest#,
				'standard' => q#Ora standard a Mexicului de nord-vest#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora de vară a zonei Pacific mexicane#,
				'generic' => q#Ora zonei Pacific mexicane#,
				'standard' => q#Ora standard a zonei Pacific mexicane#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ora de vară din Ulan Bator#,
				'generic' => q#Ora din Ulan Bator#,
				'standard' => q#Ora standard din Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ora de vară a Moscovei#,
				'generic' => q#Ora Moscovei#,
				'standard' => q#Ora standard a Moscovei#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ora Myanmarului#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ora din Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ora Nepalului#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ora de vară a Noii Caledonii#,
				'generic' => q#Ora Noii Caledonii#,
				'standard' => q#Ora standard a Noii Caledonii#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ora de vară a Noii Zeelande#,
				'generic' => q#Ora Noii Zeelande#,
				'standard' => q#Ora standard a Noii Zeelande#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora de vară din Newfoundland#,
				'generic' => q#Ora din Newfoundland#,
				'standard' => q#Ora standard din Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ora din Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ora de vară a Insulei Norfolk#,
				'generic' => q#Ora Insulei Norfolk#,
				'standard' => q#Ora standard a Insulei Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ora de vară din Fernando de Noronha#,
				'generic' => q#Ora din Fernando de Noronha#,
				'standard' => q#Ora standard din Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ora de vară din Novosibirsk#,
				'generic' => q#Ora din Novosibirsk#,
				'standard' => q#Ora standard din Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ora de vară din Omsk#,
				'generic' => q#Ora din Omsk#,
				'standard' => q#Ora standard din Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Insula Paștelui#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marchize#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Insula Pitcairn#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ora de vară a Pakistanului#,
				'generic' => q#Ora Pakistanului#,
				'standard' => q#Ora standard a Pakistanului#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ora din Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ora din Papua Noua Guinee#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ora de vară din Paraguay#,
				'generic' => q#Ora din Paraguay#,
				'standard' => q#Ora standard din Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ora de vară din Peru#,
				'generic' => q#Ora din Peru#,
				'standard' => q#Ora standard din Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ora de vară din Filipine#,
				'generic' => q#Ora din Filipine#,
				'standard' => q#Ora standard din Filipine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ora Insulelor Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora de vară din Saint-Pierre și Miquelon#,
				'generic' => q#Ora din Saint-Pierre și Miquelon#,
				'standard' => q#Ora standard din Saint-Pierre și Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ora din Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ora din Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ora din Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ora din Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ora din Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ora de vară din Sahalin#,
				'generic' => q#Ora din Sahalin#,
				'standard' => q#Ora standard din Sahalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Ora de vară din Samara#,
				'generic' => q#Ora din Samara#,
				'standard' => q#Ora standard din Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ora de vară din Samoa#,
				'generic' => q#Ora din Samoa#,
				'standard' => q#Ora standard din Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ora din Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ora din Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ora Insulelor Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ora Georgiei de Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ora Surinamului#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ora din Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ora din Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ora de vară din Taipei#,
				'generic' => q#Ora din Taipei#,
				'standard' => q#Ora standard din Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ora din Tadjikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ora din Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ora de vară din Tonga#,
				'generic' => q#Ora din Tonga#,
				'standard' => q#Ora standard din Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ora din Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ora de vară din Turkmenistan#,
				'generic' => q#Ora din Turkmenistan#,
				'standard' => q#Ora standard din Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ora din Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ora de vară a Uruguayului#,
				'generic' => q#Ora Uruguayului#,
				'standard' => q#Ora standard a Uruguayului#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ora de vară din Uzbekistan#,
				'generic' => q#Ora din Uzbekistan#,
				'standard' => q#Ora standard din Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ora de vară din Vanuatu#,
				'generic' => q#Ora din Vanuatu#,
				'standard' => q#Ora standard din Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ora Venezuelei#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ora de vară din Vladivostok#,
				'generic' => q#Ora din Vladivostok#,
				'standard' => q#Ora standard din Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ora de vară din Volgograd#,
				'generic' => q#Ora din Volgograd#,
				'standard' => q#Ora standard din Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ora din Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ora Insulei Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ora din Wallis și Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ora de vară din Iakuțk#,
				'generic' => q#Ora din Iakuțk#,
				'standard' => q#Ora standard din Iakuțk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ora de vară din Ekaterinburg#,
				'generic' => q#Ora din Ekaterinburg#,
				'standard' => q#Ora standard din Ekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora din Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
