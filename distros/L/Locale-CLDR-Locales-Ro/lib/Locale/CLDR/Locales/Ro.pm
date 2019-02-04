=encoding utf8

=head1

Locale::CLDR::Locales::Ro - Package for language Romanian

=cut

package Locale::CLDR::Locales::Ro;
# This file auto generated from Data\common\main\ro.xml
#	on Sun  3 Feb  2:14:55 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
		use bignum;
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
 				'av' => 'avară',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azeră',
 				'az@alt=short' => 'azeră',
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
 				'co' => 'corsicană',
 				'cop' => 'coptă',
 				'cr' => 'cree',
 				'crh' => 'turcă crimeeană',
 				'crs' => 'creolă franceză seselwa',
 				'cs' => 'cehă',
 				'csb' => 'cașubiană',
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
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finlandeză',
 				'fil' => 'filipineză',
 				'fj' => 'fijiană',
 				'fo' => 'faroeză',
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
 				'he' => 'ebraică',
 				'hi' => 'hindi',
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
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laoțiană',
 				'lol' => 'mongo',
 				'lou' => 'creolă (Louisiana)',
 				'loz' => 'lozi',
 				'lrc' => 'luri de nord',
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
 				'pl' => 'poloneză',
 				'pon' => 'pohnpeiană',
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
 				'rm' => 'romanșă',
 				'rn' => 'kirundi',
 				'ro' => 'română',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'root',
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
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadjică',
 				'th' => 'thailandeză',
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
 				'tpi' => 'tok pisin',
 				'tr' => 'turcă',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tătară',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiană',
 				'tyv' => 'tuvană',
 				'tzm' => 'tamazight din Altasul Central',
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
 				'yue' => 'cantoneză',
 				'za' => 'zhuang',
 				'zap' => 'zapotecă',
 				'zbl' => 'simboluri Bilss',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight standard marocană',
 				'zh' => 'chineză',
 				'zh_Hans' => 'chineză simplificată',
 				'zh_Hant' => 'chineză tradițională',
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
			'Arab' => 'arabă',
 			'Arab@alt=variant' => 'persano-arabă',
 			'Armn' => 'armeană',
 			'Bali' => 'balineză',
 			'Beng' => 'bengaleză',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Cans' => 'silabică aborigenă canadiană unificată',
 			'Copt' => 'coptă',
 			'Cprt' => 'cipriotă',
 			'Cyrl' => 'chirilică',
 			'Cyrs' => 'chirilică slavonă bisericească veche',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'mormonă',
 			'Egyd' => 'demotică egipteană',
 			'Egyh' => 'hieratică egipteană',
 			'Egyp' => 'hieroglife egiptene',
 			'Ethi' => 'etiopiană',
 			'Geok' => 'georgiană bisericească',
 			'Geor' => 'georgiană',
 			'Glag' => 'glagolitică',
 			'Goth' => 'gotică',
 			'Grek' => 'greacă',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'simplificată',
 			'Hans@alt=stand-alone' => 'han simplificată',
 			'Hant' => 'tradițională',
 			'Hant@alt=stand-alone' => 'han tradițională',
 			'Hebr' => 'ebraică',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'silabică japoneză',
 			'Hung' => 'maghiară veche',
 			'Inds' => 'indus',
 			'Ital' => 'italică veche',
 			'Jamo' => 'jamo',
 			'Java' => 'javaneză',
 			'Jpan' => 'japoneză',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmeră',
 			'Knda' => 'kannada',
 			'Kore' => 'coreeană',
 			'Laoo' => 'laoțiană',
 			'Latf' => 'latină Fraktur',
 			'Latg' => 'latină gaelică',
 			'Latn' => 'latină',
 			'Lina' => 'lineară A',
 			'Linb' => 'lineară B',
 			'Lydi' => 'lidiană',
 			'Maya' => 'hieroglife maya',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolă',
 			'Mymr' => 'birmană',
 			'Orya' => 'oriya',
 			'Phnx' => 'feniciană',
 			'Runr' => 'runică',
 			'Sinh' => 'singaleză',
 			'Syrc' => 'siriacă',
 			'Syrj' => 'siriacă occidentală',
 			'Syrn' => 'siriacă orientală',
 			'Taml' => 'tamilă',
 			'Telu' => 'telugu',
 			'Tfng' => 'berberă',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandeză',
 			'Tibt' => 'tibetană',
 			'Xpeo' => 'persană veche',
 			'Xsux' => 'cuneiformă sumero-akkadiană',
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
 			'GB@alt=short' => 'Regatul Unit',
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
 			'HK' => 'R.A.S. Hong Kong a Chinei',
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
 			'MK' => 'Republica Macedonia',
 			'MK@alt=variant' => 'Republica Macedonia (FRIM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'R.A.S. Macao a Chinei',
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
 			'ST' => 'Sao Tome și Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint-Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Swaziland',
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
 			'AREVELA' => 'armeană orientală',
 			'AREVMDA' => 'armeană occidentală',
 			'BAKU1926' => 'alfabet latin altaic unificat',
 			'BISKE' => 'dialect San Giorgio/Bila',
 			'BOONT' => 'boontling',
 			'FONIPA' => 'alfabet fonetic internațional',
 			'FONUPA' => 'alfabet fonetic uralic',
 			'KKCOR' => 'ortografie comuna cornish',
 			'LIPAW' => 'dialect lipovaz din resiană',
 			'MONOTON' => 'monotonică',
 			'NEDIS' => 'dialect Natisone',
 			'NJIVA' => 'dialect Gniva/Njiva',
 			'OSOJS' => 'dialect Oseacco/Osojane',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'politonică',
 			'POSIX' => 'informantică',
 			'REVISED' => 'ortografie revizuită',
 			'ROZAJ' => 'dialect resian',
 			'SAAHO' => 'dialect saho',
 			'SCOTLAND' => 'engleză standard scoțiană',
 			'SCOUSE' => 'dialect scouse',
 			'SOLBA' => 'dialet Stolvizza/Solbica',
 			'TARASK' => 'ortografie taraskievica',
 			'UCCOR' => 'ortografie unificată cornish',
 			'UCRCOR' => 'ortografie revizuită unificată cornish',
 			'VALENCIA' => 'valenciană',
 			'WADEGILE' => 'Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'calendar',
 			'cf' => 'Format monedă',
 			'colalternate' => 'Ordonare cu simbolurile ignorate',
 			'colbackwards' => 'Ordonare inversă după accent',
 			'colcasefirst' => 'Ordonare după majuscule/minuscule',
 			'colcaselevel' => 'Ordonare care ține seama de majuscule/minuscule',
 			'collation' => 'ordine de sortare',
 			'colnormalization' => 'Ordonare normalizată',
 			'colnumeric' => 'Ordonare numerică',
 			'colstrength' => 'Puterea ordonării',
 			'currency' => 'monedă',
 			'hc' => 'ciclu orar (12 sau 24)',
 			'lb' => 'stil de întrerupere a liniei',
 			'ms' => 'sistem de unități de măsură',
 			'numbers' => 'numere',
 			'timezone' => 'Fusul orar',
 			'va' => 'Varianta locală',
 			'x' => 'Utilizare privată',

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
 				'ethiopic-amete-alem' => q{Calendarul etiopian amete alem},
 				'gregorian' => q{calendar gregorian},
 				'hebrew' => q{calendar ebraic},
 				'indian' => q{calendar național indian},
 				'islamic' => q{calendar islamic},
 				'islamic-civil' => q{calendar islamic civil},
 				'islamic-umalqura' => q{calendar islamic (Umm al-Qura)},
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
 				'big5han' => q{sortare pentru chineza tradițională - Big5},
 				'compat' => q{ordine de sortare anterioară, pentru compatibilitate},
 				'dictionary' => q{Ordine de sortare a dicționarului},
 				'ducet' => q{ordine de sortare Unicode implicită},
 				'eor' => q{regulile europene de sortare},
 				'gb2312han' => q{sortare pentru chineza simplificată - GB2312},
 				'phonebook' => q{sortare după cartea de telefon},
 				'phonetic' => q{Tip de ordonare fonetică},
 				'pinyin' => q{sortare pinyin},
 				'reformed' => q{Ordine de sortare reformată},
 				'search' => q{căutare cu scop general},
 				'searchjl' => q{Căutați în funcție de consoana inițială hangul},
 				'standard' => q{ordine de sortare standard},
 				'stroke' => q{ordine de sortare după trasare},
 				'traditional' => q{sortare tradițională},
 				'unihan' => q{Ordine de sortare a liniilor ideogramelor},
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
 				'arab' => q{cifre indo-arabe},
 				'arabext' => q{cifre indo-arabe extinse},
 				'armn' => q{numerale armenești},
 				'armnlow' => q{numerale armenești cu minuscule},
 				'beng' => q{cifre bengaleze},
 				'deva' => q{cifre devanagari},
 				'ethi' => q{numerale etiopiene},
 				'finance' => q{Sistemul numeric financiar},
 				'fullwide' => q{cifre cu lățimea întreagă},
 				'geor' => q{numerale georgiene},
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
 				'jpan' => q{numerale japoneze},
 				'jpanfin' => q{numerale financiare japoneze},
 				'khmr' => q{cifre khmere},
 				'knda' => q{cifre kannada},
 				'laoo' => q{cifre laoțiene},
 				'latn' => q{cifre occidentale},
 				'mlym' => q{cifre malayalam},
 				'mong' => q{Cifre mongole},
 				'mymr' => q{cifre birmaneze},
 				'native' => q{Cifre native},
 				'orya' => q{cifre oriya},
 				'roman' => q{numerale romane},
 				'romanlow' => q{numerale romane cu minuscule},
 				'taml' => q{numerale tradiționale tamile},
 				'tamldec' => q{cifre tamile},
 				'telu' => q{cifre telugu},
 				'thai' => q{cifre thailandeze},
 				'tibt' => q{cifre tibetane},
 				'traditional' => q{Numere tradiționale},
 				'vaii' => q{Cifre Vai},
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
			auxiliary => qr{[á à å ä ç é è ê ë ñ ö q ş ţ ü]},
			index => ['A', 'Ă', 'Â', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ș', 'T', 'Ț', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a ă â b c d e f g h i î j k l m n o p r s ș t ț u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ " “ ” „ « » ( ) \[ \] @ * /]},
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
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0} … {1}',
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
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
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
						'name' => q(punct cardinal),
					},
					'acre' => {
						'few' => q({0} acri),
						'name' => q(acri),
						'one' => q({0} acru),
						'other' => q({0} de acri),
					},
					'acre-foot' => {
						'few' => q({0} acru-picioare),
						'name' => q(acru-picioare),
						'one' => q({0} acru-picior),
						'other' => q({0} de acru-picioare),
					},
					'ampere' => {
						'few' => q({0} amperi),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} de amperi),
					},
					'arc-minute' => {
						'few' => q({0} minute de arc),
						'name' => q(minute de arc),
						'one' => q({0} minut de arc),
						'other' => q({0} de minute de arc),
					},
					'arc-second' => {
						'few' => q({0} secunde de arc),
						'name' => q(secunde de arc),
						'one' => q({0} secundă de arc),
						'other' => q({0} de secunde de arc),
					},
					'astronomical-unit' => {
						'few' => q({0} unități astronomice),
						'name' => q(unități astronomice),
						'one' => q({0} unitate astronomică),
						'other' => q({0} de unități astronomice),
					},
					'atmosphere' => {
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosferă),
						'other' => q({0} de atmosfere),
					},
					'bit' => {
						'few' => q({0} biți),
						'name' => q(biți),
						'one' => q({0} bit),
						'other' => q({0} de biți),
					},
					'byte' => {
						'few' => q({0} byți),
						'name' => q(byți),
						'one' => q({0} byte),
						'other' => q({0} de byți),
					},
					'calorie' => {
						'few' => q({0} calorii),
						'name' => q(calorii),
						'one' => q({0} calorie),
						'other' => q({0} de calorii),
					},
					'carat' => {
						'few' => q({0} carate),
						'name' => q(carate),
						'one' => q({0} carat),
						'other' => q({0} de carate),
					},
					'celsius' => {
						'few' => q({0} grade Celsius),
						'name' => q(grade Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} de grade Celsius),
					},
					'centiliter' => {
						'few' => q({0} centilitri),
						'name' => q(centilitri),
						'one' => q({0} centilitru),
						'other' => q({0} de centilitri),
					},
					'centimeter' => {
						'few' => q({0} centimetri),
						'name' => q(centimetri),
						'one' => q({0} centimetru),
						'other' => q({0} de centimetri),
						'per' => q({0} pe centimetru),
					},
					'century' => {
						'few' => q({0} secole),
						'name' => q(secole),
						'one' => q({0} secol),
						'other' => q({0} de secole),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					'cubic-centimeter' => {
						'few' => q({0} centimetri cubi),
						'name' => q(centimetri cubi),
						'one' => q({0} centimetru cub),
						'other' => q({0} de centimetri cubi),
						'per' => q({0} pe centimetru cub),
					},
					'cubic-foot' => {
						'few' => q({0} picioare cubice),
						'name' => q(picioare cubice),
						'one' => q({0} picior cubic),
						'other' => q({0} de picioare cubice),
					},
					'cubic-inch' => {
						'few' => q({0} inchi cubici),
						'name' => q(inchi cubici),
						'one' => q({0} inch cubic),
						'other' => q({0} de inchi cubici),
					},
					'cubic-kilometer' => {
						'few' => q({0} kilometri cubi),
						'name' => q(kilometri cubi),
						'one' => q({0} kilometru cub),
						'other' => q({0} de kilometri cubi),
					},
					'cubic-meter' => {
						'few' => q({0} metri cubi),
						'name' => q(metri cubi),
						'one' => q({0} metru cub),
						'other' => q({0} de metri cubi),
						'per' => q({0} pe metru cub),
					},
					'cubic-mile' => {
						'few' => q({0} mile cubice),
						'name' => q(mile cubice),
						'one' => q({0} milă cubică),
						'other' => q({0} de mile cubice),
					},
					'cubic-yard' => {
						'few' => q({0} iarzi cubici),
						'name' => q(iarzi cubici),
						'one' => q({0} iard cubic),
						'other' => q({0} de iarzi cubici),
					},
					'cup' => {
						'few' => q({0} căni),
						'name' => q(căni),
						'one' => q({0} cană),
						'other' => q({0} de căni),
					},
					'cup-metric' => {
						'few' => q({0} căni metrice),
						'name' => q(căni metrice),
						'one' => q({0} cană metrică),
						'other' => q({0} de căni metrice),
					},
					'day' => {
						'few' => q({0} zile),
						'name' => q(zile),
						'one' => q({0} zi),
						'other' => q({0} de zile),
						'per' => q({0} pe zi),
					},
					'deciliter' => {
						'few' => q({0} decilitri),
						'name' => q(decilitri),
						'one' => q({0} decilitru),
						'other' => q({0} de decilitri),
					},
					'decimeter' => {
						'few' => q({0} decimetri),
						'name' => q(decimetri),
						'one' => q({0} decimetru),
						'other' => q({0} de decimetri),
					},
					'degree' => {
						'few' => q({0} grade),
						'name' => q(grade),
						'one' => q({0} grad),
						'other' => q({0} de grade),
					},
					'fahrenheit' => {
						'few' => q({0} grade Fahrenheit),
						'name' => q(grade Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} de grade Fahrenheit),
					},
					'fluid-ounce' => {
						'few' => q({0} uncii lichide),
						'name' => q(uncii lichide),
						'one' => q({0} uncie lichidă),
						'other' => q({0} de uncii lichide),
					},
					'foodcalorie' => {
						'few' => q({0} kilocalorii),
						'name' => q(kilocalorii),
						'one' => q({0} kilocalorie),
						'other' => q({0} de kilocalorii),
					},
					'foot' => {
						'few' => q({0} picioare),
						'name' => q(picioare),
						'one' => q({0} picior),
						'other' => q({0} de picioare),
						'per' => q({0} pe picior),
					},
					'g-force' => {
						'few' => q({0} forță g),
						'name' => q(forță g),
						'one' => q({0} forță g),
						'other' => q({0} forță g),
					},
					'gallon' => {
						'few' => q({0} galoane),
						'name' => q(galoane),
						'one' => q({0} galon),
						'other' => q({0} de galoane),
						'per' => q({0} per galon),
					},
					'gallon-imperial' => {
						'few' => q({0} galoane imperiale),
						'name' => q(galoane imperiale),
						'one' => q({0} galon imperial),
						'other' => q({0} de galoane imperiale),
						'per' => q({0} pe galon imperial),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} gigabiți),
						'name' => q(gigabiți),
						'one' => q({0} gigabit),
						'other' => q({0} de gigabiți),
					},
					'gigabyte' => {
						'few' => q({0} gigabyți),
						'name' => q(gigabyți),
						'one' => q({0} gigabyte),
						'other' => q({0} de gigabyți),
					},
					'gigahertz' => {
						'few' => q({0} gigahertzi),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} de gigahertzi),
					},
					'gigawatt' => {
						'few' => q({0} gigawați),
						'name' => q(gigawați),
						'one' => q({0} gigawatt),
						'other' => q({0} de gigawați),
					},
					'gram' => {
						'few' => q({0} grame),
						'name' => q(grame),
						'one' => q({0} gram),
						'other' => q({0} de grame),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'few' => q({0} hectare),
						'name' => q(hectare),
						'one' => q({0} hectar),
						'other' => q({0} de hectare),
					},
					'hectoliter' => {
						'few' => q({0} hectolitri),
						'name' => q(hectolitri),
						'one' => q({0} hectolitru),
						'other' => q({0} de hectolitri),
					},
					'hectopascal' => {
						'few' => q({0} hectopascali),
						'name' => q(hectopascali),
						'one' => q({0} hectopascal),
						'other' => q({0} de hectopascali),
					},
					'hertz' => {
						'few' => q({0} hertzi),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} de hertzi),
					},
					'horsepower' => {
						'few' => q({0} cai putere),
						'name' => q(cai putere),
						'one' => q({0} cal putere),
						'other' => q({0} de cai putere),
					},
					'hour' => {
						'few' => q({0} ore),
						'name' => q(ore),
						'one' => q({0} oră),
						'other' => q({0} de ore),
						'per' => q({0} pe oră),
					},
					'inch' => {
						'few' => q({0} inchi),
						'name' => q(inchi),
						'one' => q({0} inch),
						'other' => q({0} de inchi),
						'per' => q({0} pe inch),
					},
					'inch-hg' => {
						'few' => q({0} inchi coloană de mercur),
						'name' => q(inchi coloană de mercur),
						'one' => q({0} inch coloană de mercur),
						'other' => q({0} de inchi coloană de mercur),
					},
					'joule' => {
						'few' => q({0} jouli),
						'name' => q(jouli),
						'one' => q({0} joule),
						'other' => q({0} de jouli),
					},
					'karat' => {
						'few' => q({0} karate),
						'name' => q(karate),
						'one' => q({0} karată),
						'other' => q({0} de karate),
					},
					'kelvin' => {
						'few' => q({0} kelvini),
						'name' => q(kelvini),
						'one' => q({0} kelvin),
						'other' => q({0} de kelvini),
					},
					'kilobit' => {
						'few' => q({0} kilobiți),
						'name' => q(kilobiți),
						'one' => q({0} kilobit),
						'other' => q({0} de kilobiți),
					},
					'kilobyte' => {
						'few' => q({0} kilobyți),
						'name' => q(kilobyți),
						'one' => q({0} kilobyte),
						'other' => q({0} de kilobyți),
					},
					'kilocalorie' => {
						'few' => q({0} kilocalorii),
						'name' => q(kilocalorii),
						'one' => q({0} kilocalorie),
						'other' => q({0} de kilocalorii),
					},
					'kilogram' => {
						'few' => q({0} kilograme),
						'name' => q(kilograme),
						'one' => q({0} kilogram),
						'other' => q({0} de kilograme),
						'per' => q({0} per kilogram),
					},
					'kilohertz' => {
						'few' => q({0} kilohertzi),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} de kilohertzi),
					},
					'kilojoule' => {
						'few' => q({0} kilojouli),
						'name' => q(kilojouli),
						'one' => q({0} kilojoule),
						'other' => q({0} de kilojouli),
					},
					'kilometer' => {
						'few' => q({0} kilometri),
						'name' => q(kilometri),
						'one' => q({0} kilometru),
						'other' => q({0} de kilometri),
						'per' => q({0} pe kilometru),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometri pe oră),
						'name' => q(kilometri pe oră),
						'one' => q({0} kilometru pe oră),
						'other' => q({0} de kilometri pe oră),
					},
					'kilowatt' => {
						'few' => q({0} kilowați),
						'name' => q(kilowați),
						'one' => q({0} kilowatt),
						'other' => q({0} de kilowați),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilowați-oră),
						'name' => q(kilowați-oră),
						'one' => q(kilowatt-oră),
						'other' => q({0} de kilowați-oră),
					},
					'knot' => {
						'few' => q({0} noduri),
						'name' => q(nod),
						'one' => q({0} nod),
						'other' => q({0} de noduri),
					},
					'light-year' => {
						'few' => q({0} ani lumină),
						'name' => q(ani lumină),
						'one' => q({0} an lumină),
						'other' => q({0} de ani lumină),
					},
					'liter' => {
						'few' => q({0} litri),
						'name' => q(litri),
						'one' => q({0} litru),
						'other' => q({0} de litri),
						'per' => q({0} pe litru),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} litri la suta de kilometri),
						'name' => q(litri la suta de kilometri),
						'one' => q({0} litru la suta de kilometri),
						'other' => q({0} de litri la suta de kilometri),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litri pe kilometru),
						'name' => q(litri pe kilometru),
						'one' => q({0} litru pe kilometru),
						'other' => q({0} de litri pe kilometru),
					},
					'lux' => {
						'few' => q({0} lucși),
						'name' => q(lucși),
						'one' => q({0} lux),
						'other' => q({0} de lucși),
					},
					'megabit' => {
						'few' => q({0} megabiți),
						'name' => q(megabiți),
						'one' => q({0} megabit),
						'other' => q({0} de megabiți),
					},
					'megabyte' => {
						'few' => q({0} megabyți),
						'name' => q(megabyți),
						'one' => q({0} megabyte),
						'other' => q({0} de megabyți),
					},
					'megahertz' => {
						'few' => q({0} megahertzi),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} de megahertzi),
					},
					'megaliter' => {
						'few' => q({0} megalitri),
						'name' => q(megalitri),
						'one' => q({0} megalitru),
						'other' => q({0} megalitri),
					},
					'megawatt' => {
						'few' => q({0} megawați),
						'name' => q(megawați),
						'one' => q({0} megawatt),
						'other' => q({0} de megawați),
					},
					'meter' => {
						'few' => q({0} metri),
						'name' => q(metri),
						'one' => q({0} metru),
						'other' => q({0} de metri),
						'per' => q({0} pe metru),
					},
					'meter-per-second' => {
						'few' => q({0} metri pe secundă),
						'name' => q(metri pe secundă),
						'one' => q({0} metru pe secundă),
						'other' => q({0} de metri pe secundă),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metri pe secundă la pătrat),
						'name' => q(metri pe secundă la pătrat),
						'one' => q({0} metru pe secundă la pătrat),
						'other' => q({0} de metri pe secundă la pătrat),
					},
					'metric-ton' => {
						'few' => q({0} tone),
						'name' => q(tone),
						'one' => q({0} tonă),
						'other' => q({0} de tone),
					},
					'microgram' => {
						'few' => q({0} micrograme),
						'name' => q(micrograme),
						'one' => q({0} microgram),
						'other' => q({0} de micrograme),
					},
					'micrometer' => {
						'few' => q({0} micrometri),
						'name' => q(micrometri),
						'one' => q({0} micrometru),
						'other' => q({0} de micrometri),
					},
					'microsecond' => {
						'few' => q({0} microsecunde),
						'name' => q(microsecunde),
						'one' => q({0} microsecundă),
						'other' => q({0} de microsecunde),
					},
					'mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} milă),
						'other' => q({0} de mile),
					},
					'mile-per-gallon' => {
						'few' => q({0} mile pe galon),
						'name' => q(mile pe galon),
						'one' => q({0} milă pe galon),
						'other' => q({0} de mile pe galon),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} mile pe galon imperial),
						'name' => q(mile pe galon imperial),
						'one' => q({0} milă pe galon imperial),
						'other' => q({0} de mile pe galon imperial),
					},
					'mile-per-hour' => {
						'few' => q({0} mile pe oră),
						'name' => q(mile pe oră),
						'one' => q({0} milă pe oră),
						'other' => q({0} de mile pe oră),
					},
					'mile-scandinavian' => {
						'few' => q({0} mile scandinave),
						'name' => q(milă scandinavă),
						'one' => q({0} milă scandinavă),
						'other' => q({0} de mile scandinave),
					},
					'milliampere' => {
						'few' => q({0} miliamperi),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} de miliamperi),
					},
					'millibar' => {
						'few' => q({0} milibari),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} de milibari),
					},
					'milligram' => {
						'few' => q({0} miligrame),
						'name' => q(miligrame),
						'one' => q({0} miligram),
						'other' => q({0} de miligrame),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} miligrame pe decilitru),
						'name' => q(miligrame pe decilitru),
						'one' => q({0} miligram pe decilitru),
						'other' => q({0} de miligrame pe decilitru),
					},
					'milliliter' => {
						'few' => q({0} mililitri),
						'name' => q(mililitri),
						'one' => q({0} mililitru),
						'other' => q({0} de mililitri),
					},
					'millimeter' => {
						'few' => q({0} milimetri),
						'name' => q(milimetri),
						'one' => q({0} milimetru),
						'other' => q({0} de milimetri),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetri coloană de mercur),
						'name' => q(milimetri coloană de mercur),
						'one' => q({0} milimetru coloană de mercur),
						'other' => q({0} de milimetri coloană de mercur),
					},
					'millimole-per-liter' => {
						'few' => q({0} milimoli pe litru),
						'name' => q(milimoli pe litru),
						'one' => q({0} milimol pe litru),
						'other' => q({0} de milimoli pe litru),
					},
					'millisecond' => {
						'few' => q({0} milisecunde),
						'name' => q(milisecunde),
						'one' => q({0} milisecundă),
						'other' => q({0} de milisecunde),
					},
					'milliwatt' => {
						'few' => q({0} miliwați),
						'name' => q(miliwați),
						'one' => q({0} miliwatt),
						'other' => q({0} de miliwați),
					},
					'minute' => {
						'few' => q({0} minute),
						'name' => q(minute),
						'one' => q({0} minut),
						'other' => q({0} de minute),
						'per' => q({0} pe minut),
					},
					'month' => {
						'few' => q({0} luni),
						'name' => q(luni),
						'one' => q({0} lună),
						'other' => q({0} de luni),
						'per' => q({0} pe lună),
					},
					'nanometer' => {
						'few' => q({0} nanometri),
						'name' => q(nanometri),
						'one' => q({0} nanometru),
						'other' => q({0} de nanometri),
					},
					'nanosecond' => {
						'few' => q({0} nanosecunde),
						'name' => q(nanosecunde),
						'one' => q({0} nanosecundă),
						'other' => q({0} de nanosecunde),
					},
					'nautical-mile' => {
						'few' => q({0} mile nautice),
						'name' => q(mile nautice),
						'one' => q({0} milă nautică),
						'other' => q({0} de mile nautice),
					},
					'ohm' => {
						'few' => q({0} ohmi),
						'name' => q(ohmi),
						'one' => q({0} ohm),
						'other' => q({0} de ohmi),
					},
					'ounce' => {
						'few' => q({0} uncii),
						'name' => q(uncii),
						'one' => q({0} uncie),
						'other' => q({0} de uncii),
						'per' => q({0} per uncie),
					},
					'ounce-troy' => {
						'few' => q({0} uncii monetare),
						'name' => q(uncii monetare),
						'one' => q({0} uncie monetară),
						'other' => q({0} de uncii monetare),
					},
					'parsec' => {
						'few' => q({0} parseci),
						'name' => q(parseci),
						'one' => q({0} parsec),
						'other' => q({0} de parseci),
					},
					'part-per-million' => {
						'few' => q({0} părți pe milion),
						'name' => q(părți pe milion),
						'one' => q({0} parte pe milion),
						'other' => q({0} de părți pe milion),
					},
					'per' => {
						'1' => q({0} pe {1}),
					},
					'percent' => {
						'few' => q({0} procente),
						'name' => q(procent),
						'one' => q({0} procent),
						'other' => q({0} de procente),
					},
					'permille' => {
						'few' => q({0} la mie),
						'name' => q(‰),
						'one' => q(la mie),
						'other' => q({0} la mie),
					},
					'petabyte' => {
						'few' => q({0} petabyți),
						'name' => q(petabyți),
						'one' => q({0} petabyte),
						'other' => q({0} de petabyți),
					},
					'picometer' => {
						'few' => q({0} picometri),
						'name' => q(picometri),
						'one' => q({0} picometru),
						'other' => q({0} de picometri),
					},
					'pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pintă),
						'other' => q({0} de pinte),
					},
					'pint-metric' => {
						'few' => q({0} pinte metrice),
						'name' => q(pinte metrice),
						'one' => q({0} pintă metrică),
						'other' => q({0} de pinte metrice),
					},
					'point' => {
						'few' => q({0} puncte),
						'name' => q(puncte),
						'one' => q({0} punct),
						'other' => q({0} de puncte),
					},
					'pound' => {
						'few' => q({0} livre),
						'name' => q(livre),
						'one' => q({0} livră),
						'other' => q({0} de livre),
						'per' => q({0} per livră),
					},
					'pound-per-square-inch' => {
						'few' => q({0} livre pe inch pătrat),
						'name' => q(livre pe inch pătrat),
						'one' => q({0} livră pe inch pătrat),
						'other' => q({0} de livre pe inch pătrat),
					},
					'quart' => {
						'few' => q({0} quarte),
						'name' => q(quarte),
						'one' => q({0} quart),
						'other' => q({0} de quarte),
					},
					'radian' => {
						'few' => q({0} radiani),
						'name' => q(radiani),
						'one' => q({0} radian),
						'other' => q({0} de radiani),
					},
					'revolution' => {
						'few' => q({0} revoluții),
						'name' => q(revoluție),
						'one' => q({0} revoluție),
						'other' => q({0} de revoluții),
					},
					'second' => {
						'few' => q({0} secunde),
						'name' => q(secunde),
						'one' => q({0} secundă),
						'other' => q({0} de secunde),
						'per' => q({0} pe secundă),
					},
					'square-centimeter' => {
						'few' => q({0} centimetri pătrați),
						'name' => q(centimetri pătrați),
						'one' => q({0} centimetru pătrat),
						'other' => q({0} de centimetri pătrați),
						'per' => q({0} pe centimetru pătrat),
					},
					'square-foot' => {
						'few' => q({0} picioare pătrate),
						'name' => q(picioare pătrate),
						'one' => q({0} picior pătrat),
						'other' => q({0} de picioare pătrate),
					},
					'square-inch' => {
						'few' => q({0} inchi pătrați),
						'name' => q(inchi pătrați),
						'one' => q({0} inch pătrat),
						'other' => q({0} de inchi pătrați),
						'per' => q({0} pe inchi pătrat),
					},
					'square-kilometer' => {
						'few' => q({0} kilometri pătrați),
						'name' => q(kilometri pătrați),
						'one' => q({0} kilometru pătrat),
						'other' => q({0} de kilometri pătrați),
						'per' => q({0} pe kilometru pătrat),
					},
					'square-meter' => {
						'few' => q({0} metri pătrați),
						'name' => q(metri pătrați),
						'one' => q({0} metru pătrat),
						'other' => q({0} de metri pătrați),
						'per' => q({0} pe metru pătrat),
					},
					'square-mile' => {
						'few' => q({0} mile pătrate),
						'name' => q(mile pătrate),
						'one' => q({0} milă pătrată),
						'other' => q({0} de mile pătrate),
						'per' => q({0} pe milă pătrată),
					},
					'square-yard' => {
						'few' => q({0} iarzi pătrați),
						'name' => q(iarzi pătrați),
						'one' => q({0} iard pătrat),
						'other' => q({0} de iarzi pătrați),
					},
					'tablespoon' => {
						'few' => q({0} linguri),
						'name' => q(linguri),
						'one' => q({0} lingură),
						'other' => q({0} de linguri),
					},
					'teaspoon' => {
						'few' => q({0} lingurițe),
						'name' => q(lingurițe),
						'one' => q({0} linguriță),
						'other' => q({0} de lingurițe),
					},
					'terabit' => {
						'few' => q({0} terabiți),
						'name' => q(terabiți),
						'one' => q({0} terabit),
						'other' => q({0} de terabiți),
					},
					'terabyte' => {
						'few' => q({0} terabyți),
						'name' => q(terabyți),
						'one' => q({0} terabyte),
						'other' => q({0} de terabyți),
					},
					'ton' => {
						'few' => q({0} tone scurte),
						'name' => q(tone scurte),
						'one' => q({0} tonă scurtă),
						'other' => q({0} de tone scurte),
					},
					'volt' => {
						'few' => q({0} volți),
						'name' => q(volți),
						'one' => q({0} volt),
						'other' => q({0} de volți),
					},
					'watt' => {
						'few' => q({0} wați),
						'name' => q(wați),
						'one' => q({0} watt),
						'other' => q({0} de wați),
					},
					'week' => {
						'few' => q({0} săptămâni),
						'name' => q(săptămâni),
						'one' => q({0} săptămână),
						'other' => q({0} de săptămâni),
						'per' => q({0} pe săptămână),
					},
					'yard' => {
						'few' => q({0} iarzi),
						'name' => q(iarzi),
						'one' => q({0} iard),
						'other' => q({0} de iarzi),
					},
					'year' => {
						'few' => q({0} ani),
						'name' => q(ani),
						'one' => q({0} an),
						'other' => q({0} de ani),
						'per' => q({0} pe an),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(direcție),
					},
					'acre' => {
						'few' => q({0} ac.),
						'one' => q({0} ac.),
						'other' => q({0} ac.),
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
						'few' => q({0} ua),
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'carat' => {
						'few' => q({0} ct),
						'name' => q(carate),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'few' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'few' => q({0} sec.),
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
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
						'few' => q({0} z),
						'name' => q(zi),
						'one' => q({0} z),
						'other' => q({0} z),
						'per' => q({0}/zi),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'name' => q(dm),
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
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'few' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'generic' => {
						'few' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
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
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'few' => q({0} CP),
						'one' => q({0} CP),
						'other' => q({0} CP),
					},
					'hour' => {
						'few' => q({0} h),
						'name' => q(oră),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
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
					'kelvin' => {
						'few' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
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
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'knot' => {
						'few' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} a.l.),
						'name' => q(a.l.),
						'one' => q({0} a.l.),
						'other' => q({0} a.l.),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
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
					'millibar' => {
						'few' => q({0} mb),
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram' => {
						'few' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
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
					'millisecond' => {
						'few' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'few' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/min.),
					},
					'month' => {
						'few' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/lună),
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
						'few' => q({0} mn),
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
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
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0}%),
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'picometer' => {
						'few' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'point' => {
						'few' => q({0} pt),
						'name' => q(pt),
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
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
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
					'stone' => {
						'few' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'ton' => {
						'few' => q({0} t.s.),
						'name' => q(t.s.),
						'one' => q({0} t.s.),
						'other' => q({0} t.s.),
					},
					'watt' => {
						'few' => q({0} W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} săpt.),
						'name' => q(săpt.),
						'one' => q({0} săpt.),
						'other' => q({0} săpt.),
						'per' => q({0}/săpt.),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} a),
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/an),
					},
				},
				'short' => {
					'' => {
						'name' => q(direcție),
					},
					'acre' => {
						'few' => q({0} ac.),
						'name' => q(acri),
						'one' => q({0} ac.),
						'other' => q({0} ac.),
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
						'few' => q({0} arcmin),
						'name' => q(arcmin),
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					'arc-second' => {
						'few' => q({0} arcsec),
						'name' => q(arcsec),
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					'astronomical-unit' => {
						'few' => q({0} ua),
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'atmosphere' => {
						'few' => q({0} atm),
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'few' => q({0} b),
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'byte' => {
						'few' => q({0} B),
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'calorie' => {
						'few' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} ct),
						'name' => q(carate),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'few' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
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
						'few' => q({0} sec.),
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
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
						'name' => q(căni),
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
						'few' => q({0} zile),
						'name' => q(zile),
						'one' => q({0} zi),
						'other' => q({0} zile),
						'per' => q({0}/zi),
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
						'name' => q(grade),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
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
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'few' => q({0} G),
						'name' => q(forță g),
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
						'few' => q({0} gal imp.),
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0} gal imp.),
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
						'name' => q(grame),
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
						'few' => q({0} CP),
						'name' => q(CP),
						'one' => q({0} CP),
						'other' => q({0} CP),
					},
					'hour' => {
						'few' => q({0} ore),
						'name' => q(ore),
						'one' => q({0} oră),
						'other' => q({0} ore),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'few' => q({0} in Hg),
						'name' => q(in Hg),
						'one' => q({0} in Hg),
						'other' => q({0} in Hg),
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
						'few' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} a.l.),
						'name' => q(a.l.),
						'one' => q({0} a.l.),
						'other' => q({0} a.l.),
					},
					'liter' => {
						'few' => q({0} l),
						'name' => q(litri),
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
						'few' => q({0} mile/gal.),
						'name' => q(mile/gal.),
						'one' => q({0} milă/gal.),
						'other' => q({0} mile/gal.),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} mi/gal imp.),
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
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
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
					},
					'month' => {
						'few' => q({0} luni),
						'name' => q(luni),
						'one' => q({0} lună),
						'other' => q({0} luni),
						'per' => q({0}/lună),
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
						'few' => q({0} mn),
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
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
					'percent' => {
						'few' => q({0}%),
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'few' => q({0}‰),
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'few' => q({0} PB),
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
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
						'few' => q({0} pt),
						'name' => q(pt),
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
						'few' => q({0} rev.),
						'name' => q(rev.),
						'one' => q({0} rev.),
						'other' => q({0} rev.),
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
						'per' => q({0} pe cm²),
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
						'per' => q({0} pe m²),
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
						'few' => q({0} t.s.),
						'name' => q(t.s.),
						'one' => q({0} t.s.),
						'other' => q({0} t.s.),
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
						'few' => q({0} săpt.),
						'name' => q(săptămâni),
						'one' => q({0} săpt.),
						'other' => q({0} săpt.),
						'per' => q({0}/săpt.),
					},
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} ani),
						'name' => q(ani),
						'one' => q({0} an),
						'other' => q({0} ani),
						'per' => q({0}/an),
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
					'few' => '0 K',
					'one' => '0 K',
					'other' => '0 K',
				},
				'10000' => {
					'few' => '00 K',
					'one' => '00 K',
					'other' => '00 K',
				},
				'100000' => {
					'few' => '000 K',
					'one' => '000 K',
					'other' => '000 K',
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
					'few' => '0 mld'.'',
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'few' => '00 mld'.'',
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'few' => '000 mld'.'',
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'few' => '0 tril'.'',
					'one' => '0 tril'.'',
					'other' => '0 tril'.'',
				},
				'10000000000000' => {
					'few' => '00 tril'.'',
					'one' => '00 tril'.'',
					'other' => '00 tril'.'',
				},
				'100000000000000' => {
					'few' => '000 tril'.'',
					'one' => '000 tril'.'',
					'other' => '000 tril'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
					'few' => '0 K',
					'one' => '0 K',
					'other' => '0 K',
				},
				'10000' => {
					'few' => '00 K',
					'one' => '00 K',
					'other' => '00 K',
				},
				'100000' => {
					'few' => '000 K',
					'one' => '000 K',
					'other' => '000 K',
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
					'few' => '0 mld'.'',
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'few' => '00 mld'.'',
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'few' => '000 mld'.'',
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'few' => '0 tril'.'',
					'one' => '0 tril'.'',
					'other' => '0 tril'.'',
				},
				'10000000000000' => {
					'few' => '00 tril'.'',
					'one' => '00 tril'.'',
					'other' => '00 tril'.'',
				},
				'100000000000000' => {
					'few' => '000 tril'.'',
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
				'currency' => q(pesetă andorrană),
				'few' => q(pesete andorrane),
				'one' => q(pesetă andorrană),
				'other' => q(pesete andorrane),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(dirham din Emiratele Arabe Unite),
				'few' => q(dirhami din Emiratele Arabe Unite),
				'one' => q(dirham din Emiratele Arabe Unite),
				'other' => q(dirhami din Emiratele Arabe Unite),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgani afgan),
				'few' => q(afgani afgani),
				'one' => q(afgani afgan),
				'other' => q(afgani afgani),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(leka albaneză),
				'few' => q(leka albaneze),
				'one' => q(leka albaneză),
				'other' => q(leka albaneze),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(dram armenesc),
				'few' => q(drami armenești),
				'one' => q(dram armenesc),
				'other' => q(drami armenești),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(gulden din Antilele Olandeze),
				'few' => q(guldeni din Antilele Olandeze),
				'one' => q(gulden din Antilele Olandeze),
				'other' => q(guldeni din Antilele Olandeze),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'AWG',
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
			symbol => 'AZN',
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
			symbol => 'BAM',
			display_name => {
				'currency' => q(marcă convertibilă din Bosnia și Herțegovina),
				'few' => q(mărci convertibile din Bosnia și Herțegovina),
				'one' => q(marcă convertibilă din Bosnia și Herțegovina),
				'other' => q(mărci convertibile din Bosnia și Herțegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(dolar din Barbados),
				'few' => q(dolari din Barbados),
				'one' => q(dolar din Barbados),
				'other' => q(dolari din Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(taka din Bangladesh),
				'few' => q(taka din Bangladesh),
				'one' => q(taka din Bangladesh),
				'other' => q(taka din Bangladesh),
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
			symbol => 'BGN',
			display_name => {
				'currency' => q(leva bulgărească),
				'few' => q(leva bulgărești),
				'one' => q(leva bulgărească),
				'other' => q(leva bulgărești),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(dinar din Bahrain),
				'few' => q(dinari din Bahrain),
				'one' => q(dinar din Bahrain),
				'other' => q(dinari din Bahrain),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(franc burundez),
				'few' => q(franci burundezi),
				'one' => q(franc burundez),
				'other' => q(franci burundezi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(dolar din Bermuda),
				'few' => q(dolari din Bermuda),
				'one' => q(dolar din Bermuda),
				'other' => q(dolari din Bermuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(dolar din Brunei),
				'few' => q(dolari din Brunei),
				'one' => q(dolar din Brunei),
				'other' => q(dolari Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(boliviano bolivian),
				'few' => q(boliviano bolivieni),
				'one' => q(boliviano bolivian),
				'other' => q(boliviano bolivieni),
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
				'currency' => q(real brazilian),
				'few' => q(reali brazilieni),
				'one' => q(real brazilian),
				'other' => q(reali brazilieni),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro brazilian \(1993–1994\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(dolar din Bahamas),
				'few' => q(dolari din Bahamas),
				'one' => q(dolar din Bahamas),
				'other' => q(dolari din Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(ngultrum din Bhutan),
				'few' => q(ngultrum din Bhutan),
				'one' => q(ngultrum din Bhutan),
				'other' => q(ngultrum din Bhutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birman),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(pula Botswana),
				'few' => q(pula Botswana),
				'one' => q(pula Botswana),
				'other' => q(pula Botswana),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(rublă belarusă),
				'few' => q(ruble belaruse),
				'one' => q(rublă belarusă),
				'other' => q(ruble belaruse),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(rublă belarusă \(2000–2016\)),
				'few' => q(ruble belaruse \(2000–2016\)),
				'one' => q(rublă belarusă \(2000–2016\)),
				'other' => q(ruble belaruse \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
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
			symbol => 'CDF',
			display_name => {
				'currency' => q(franc congolez),
				'few' => q(franci congolezi),
				'one' => q(franc congolez),
				'other' => q(franci congolezi),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(franc elvețian),
				'few' => q(franci elvețieni),
				'one' => q(franc elvețian),
				'other' => q(franci elvețieni),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(peso chilian),
				'few' => q(pesos chilieni),
				'one' => q(peso chilian),
				'other' => q(pesos chilieni),
			},
		},
		'CNH' => {
			symbol => 'CNH',
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
			symbol => 'COP',
			display_name => {
				'currency' => q(peso columbian),
				'few' => q(pesos columbieni),
				'one' => q(peso columbian),
				'other' => q(pesos columbieni),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(colon costarican),
				'few' => q(coloni costaricani),
				'one' => q(colon costarican),
				'other' => q(coloni costaricani),
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(peso cubanez convertibil),
				'few' => q(pesos cubanezi convertibili),
				'one' => q(peso cubanez convertibil),
				'other' => q(pesos cubanezi convertibili),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(peso cubanez),
				'few' => q(pesos cubanezi),
				'one' => q(peso cubanez),
				'other' => q(pesos cubanezi),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(escudo din Capul Verde),
				'few' => q(escudo din Capul Verde),
				'one' => q(escudo din Capul Verde),
				'other' => q(escudo din Capul Verde),
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
			symbol => 'CZK',
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
			symbol => 'DJF',
			display_name => {
				'currency' => q(franc djiboutian),
				'few' => q(franci djiboutieni),
				'one' => q(franc djiboutian),
				'other' => q(franci djiboutieni),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(coroană daneză),
				'few' => q(coroane daneze),
				'one' => q(coroană daneză),
				'other' => q(coroane daneze),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(peso dominican),
				'few' => q(pesos dominicani),
				'one' => q(peso dominican),
				'other' => q(pesos dominicani),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
			symbol => 'EGP',
			display_name => {
				'currency' => q(liră egipteană),
				'few' => q(lire egiptene),
				'one' => q(liră egipteană),
				'other' => q(lire egiptene),
			},
		},
		'ERN' => {
			symbol => 'ERN',
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
			symbol => 'ETB',
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
				'few' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
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
			symbol => 'FJD',
			display_name => {
				'currency' => q(dolar fijian),
				'few' => q(dolari fijieni),
				'one' => q(dolar fijian),
				'other' => q(dolari fijieni),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
			symbol => 'GEL',
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
			symbol => 'GHS',
			display_name => {
				'currency' => q(cedi ghanez),
				'few' => q(cedi ghanezi),
				'one' => q(cedi ghanez),
				'other' => q(cedi ghanezi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(liră din Gibraltar),
				'few' => q(lire din Gibraltar),
				'one' => q(liră din Gibraltar),
				'other' => q(lire Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi din Gambia),
				'few' => q(dalasi din Gambia),
				'one' => q(dalasi din Gambia),
				'other' => q(dalasi din Gambia),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
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
			symbol => 'HNL',
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
			symbol => 'HRK',
			display_name => {
				'currency' => q(kuna croată),
				'few' => q(kune croate),
				'one' => q(kuna croată),
				'other' => q(kune croate),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(gourde din Haiti),
				'few' => q(gourde din Haiti),
				'one' => q(gourde din Haiti),
				'other' => q(gourde din Haiti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(forint maghiar),
				'few' => q(forinți maghiari),
				'one' => q(forint maghiar),
				'other' => q(forinți maghiari),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
				'currency' => q(șechel israelian nou),
				'few' => q(șecheli israelieni noi),
				'one' => q(șechel israelian nou),
				'other' => q(șecheli israelieni noi),
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
			symbol => 'IQD',
			display_name => {
				'currency' => q(dinar irakian),
				'few' => q(dinari irakieni),
				'one' => q(dinar irakian),
				'other' => q(dinari irakieni),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(rial iranian),
				'few' => q(riali iranieni),
				'one' => q(rial iranian),
				'other' => q(riali iranieni),
			},
		},
		'ISK' => {
			symbol => 'ISK',
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
			symbol => 'JMD',
			display_name => {
				'currency' => q(dolar jamaican),
				'few' => q(dolari jamaicani),
				'one' => q(dolar jamaican),
				'other' => q(dolari jamaicani),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(șiling kenyan),
				'few' => q(șilingi kenyeni),
				'one' => q(șiling kenyan),
				'other' => q(șilingi kenyeni),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(som kârgâz),
				'few' => q(somi kârgâzi),
				'one' => q(som kârgâz),
				'other' => q(somi kârgâzi),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel cambodgian),
				'few' => q(rieli cambodgieni),
				'one' => q(riel cambodgian),
				'other' => q(rieli cambodgieni),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(franc comorian),
				'few' => q(franci comorieni),
				'one' => q(franc comorian),
				'other' => q(franci comorieni),
			},
		},
		'KPW' => {
			symbol => 'KPW',
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
			symbol => 'KWD',
			display_name => {
				'currency' => q(dinar kuweitian),
				'few' => q(dinari kuweitieni),
				'one' => q(dinar kuweitian),
				'other' => q(dinari kuweitieni),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dolar din Insulele Cayman),
				'few' => q(dolari din Insulele Cayman),
				'one' => q(dolar din Insulele Cayman),
				'other' => q(dolari din Insulele Cayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(tenge kazahă),
				'few' => q(tenge kazahe),
				'one' => q(tenge kazahă),
				'other' => q(tenge kazahe),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip laoțian),
				'few' => q(kipi laoțieni),
				'one' => q(kip laoțian),
				'other' => q(kipi laoțieni),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(liră libaneză),
				'few' => q(lire libaneze),
				'one' => q(liră libaneză),
				'other' => q(lire libaneze),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(rupie srilankeză),
				'few' => q(rupii srilankeze),
				'one' => q(rupie srilankeză),
				'other' => q(rupii srilankeze),
			},
		},
		'LRD' => {
			symbol => 'LRD',
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
			},
		},
		'LTL' => {
			symbol => 'LTL',
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
			symbol => 'LVL',
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
			symbol => 'LYD',
			display_name => {
				'currency' => q(dinar libian),
				'few' => q(dinari libieni),
				'one' => q(dinar libian),
				'other' => q(dinari libieni),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MDL',
			display_name => {
				'currency' => q(leu moldovenesc),
				'few' => q(lei moldovenești),
				'one' => q(leu moldovenesc),
				'other' => q(lei moldovenești),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
			symbol => 'MKD',
			display_name => {
				'currency' => q(dinar macedonean),
				'few' => q(dinari macedoneni),
				'one' => q(dinar macedonean),
				'other' => q(dinari macedoneni),
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
			symbol => 'MMK',
			display_name => {
				'currency' => q(kyat din Myanmar),
				'few' => q(kyați din Myanmar),
				'one' => q(kyat din Myanmar),
				'other' => q(kyați din Myanmar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(tugrik mongol),
				'few' => q(tugrici mongoli),
				'one' => q(tugrik mongol),
				'other' => q(tugrici mongoli),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(pataca din Macao),
				'few' => q(pataca din Macao),
				'one' => q(pataca din Macao),
				'other' => q(pataca din Macao),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(ouguiya mauritană \(1973–2017\)),
				'few' => q(ouguiya mauritane \(1973–2017\)),
				'one' => q(ouguiya mauritană \(1973–2017\)),
				'other' => q(ouguiya mauritane \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(rupie mauritiană),
				'few' => q(rupii mauritiene),
				'one' => q(rupie mauritiană),
				'other' => q(rupii mauritiene),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(rufiyaa maldiviană),
				'few' => q(rufiyaa maldiviene),
				'one' => q(rufiyaa maldiviană),
				'other' => q(rufiyaa maldiviene),
			},
		},
		'MWK' => {
			symbol => 'MWK',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(metical mozambican),
				'few' => q(metical mozambicani),
				'one' => q(metical mozambican),
				'other' => q(metical mozambicani),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(dolar namibian),
				'few' => q(dolari namibieni),
				'one' => q(dolar namibian),
				'other' => q(dolari namibieni),
			},
		},
		'NGN' => {
			symbol => 'NGN',
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
			symbol => 'NIO',
			display_name => {
				'currency' => q(cordoba nicaraguană),
				'few' => q(cordobe nicaraguane),
				'one' => q(cordoba nicaraguană),
				'other' => q(cordobe nicaraguane),
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
			symbol => 'NOK',
			display_name => {
				'currency' => q(coroană norvegiană),
				'few' => q(coroane norvegiene),
				'one' => q(coroană norvegiană),
				'other' => q(coroane norvegiene),
			},
		},
		'NPR' => {
			symbol => 'NPR',
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
			symbol => 'OMR',
			display_name => {
				'currency' => q(rial omanez),
				'few' => q(riali omanezi),
				'one' => q(rial omanez),
				'other' => q(riali omanezi),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
			symbol => 'PEN',
			display_name => {
				'currency' => q(sol peruvian),
				'few' => q(soli peruvieni),
				'one' => q(sol peruvian),
				'other' => q(soli peruvieni),
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
			symbol => 'PGK',
			display_name => {
				'currency' => q(kina din Papua-Noua Guinee),
				'few' => q(kina din Papua-Noua Guinee),
				'one' => q(kina din Papua-Noua Guinee),
				'other' => q(kina din Papua-Noua Guinee),
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(rupie pakistaneză),
				'few' => q(rupii pakistaneze),
				'one' => q(rupie pakistaneză),
				'other' => q(rupii pakistaneze),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(zlot polonez),
				'few' => q(zloți polonezi),
				'one' => q(zlot polonez),
				'other' => q(zloți polonezi),
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(guarani paraguayan),
				'few' => q(guarani paraguayeni),
				'one' => q(guarani paraguayan),
				'other' => q(guarani paraguayeni),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'RON',
			display_name => {
				'currency' => q(leu românesc),
				'few' => q(lei românești),
				'one' => q(leu românesc),
				'other' => q(lei românești),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinar sârbesc),
				'few' => q(dinari sârbești),
				'one' => q(dinar sârbesc),
				'other' => q(dinari sârbești),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(rublă rusească),
				'few' => q(ruble rusești),
				'one' => q(rublă rusească),
				'other' => q(ruble rusești),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(franc rwandez),
				'few' => q(franci rwandezi),
				'one' => q(franc rwandez),
				'other' => q(franci rwandezi),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(rial saudit),
				'few' => q(riali saudiți),
				'one' => q(rial saudit),
				'other' => q(riali saudiți),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(dolar din Insulele Solomon),
				'few' => q(dolari din Insulele Solomon),
				'one' => q(dolar din Insulele Solomon),
				'other' => q(dolari din Insulele Solomon),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(rupie din Seychelles),
				'few' => q(rupii din Seychelles),
				'one' => q(rupie din Seychelles),
				'other' => q(rupii din Seychelles),
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
			symbol => 'SDG',
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
			symbol => 'SEK',
			display_name => {
				'currency' => q(coroană suedeză),
				'few' => q(coroane suedeze),
				'one' => q(coroană suedeză),
				'other' => q(coroane suedeze),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(dolar singaporez),
				'few' => q(dolari singaporezi),
				'one' => q(dolar singaporez),
				'other' => q(dolari singaporezi),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(liră Insula Sf. Elena),
				'few' => q(lire Insula Sf. Elena),
				'one' => q(liră Insula Sf. Elena),
				'other' => q(lire Insula Sf. Elena),
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leone din Sierra Leone),
				'few' => q(leoni din Sierra Leone),
				'one' => q(leone din Sierra Leone),
				'other' => q(leoni din Sierra Leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(șiling somalez),
				'few' => q(șilingi somalezi),
				'one' => q(șiling somalez),
				'other' => q(șilingi somalezi),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(liră din Sudanul de Sud),
				'few' => q(lire din Sudanul de Sud),
				'one' => q(liră din Sudanul de Sud),
				'other' => q(lire din Sudanul de Sud),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(dobra Sao Tome și Principe \(1977–2017\)),
				'few' => q(dobre Sao Tome și Principe \(1977–2017\)),
				'one' => q(dobra Sao Tome și Principe \(1977–2017\)),
				'other' => q(dobre Sao Tome și Principe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(dobra Sao Tome și Principe),
				'few' => q(dobre Sao Tome și Principe),
				'one' => q(dobra Sao Tome și Principe),
				'other' => q(dobre Sao Tome și Principe),
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
			symbol => 'SYP',
			display_name => {
				'currency' => q(liră siriană),
				'few' => q(lire siriene),
				'one' => q(liră siriană),
				'other' => q(lire siriene),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(lilangeni din Swaziland),
				'few' => q(emalangeni din Swaziland),
				'one' => q(lilangeni din Swaziland),
				'other' => q(emalangeni din Swaziland),
			},
		},
		'THB' => {
			symbol => 'THB',
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
			symbol => 'TJS',
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
			symbol => 'TMT',
			display_name => {
				'currency' => q(manat turkmen),
				'few' => q(manat turkmeni),
				'one' => q(manat turkmen),
				'other' => q(manat turkmeni),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinar tunisian),
				'few' => q(dinari tunisieni),
				'one' => q(dinar tunisian),
				'other' => q(dinari tunisieni),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
			symbol => 'TRY',
			display_name => {
				'currency' => q(liră turcească),
				'few' => q(lire turcești),
				'one' => q(liră turcească),
				'other' => q(lire turcești),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(dolar din Trinidad-Tobago),
				'few' => q(dolari din Trinidad-Tobago),
				'one' => q(dolar din Trinidad-Tobago),
				'other' => q(dolari din Trinidad-Tobago),
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(șiling tanzanian),
				'few' => q(șilingi tanzanieni),
				'one' => q(șiling tanzanian),
				'other' => q(șilingi tanzanieni),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(hryvna ucraineană),
				'few' => q(hryvna ucrainiene),
				'one' => q(hryvna ucrainiană),
				'other' => q(hryvna ucrainiene),
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
			symbol => 'UGX',
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(peso uruguayan),
				'few' => q(pesos uruguayeni),
				'one' => q(peso uruguayan),
				'other' => q(pesos uruguayeni),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(sum Uzbekistan),
				'few' => q(sum Uzbekistan),
				'one' => q(sum Uzbekistan),
				'other' => q(sum Uzbekistan),
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
			symbol => 'VEF',
			display_name => {
				'currency' => q(bolivar venezuelean \(2008–2018\)),
				'few' => q(bolivari venezueleni \(2008–2018\)),
				'one' => q(bolivar venezuelean \(2008–2018\)),
				'other' => q(bolivari venezueleni \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(bolivar venezuelean),
				'few' => q(bolivari venezueleni),
				'one' => q(bolivar venezuelean),
				'other' => q(bolivari venezueleni),
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
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu din Vanuatu),
				'few' => q(vatu din Vanuatu),
				'one' => q(vatu din Vanuatu),
				'other' => q(vatu din Vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala samoană),
				'few' => q(tala samoane),
				'one' => q(tala samoană),
				'other' => q(tala samoană),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
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
				'currency' => q(dolar din Caraibele de Est),
				'few' => q(dolari din Caraibele de Est),
				'one' => q(dolar din Caraibele de Est),
				'other' => q(dolari din Caraibele de Est),
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
			symbol => 'CFA',
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
			symbol => 'CFPF',
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
			symbol => 'YER',
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
			symbol => 'ZAR',
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
			symbol => 'ZMW',
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
				},
				'stand-alone' => {
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					abbreviated => {
						mon => 'lun.',
						tue => 'mar.',
						wed => 'mie.',
						thu => 'joi',
						fri => 'vin.',
						sat => 'sâm.',
						sun => 'dum.'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					narrow => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
					},
					wide => {0 => 'trimestrul I',
						1 => 'trimestrul al II-lea',
						2 => 'trimestrul al III-lea',
						3 => 'trimestrul al IV-lea'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'trim. I',
						1 => 'trim. II',
						2 => 'trim. III',
						3 => 'trim. IV'
					},
					narrow => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
					},
					wide => {0 => 'trimestrul I',
						1 => 'trimestrul al II-lea',
						2 => 'trimestrul al III-lea',
						3 => 'trimestrul al IV-lea'
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
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 500
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 500
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 500;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
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
				'narrow' => {
					'night1' => q{noaptea},
					'am' => q{a.m.},
					'pm' => q{p.m.},
					'midnight' => q{miezul nopții},
					'afternoon1' => q{după-amiaza},
					'noon' => q{la amiază},
					'morning1' => q{dimineața},
					'evening1' => q{seara},
				},
				'wide' => {
					'am' => q{a.m.},
					'midnight' => q{la miezul nopții},
					'pm' => q{p.m.},
					'night1' => q{noaptea},
					'morning1' => q{dimineața},
					'evening1' => q{seara},
					'afternoon1' => q{după-amiaza},
					'noon' => q{la amiază},
				},
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
					'midnight' => q{miezul nopții},
					'night1' => q{noaptea},
					'morning1' => q{dimineața},
					'evening1' => q{seara},
					'afternoon1' => q{după-amiaza},
					'noon' => q{amiază},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a.m.},
					'midnight' => q{miezul nopții},
					'pm' => q{p.m.},
					'night1' => q{noaptea},
					'morning1' => q{dimineața},
					'evening1' => q{seara},
					'noon' => q{amiază},
					'afternoon1' => q{după-amiaza},
				},
				'wide' => {
					'midnight' => q{la miezul nopții},
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'night1' => q{noaptea},
					'evening1' => q{seara},
					'morning1' => q{dimineața},
					'afternoon1' => q{după-amiaza},
					'noon' => q{la amiază},
				},
				'narrow' => {
					'night1' => q{noaptea},
					'am' => q{a.m.},
					'pm' => q{p.m.},
					'midnight' => q{miezul nopții},
					'afternoon1' => q{după-amiaza},
					'noon' => q{amiază},
					'morning1' => q{dimineața},
					'evening1' => q{seara},
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
			narrow => {
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
			narrow => {
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
			narrow => {
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
			narrow => {
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
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'A.M.'
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
				'0' => 'A.H.'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'A.P.'
			},
			narrow => {
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
			narrow => {
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.y GGGGG},
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
			'full' => q{{1} 'la' {0}},
			'long' => q{{1} 'la' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} 'la' {0}},
			'long' => q{{1} 'la' {0}},
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
		'buddhist' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
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
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'săptămâna' W 'din' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd.MM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
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
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
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
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
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
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
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
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
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
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
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
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
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
		regionFormat => q(Ora din {0}),
		regionFormat => q(Ora de vară din {0}),
		regionFormat => q(Ora standard din {0}),
		fallbackFormat => q({1} ({0})),
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
			exemplarCity => q#Alger#,
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
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
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
			exemplarCity => q#Sao Tomé#,
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
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
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
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
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
			exemplarCity => q#Guadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
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
			exemplarCity => q#Jamaica#,
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
			exemplarCity => q#Martinica#,
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
			exemplarCity => q#Beulah, Dakota de Nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota de Nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota de Nord#,
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
			exemplarCity => q#Showa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatî#,
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
			exemplarCity => q#Așgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atîrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
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
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bișkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Cita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasc#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dușanbe#,
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
			exemplarCity => q#Irkuțk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ierusalim#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamciatka#,
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
			exemplarCity => q#Krasnoiarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuweit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
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
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznețk#,
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
			exemplarCity => q#Phenian#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
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
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tașkent#,
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
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canare#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Capul Verde#,
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
			exemplarCity => q#Georgia de Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sf. Elena#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
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
			exemplarCity => q#București#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapesta#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chișinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhaga#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Ora de vară a Irlandei#,
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
			exemplarCity => q#Insula Man#,
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
			exemplarCity => q#Lisabona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
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
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscova#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
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
			exemplarCity => q#Roma#,
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
			exemplarCity => q#Sofia#,
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
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ujhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varșovia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
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
			exemplarCity => q#Comore#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldive#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
				'standard' => q#Ora Insulelor Norfolk#,
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
			exemplarCity => q#Insula Paștelui#,
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
			exemplarCity => q#Marchize#,
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
			exemplarCity => q#Insula Pitcairn#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
