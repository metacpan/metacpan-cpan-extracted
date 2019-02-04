=encoding utf8

=head1

Locale::CLDR::Locales::Eo - Package for language Esperanto

=cut

package Locale::CLDR::Locales::Eo;
# This file auto generated from Data\common\main\eo.xml
#	on Sun  3 Feb  1:48:29 pm GMT

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulo),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komo →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(unu),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(du),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(kvar),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(kvin),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ses),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sep),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ok),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naŭ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dek[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←dek[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←cent[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miliono[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← milionoj[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← miliardoj[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biliono[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← bilionoj[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biliardoj[ →→]),
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=a),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=a),
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
				'aa' => 'afara',
 				'ab' => 'abĥaza',
 				'af' => 'afrikansa',
 				'ak' => 'akana',
 				'am' => 'amhara',
 				'ar' => 'araba',
 				'ar_001' => 'moderna norma araba',
 				'arn' => 'mapuĉa',
 				'as' => 'asama',
 				'ay' => 'ajmara',
 				'az' => 'azerbajĝana',
 				'ba' => 'baŝkira',
 				'be' => 'belorusa',
 				'bg' => 'bulgara',
 				'bi' => 'bislamo',
 				'bm' => 'bambara',
 				'bn' => 'bengala',
 				'bo' => 'tibeta',
 				'br' => 'bretona',
 				'brx' => 'bodoa',
 				'bs' => 'bosnia',
 				'ca' => 'kataluna',
 				'chr' => 'ĉeroka',
 				'ckb' => 'sorana',
 				'co' => 'korsika',
 				'cs' => 'ĉeĥa',
 				'cy' => 'kimra',
 				'da' => 'dana',
 				'de' => 'germana',
 				'de_AT' => 'aŭstra germana',
 				'de_CH' => 'svisa germana',
 				'dsb' => 'malsuprasoraba',
 				'dv' => 'mahla',
 				'dz' => 'dzonko',
 				'efi' => 'ibibioefika',
 				'el' => 'greka',
 				'en' => 'angla',
 				'en_AU' => 'aŭstralia angla',
 				'en_CA' => 'kanada angla',
 				'en_GB' => 'brita angla',
 				'en_GB@alt=short' => 'brita angla',
 				'en_US' => 'usona angla',
 				'en_US@alt=short' => 'usona angla',
 				'eo' => 'esperanto',
 				'es' => 'hispana',
 				'es_419' => 'amerika hispana',
 				'es_ES' => 'eŭropa hispana',
 				'es_MX' => 'meksika hispana',
 				'et' => 'estona',
 				'eu' => 'eŭska',
 				'fa' => 'persa',
 				'fi' => 'finna',
 				'fil' => 'filipina',
 				'fj' => 'fiĝia',
 				'fo' => 'feroa',
 				'fr' => 'franca',
 				'fr_CA' => 'kanada franca',
 				'fr_CH' => 'svisa franca',
 				'fy' => 'frisa',
 				'ga' => 'irlanda',
 				'gd' => 'gaela',
 				'gl' => 'galega',
 				'gn' => 'gvarania',
 				'gu' => 'guĝarata',
 				'ha' => 'haŭsa',
 				'haw' => 'havaja',
 				'he' => 'hebrea',
 				'hi' => 'hinda',
 				'hr' => 'kroata',
 				'ht' => 'haitia kreola',
 				'hu' => 'hungara',
 				'hy' => 'armena',
 				'ia' => 'interlingvao',
 				'id' => 'indonezia',
 				'ie' => 'okcidentalo',
 				'ik' => 'eskima',
 				'is' => 'islanda',
 				'it' => 'itala',
 				'iu' => 'inuita',
 				'ja' => 'japana',
 				'jv' => 'java',
 				'ka' => 'kartvela',
 				'kk' => 'kazaĥa',
 				'kl' => 'gronlanda',
 				'km' => 'kmera',
 				'kn' => 'kanara',
 				'ko' => 'korea',
 				'ks' => 'kaŝmira',
 				'ku' => 'kurda',
 				'ky' => 'kirgiza',
 				'la' => 'latino',
 				'lb' => 'luksemburga',
 				'ln' => 'lingala',
 				'lo' => 'laŭa',
 				'lt' => 'litova',
 				'lv' => 'latva',
 				'mg' => 'malagasa',
 				'mi' => 'maoria',
 				'mk' => 'makedona',
 				'ml' => 'malajalama',
 				'mn' => 'mongola',
 				'mr' => 'marata',
 				'ms' => 'malaja',
 				'mt' => 'malta',
 				'mul' => 'pluraj lingvoj',
 				'my' => 'birma',
 				'na' => 'naura',
 				'nb' => 'dannorvega',
 				'ne' => 'nepala',
 				'nl' => 'nederlanda',
 				'nl_BE' => 'flandra',
 				'nn' => 'novnorvega',
 				'no' => 'norvega',
 				'oc' => 'okcitana',
 				'om' => 'oroma',
 				'or' => 'orijo',
 				'pa' => 'panĝaba',
 				'pl' => 'pola',
 				'ps' => 'paŝtoa',
 				'pt' => 'portugala',
 				'pt_BR' => 'brazilportugala',
 				'pt_PT' => 'eŭropportugala',
 				'qu' => 'keĉua',
 				'rm' => 'romanĉa',
 				'rn' => 'burunda',
 				'ro' => 'rumana',
 				'ru' => 'rusa',
 				'rw' => 'ruanda',
 				'sa' => 'sanskrito',
 				'sd' => 'sinda',
 				'sg' => 'sangoa',
 				'sh' => 'serbo-Kroata',
 				'si' => 'sinhala',
 				'sk' => 'slovaka',
 				'sl' => 'slovena',
 				'sm' => 'samoa',
 				'sn' => 'ŝona',
 				'so' => 'somala',
 				'sq' => 'albana',
 				'sr' => 'serba',
 				'ss' => 'svazia',
 				'st' => 'sota',
 				'su' => 'sunda',
 				'sv' => 'sveda',
 				'sw' => 'svahila',
 				'ta' => 'tamila',
 				'te' => 'telugua',
 				'tg' => 'taĝika',
 				'th' => 'taja',
 				'ti' => 'tigraja',
 				'tk' => 'turkmena',
 				'tl' => 'tagaloga',
 				'tlh' => 'klingona',
 				'tn' => 'cvana',
 				'to' => 'tongaa',
 				'tr' => 'turka',
 				'ts' => 'conga',
 				'tt' => 'tatara',
 				'tw' => 'tw',
 				'ug' => 'ujgura',
 				'uk' => 'ukraina',
 				'und' => 'nekonata lingvo',
 				'ur' => 'urduo',
 				'uz' => 'uzbeka',
 				'vi' => 'vjetnama',
 				'vo' => 'volapuko',
 				'wo' => 'volofa',
 				'xh' => 'ksosa',
 				'yi' => 'jida',
 				'yo' => 'joruba',
 				'za' => 'ĝuanga',
 				'zh' => 'ĉina',
 				'zh_Hans' => 'ĉina simpligita',
 				'zh_Hant' => 'ĉina tradicia',
 				'zu' => 'zulua',
 				'zxx' => 'nelingvaĵo',

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
			'Arab' => 'araba',
 			'Cyrl' => 'cirila',
 			'Hans' => 'simpligita',
 			'Hans@alt=stand-alone' => 'simpligita ĉina',
 			'Hant' => 'tradicia',
 			'Hant@alt=stand-alone' => 'tradicia ĉina',
 			'Jpan' => 'japana',
 			'Kore' => 'korea',
 			'Latn' => 'latina',
 			'Zxxx' => 'neskribata',
 			'Zzzz' => 'nekonata skribsistemo',

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
			'AD' => 'Andoro',
 			'AE' => 'Unuiĝintaj Arabaj Emirlandoj',
 			'AF' => 'Afganujo',
 			'AG' => 'Antigvo-Barbudo',
 			'AI' => 'Angvilo',
 			'AL' => 'Albanujo',
 			'AM' => 'Armenujo',
 			'AO' => 'Angolo',
 			'AQ' => 'Antarkto',
 			'AR' => 'Argentino',
 			'AT' => 'Aŭstrujo',
 			'AU' => 'Aŭstralio',
 			'AW' => 'Arubo',
 			'AZ' => 'Azerbajĝano',
 			'BA' => 'Bosnio-Hercegovino',
 			'BB' => 'Barbado',
 			'BD' => 'Bangladeŝo',
 			'BE' => 'Belgujo',
 			'BF' => 'Burkino',
 			'BG' => 'Bulgarujo',
 			'BH' => 'Barejno',
 			'BI' => 'Burundo',
 			'BJ' => 'Benino',
 			'BM' => 'Bermudoj',
 			'BN' => 'Brunejo',
 			'BO' => 'Bolivio',
 			'BR' => 'Brazilo',
 			'BS' => 'Bahamoj',
 			'BT' => 'Butano',
 			'BW' => 'Bocvano',
 			'BY' => 'Belorusujo',
 			'BZ' => 'Belizo',
 			'CA' => 'Kanado',
 			'CF' => 'Centr-Afrika Respubliko',
 			'CG' => 'Kongolo',
 			'CH' => 'Svisujo',
 			'CI' => 'Ebur-Bordo',
 			'CK' => 'Kukinsuloj',
 			'CL' => 'Ĉilio',
 			'CM' => 'Kameruno',
 			'CN' => 'Ĉinujo',
 			'CO' => 'Kolombio',
 			'CR' => 'Kostariko',
 			'CU' => 'Kubo',
 			'CV' => 'Kabo-Verdo',
 			'CY' => 'Kipro',
 			'CZ' => 'Ĉeĥujo',
 			'DE' => 'Germanujo',
 			'DJ' => 'Ĝibutio',
 			'DK' => 'Danujo',
 			'DM' => 'Dominiko',
 			'DO' => 'Domingo',
 			'DZ' => 'Alĝerio',
 			'EC' => 'Ekvadoro',
 			'EE' => 'Estonujo',
 			'EG' => 'Egipto',
 			'EH' => 'Okcidenta Saharo',
 			'ER' => 'Eritreo',
 			'ES' => 'Hispanujo',
 			'ET' => 'Etiopujo',
 			'FI' => 'Finnlando',
 			'FJ' => 'Fiĝoj',
 			'FM' => 'Mikronezio',
 			'FO' => 'Ferooj',
 			'FR' => 'Francujo',
 			'GA' => 'Gabono',
 			'GB' => 'Unuiĝinta Reĝlando',
 			'GD' => 'Grenado',
 			'GE' => 'Kartvelujo',
 			'GF' => 'Franca Gviano',
 			'GH' => 'Ganao',
 			'GI' => 'Ĝibraltaro',
 			'GL' => 'Gronlando',
 			'GM' => 'Gambio',
 			'GN' => 'Gvineo',
 			'GP' => 'Gvadelupo',
 			'GQ' => 'Ekvatora Gvineo',
 			'GR' => 'Grekujo',
 			'GS' => 'Sud-Georgio kaj Sud-Sandviĉinsuloj',
 			'GT' => 'Gvatemalo',
 			'GU' => 'Gvamo',
 			'GW' => 'Gvineo-Bisaŭo',
 			'GY' => 'Gujano',
 			'HK' => 'Honkongo',
 			'HM' => 'Herda kaj Makdonaldaj Insuloj',
 			'HN' => 'Honduro',
 			'HR' => 'Kroatujo',
 			'HT' => 'Haitio',
 			'HU' => 'Hungarujo',
 			'ID' => 'Indonezio',
 			'IE' => 'Irlando',
 			'IL' => 'Israelo',
 			'IN' => 'Hindujo',
 			'IO' => 'Brita Hindoceana Teritorio',
 			'IQ' => 'Irako',
 			'IR' => 'Irano',
 			'IS' => 'Islando',
 			'IT' => 'Italujo',
 			'JM' => 'Jamajko',
 			'JO' => 'Jordanio',
 			'JP' => 'Japanujo',
 			'KE' => 'Kenjo',
 			'KG' => 'Kirgizistano',
 			'KH' => 'Kamboĝo',
 			'KI' => 'Kiribato',
 			'KM' => 'Komoroj',
 			'KN' => 'Sent-Kristofo kaj Neviso',
 			'KP' => 'Nord-Koreo',
 			'KR' => 'Sud-Koreo',
 			'KW' => 'Kuvajto',
 			'KY' => 'Kejmanoj',
 			'KZ' => 'Kazaĥstano',
 			'LA' => 'Laoso',
 			'LB' => 'Libano',
 			'LC' => 'Sent-Lucio',
 			'LI' => 'Liĥtenŝtejno',
 			'LK' => 'Sri-Lanko',
 			'LR' => 'Liberio',
 			'LS' => 'Lesoto',
 			'LT' => 'Litovujo',
 			'LU' => 'Luksemburgo',
 			'LV' => 'Latvujo',
 			'LY' => 'Libio',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavujo',
 			'MG' => 'Madagaskaro',
 			'MH' => 'Marŝaloj',
 			'MK' => 'Makedonujo',
 			'ML' => 'Malio',
 			'MM' => 'Mjanmao',
 			'MN' => 'Mongolujo',
 			'MP' => 'Nord-Marianoj',
 			'MQ' => 'Martiniko',
 			'MR' => 'Maŭritanujo',
 			'MT' => 'Malto',
 			'MU' => 'Maŭricio',
 			'MV' => 'Maldivoj',
 			'MW' => 'Malavio',
 			'MX' => 'Meksiko',
 			'MY' => 'Malajzio',
 			'MZ' => 'Mozambiko',
 			'NA' => 'Namibio',
 			'NC' => 'Nov-Kaledonio',
 			'NE' => 'Niĝero',
 			'NF' => 'Norfolkinsulo',
 			'NG' => 'Niĝerio',
 			'NI' => 'Nikaragvo',
 			'NL' => 'Nederlando',
 			'NO' => 'Norvegujo',
 			'NP' => 'Nepalo',
 			'NR' => 'Nauro',
 			'NU' => 'Niuo',
 			'NZ' => 'Nov-Zelando',
 			'OM' => 'Omano',
 			'PA' => 'Panamo',
 			'PE' => 'Peruo',
 			'PF' => 'Franca Polinezio',
 			'PG' => 'Papuo-Nov-Gvineo',
 			'PH' => 'Filipinoj',
 			'PK' => 'Pakistano',
 			'PL' => 'Pollando',
 			'PM' => 'Sent-Piero kaj Mikelono',
 			'PN' => 'Pitkarna Insulo',
 			'PR' => 'Puerto-Riko',
 			'PT' => 'Portugalujo',
 			'PW' => 'Belaŭo',
 			'PY' => 'Paragvajo',
 			'QA' => 'Kataro',
 			'RE' => 'Reunio',
 			'RO' => 'Rumanujo',
 			'RU' => 'Rusujo',
 			'RW' => 'Ruando',
 			'SA' => 'Saŭda Arabujo',
 			'SB' => 'Salomonoj',
 			'SC' => 'Sejŝeloj',
 			'SD' => 'Sudano',
 			'SE' => 'Svedujo',
 			'SG' => 'Singapuro',
 			'SH' => 'Sent-Heleno',
 			'SI' => 'Slovenujo',
 			'SJ' => 'Svalbardo kaj Jan-Majen-insulo',
 			'SK' => 'Slovakujo',
 			'SL' => 'Siera-Leono',
 			'SM' => 'San-Marino',
 			'SN' => 'Senegalo',
 			'SO' => 'Somalujo',
 			'SR' => 'Surinamo',
 			'SS' => 'Sud-Sudano',
 			'ST' => 'Sao-Tomeo kaj Principeo',
 			'SV' => 'Salvadoro',
 			'SY' => 'Sirio',
 			'SZ' => 'Svazilando',
 			'TD' => 'Ĉado',
 			'TG' => 'Togolo',
 			'TH' => 'Tajlando',
 			'TJ' => 'Taĝikujo',
 			'TM' => 'Turkmenujo',
 			'TN' => 'Tunizio',
 			'TO' => 'Tongo',
 			'TR' => 'Turkujo',
 			'TT' => 'Trinidado kaj Tobago',
 			'TV' => 'Tuvalo',
 			'TW' => 'Tajvano',
 			'TZ' => 'Tanzanio',
 			'UA' => 'Ukrajno',
 			'UG' => 'Ugando',
 			'UM' => 'Usonaj malgrandaj insuloj',
 			'US' => 'Usono',
 			'UY' => 'Urugvajo',
 			'UZ' => 'Uzbekujo',
 			'VA' => 'Vatikano',
 			'VC' => 'Sent-Vincento kaj la Grenadinoj',
 			'VE' => 'Venezuelo',
 			'VG' => 'Britaj Virgulininsuloj',
 			'VI' => 'Usonaj Virgulininsuloj',
 			'VN' => 'Vjetnamo',
 			'VU' => 'Vanuatuo',
 			'WF' => 'Valiso kaj Futuno',
 			'WS' => 'Samoo',
 			'YE' => 'Jemeno',
 			'YT' => 'Majoto',
 			'ZA' => 'Sud-Afriko',
 			'ZM' => 'Zambio',
 			'ZW' => 'Zimbabvo',
 			'ZZ' => 'nekonata regiono',

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
 				'gregorian' => q{gregoria kalendaro},
 				'iso8601' => q{kalendaro ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{norma ordigo},
 			},
 			'numbers' => {
 				'latn' => q{eŭropaj ciferoj},
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
			'metric' => q{metra},
 			'UK' => q{brita},
 			'US' => q{usona},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Lingvo: {0}',
 			'script' => 'Skribsistemo: {0}',
 			'region' => 'Regiono: {0}',

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
			index => ['A', 'B', 'C', 'Ĉ', 'D', 'E', 'F', 'G', 'Ĝ', 'H', 'Ĥ', 'I', 'J', 'Ĵ', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'Ŝ', 'T', 'U', 'Ŭ', 'V', 'Z'],
			main => qr{[a b c ĉ d e f g ĝ h ĥ i j ĵ k l m n o p r s ŝ t u ŭ v z]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] \{ \} /]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ĉ', 'D', 'E', 'F', 'G', 'Ĝ', 'H', 'Ĥ', 'I', 'J', 'Ĵ', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'Ŝ', 'T', 'U', 'Ŭ', 'V', 'Z'], };
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
						'name' => q(akreoj),
						'one' => q({0} akreo),
						'other' => q({0} akreoj),
					},
					'astronomical-unit' => {
						'name' => q(astronomiaj unuoj),
						'one' => q({0} astronomia unuo),
						'other' => q({0} astronomiaj unuoj),
					},
					'bit' => {
						'name' => q(bitoj),
						'one' => q({0} bito),
						'other' => q({0} bitoj),
					},
					'byte' => {
						'name' => q(bajtoj),
						'one' => q({0} bajto),
						'other' => q({0} bajtoj),
					},
					'celsius' => {
						'name' => q(gradoj celsiaj),
						'one' => q({0} grado celsia),
						'other' => q({0} gradoj celsiaj),
					},
					'centimeter' => {
						'name' => q(centimetroj),
						'one' => q({0} centimetro),
						'other' => q({0} centimetroj),
					},
					'day' => {
						'name' => q(tagoj),
						'one' => q({0} tago),
						'other' => q({0} tagoj),
					},
					'decimeter' => {
						'name' => q(decimetroj),
						'one' => q({0} decimetro),
						'other' => q({0} decimetroj),
					},
					'fathom' => {
						'name' => q(klaftoj),
						'one' => q({0} klafto),
						'other' => q({0} klaftoj),
					},
					'foot' => {
						'name' => q(futoj),
						'one' => q({0} futo),
						'other' => q({0} futoj),
					},
					'furlong' => {
						'name' => q(stadioj),
						'one' => q({0} stadio),
						'other' => q({0} stadioj),
					},
					'gigabit' => {
						'name' => q(gigabitoj),
						'one' => q({0} gigabito),
						'other' => q({0} gigabitoj),
					},
					'gigabyte' => {
						'name' => q(gigabajtoj),
						'one' => q({0} gigabajto),
						'other' => q({0} gigabajtoj),
					},
					'gram' => {
						'name' => q(gramoj),
						'one' => q({0} gramo),
						'other' => q({0} gramoj),
					},
					'hectare' => {
						'name' => q(hektaroj),
						'one' => q({0} hektaro),
						'other' => q({0} hektaroj),
					},
					'hour' => {
						'name' => q(horoj),
						'one' => q({0} horo),
						'other' => q({0} horoj),
						'per' => q({0} por horo),
					},
					'inch' => {
						'name' => q(coloj),
						'one' => q({0} colo),
						'other' => q({0} coloj),
					},
					'kilobit' => {
						'name' => q(kilobitoj),
						'one' => q({0} kilobito),
						'other' => q({0} kilobitoj),
					},
					'kilobyte' => {
						'name' => q(kilobajtoj),
						'one' => q({0} kilobajto),
						'other' => q({0} kilobajtoj),
					},
					'kilogram' => {
						'name' => q(kilogramoj),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramoj),
					},
					'kilometer' => {
						'name' => q(kilometroj),
						'one' => q({0} kilometro),
						'other' => q({0} kilometroj),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometroj en horo),
						'one' => q({0} kilometro en horo),
						'other' => q({0} kilometroj en horo),
					},
					'light-year' => {
						'name' => q(lumjaroj),
						'one' => q({0} lumjaro),
						'other' => q({0} lumjaroj),
					},
					'liter' => {
						'name' => q(litroj),
						'one' => q({0} litro),
						'other' => q({0} litroj),
					},
					'megabit' => {
						'name' => q(megabitoj),
						'one' => q({0} megabito),
						'other' => q({0} megabitoj),
					},
					'megabyte' => {
						'name' => q(megabajtoj),
						'one' => q({0} megabajto),
						'other' => q({0} megabajtoj),
					},
					'meter' => {
						'name' => q(metroj),
						'one' => q({0} metro),
						'other' => q({0} metroj),
					},
					'micrometer' => {
						'name' => q(mikrometroj),
						'one' => q({0} mikrometro),
						'other' => q({0} mikrometroj),
					},
					'mile' => {
						'name' => q(mejloj),
						'one' => q({0} mejlo),
						'other' => q({0} mejloj),
					},
					'millimeter' => {
						'name' => q(milimetroj),
						'one' => q({0} milimetro),
						'other' => q({0} milimetroj),
					},
					'millisecond' => {
						'name' => q(milisekundoj),
						'one' => q({0} milisekundo),
						'other' => q({0} milisekundoj),
					},
					'minute' => {
						'name' => q(minutoj),
						'one' => q({0} minuto),
						'other' => q({0} minutoj),
					},
					'month' => {
						'name' => q(monatoj),
						'one' => q({0} monato),
						'other' => q({0} monatoj),
					},
					'nanometer' => {
						'name' => q(nanometroj),
						'one' => q({0} nanometro),
						'other' => q({0} nanometroj),
					},
					'nautical-mile' => {
						'name' => q(marmejloj),
						'one' => q({0} marmejlo),
						'other' => q({0} marmejloj),
					},
					'parsec' => {
						'name' => q(parsekoj),
						'one' => q({0} parseko),
						'other' => q({0} parsekoj),
					},
					'picometer' => {
						'name' => q(pikometroj),
						'one' => q({0} pikometro),
						'other' => q({0} pikometroj),
					},
					'second' => {
						'name' => q(sekundoj),
						'one' => q({0} sekundo),
						'other' => q({0} sekundoj),
						'per' => q({0} por sekundo),
					},
					'square-centimeter' => {
						'name' => q(kvadrataj centimetroj),
						'one' => q({0} kvadrata centimetro),
						'other' => q({0} kvadrataj centimetroj),
					},
					'square-foot' => {
						'name' => q(kvadrataj futoj),
						'one' => q({0} kvadrata futo),
						'other' => q({0} kvadrataj futoj),
					},
					'square-inch' => {
						'name' => q(kvadrataj coloj),
						'one' => q({0} kvadrata colo),
						'other' => q({0} kvadrataj coloj),
					},
					'square-kilometer' => {
						'name' => q(kvadrataj kilometroj),
						'one' => q({0} kvadrata kilometro),
						'other' => q({0} kvadrataj kilometroj),
					},
					'square-meter' => {
						'name' => q(kvadrataj metroj),
						'one' => q({0} kvadrata metro),
						'other' => q({0} kvadrataj metroj),
					},
					'square-mile' => {
						'name' => q(kvadrataj mejloj),
						'one' => q({0} kvadrata mejlo),
						'other' => q({0} kvadrataj mejloj),
					},
					'square-yard' => {
						'name' => q(kvadrataj jardoj),
						'one' => q({0} kvadrata jardo),
						'other' => q({0} kvadrataj jardoj),
					},
					'terabit' => {
						'name' => q(terabitoj),
						'one' => q({0} terabito),
						'other' => q({0} terabitoj),
					},
					'terabyte' => {
						'name' => q(terabajtoj),
						'one' => q({0} terabajto),
						'other' => q({0} terabajtoj),
					},
					'week' => {
						'name' => q(semajnoj),
						'one' => q({0} semajno),
						'other' => q({0} semajnoj),
					},
					'yard' => {
						'name' => q(jardoj),
						'one' => q({0} jardo),
						'other' => q({0} jardoj),
					},
					'year' => {
						'name' => q(jaroj),
						'one' => q({0} jaro),
						'other' => q({0} jaroj),
					},
				},
				'narrow' => {
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0}au),
						'other' => q({0}au),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'day' => {
						'name' => q(t.),
						'one' => q({0}t.),
						'other' => q({0}t.),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hour' => {
						'name' => q(h.),
						'one' => q({0}h.),
						'other' => q({0}h.),
						'per' => q({0}/h.),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					'light-year' => {
						'name' => q(lj),
						'one' => q({0}lj),
						'other' => q({0}lj),
					},
					'liter' => {
						'name' => q(L),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0}µm),
						'other' => q({0}µm),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(ms.),
						'one' => q({0}ms.),
						'other' => q({0}ms.),
					},
					'minute' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'second' => {
						'name' => q(s.),
						'one' => q({0}s.),
						'other' => q({0}s.),
						'per' => q({0}/s.),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					'year' => {
						'name' => q(j.),
						'one' => q({0}j.),
						'other' => q({0}j.),
					},
				},
				'short' => {
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'day' => {
						'name' => q(tago),
						'one' => q({0} t.),
						'other' => q({0} t.),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hour' => {
						'name' => q(horo),
						'one' => q({0} h.),
						'other' => q({0} h.),
						'per' => q({0}/h.),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					'liter' => {
						'name' => q(L),
						'one' => q({0} L),
						'other' => q({0} L),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(milisekundo),
						'one' => q({0} ms.),
						'other' => q({0} ms.),
					},
					'minute' => {
						'name' => q(minuto),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					'month' => {
						'name' => q(monato),
						'one' => q({0} mon.),
						'other' => q({0} mon.),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'second' => {
						'name' => q(sekundo),
						'one' => q({0} s.),
						'other' => q({0} s.),
						'per' => q({0}/s.),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'week' => {
						'name' => q(semajno),
					},
					'year' => {
						'name' => q(jaro),
						'one' => q({0} j.),
						'other' => q({0} j.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jes|j|yes|y)$' }
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
				end => q({0} kaj {1}),
				2 => q({0} kaj {1}),
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'infinity' => q(∞),
			'minusSign' => q(−),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Aŭstralia dolaro),
				'one' => q(aŭstralia dolaro),
				'other' => q(aŭstraliaj dolaroj),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brazila realo),
				'one' => q(brazila realo),
				'other' => q(brazilaj realoj),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanada dolaro),
				'one' => q(kanada dolaro),
				'other' => q(kanadaj dolaroj),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Svisa franko),
				'one' => q(svisa franko),
				'other' => q(svisaj frankoj),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Ĉina juano),
				'one' => q(ĉina juano),
				'other' => q(ĉinaj juanoj),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Dana krono),
				'one' => q(dana krono),
				'other' => q(danaj kronoj),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Eŭro),
				'one' => q(eŭro),
				'other' => q(eŭroj),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Brita pundo),
				'one' => q(brita pundo),
				'other' => q(britaj pundoj),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Honkonga dolaro),
				'one' => q(honkonga dolaro),
				'other' => q(honkongaj dolaroj),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonezia rupio),
				'one' => q(Indonezia rupio),
				'other' => q(Indoneziaj rupioj),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Barata rupio),
				'one' => q(barata rupio),
				'other' => q(barataj rupioj),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Japana eno),
				'one' => q(japana eno),
				'other' => q(japanaj enoj),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Sud-korea ŭono),
				'one' => q(sud-korea ŭono),
				'other' => q(sud-koreaj ŭonoj),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Meksika peso),
				'one' => q(meksika peso),
				'other' => q(meksikaj pesoj),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norvega krono),
				'one' => q(norvega krono),
				'other' => q(norvegaj kronoj),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Pola zloto),
				'one' => q(pola zloto),
				'other' => q(polaj zlotoj),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rusa rublo),
				'one' => q(rusa rublo),
				'other' => q(rusaj rubloj),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Sauda rialo),
				'one' => q(sauda rialo),
				'other' => q(saudaj rialoj),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Sveda krono),
				'one' => q(sveda krono),
				'other' => q(svedaj kronoj),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Taja bahto),
				'one' => q(taja bahto),
				'other' => q(tajaj bahtoj),
			},
		},
		'TRY' => {
			symbol => '₺',
			display_name => {
				'currency' => q(Turka liro),
				'one' => q(turka liro),
				'other' => q(turkaj liroj),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nova tajvana dolaro),
				'one' => q(nova tajvana dolaro),
				'other' => q(novaj tajvanaj dolaroj),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Usona dolaro),
				'one' => q(usona dolaro),
				'other' => q(usonaj dolaroj),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(arĝento),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(oro),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(eŭropa monunuo),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franca ora franko),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladio),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(plateno),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nekonata valuto),
				'one' => q(nekonata monunuo),
				'other' => q(nekonataj monunuoj),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Sud-afrika rando),
				'one' => q(sud-afrika rando),
				'other' => q(sud-afrikaj randoj),
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
							'aŭg',
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
							'januaro',
							'februaro',
							'marto',
							'aprilo',
							'majo',
							'junio',
							'julio',
							'aŭgusto',
							'septembro',
							'oktobro',
							'novembro',
							'decembro'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
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
							'januaro',
							'februaro',
							'marto',
							'aprilo',
							'majo',
							'junio',
							'julio',
							'aŭgusto',
							'septembro',
							'oktobro',
							'novembro',
							'decembro'
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
						mon => 'lu',
						tue => 'ma',
						wed => 'me',
						thu => 'ĵa',
						fri => 've',
						sat => 'sa',
						sun => 'di'
					},
					wide => {
						mon => 'lundo',
						tue => 'mardo',
						wed => 'merkredo',
						thu => 'ĵaŭdo',
						fri => 'vendredo',
						sat => 'sabato',
						sun => 'dimanĉo'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'Ĵ',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					wide => {
						mon => 'lundo',
						tue => 'mardo',
						wed => 'merkredo',
						thu => 'ĵaŭdo',
						fri => 'vendredo',
						sat => 'sabato',
						sun => 'dimanĉo'
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
					wide => {0 => '1-a kvaronjaro',
						1 => '2-a kvaronjaro',
						2 => '3-a kvaronjaro',
						3 => '4-a kvaronjaro'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-a kvaronjaro',
						1 => '2-a kvaronjaro',
						2 => '3-a kvaronjaro',
						3 => '4-a kvaronjaro'
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
				'wide' => {
					'am' => q{atm},
					'pm' => q{ptm},
				},
				'narrow' => {
					'pm' => q{p},
					'am' => q{a},
				},
				'abbreviated' => {
					'pm' => q{ptm},
					'am' => q{atm},
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
				'0' => 'aK',
				'1' => 'pK'
			},
			narrow => {
				'0' => 'aK',
				'1' => 'pK'
			},
			wide => {
				'0' => 'aK',
				'1' => 'pK'
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
			'full' => q{EEEE, d-'a' 'de' MMMM y G},
			'long' => q{G y-MMMM-dd},
			'medium' => q{G y-MMM-dd},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, d-'a' 'de' MMMM y},
			'long' => q{y-MMMM-dd},
			'medium' => q{y-MMM-dd},
			'short' => q{yy-MM-dd},
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
			'full' => q{H-'a' 'horo' 'kaj' m:ss zzzz},
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
		},
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Ed => q{E d},
			MMMEd => q{E 'la' d-'an' 'de' MMM},
			MMMd => q{d MMM},
			d => q{d},
			y => q{y},
			yMMM => q{MMM y},
			yMMMEd => q{E 'la' d-'an' 'de' MMM y},
			yMMMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
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
				M => q{E, MM-dd – E, MM-dd},
				d => q{E, MM-dd – E, MM-dd},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM-dd – E, MMM-dd},
				d => q{E, MMM-dd – E, MMM-dd},
			},
			MMMd => {
				M => q{MMM-dd – MMM-dd},
				d => q{MMM-dd – MMM-dd},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				y => q{G y–y},
			},
			yM => {
				M => q{G y-MM – y-MM},
				y => q{G y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{G y-MMM – y-MMM},
				y => q{G y-MMM – y-MMM},
			},
			yMMMEd => {
				M => q{E, d-'a' 'de' MMM – E, d-'a' 'de' MMM y G},
				d => q{E, d-'a' - E, d-'a' 'de' MMM y G},
				y => q{E, d-'a' 'de' MMM y – E, d-'a' 'de' MMM y G},
			},
			yMMMd => {
				M => q{G y-MMM-dd – y-MMM-dd},
				d => q{G y-MMM-dd – y-MMM-dd},
				y => q{G y-MMM-dd – y-MMM-dd},
			},
			yMd => {
				M => q{G y-MM-dd – y-MM-dd},
				d => q{G y-MM-dd – y-MM-dd},
				y => q{G y-MM-dd – y-MM-dd},
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
				M => q{E, MM-dd – E, MM-dd},
				d => q{E, MM-dd – E, MM-dd},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM-dd – E, MMM-dd},
				d => q{E, MMM-dd – E, MMM-dd},
			},
			MMMd => {
				M => q{MMM-dd – MMM-dd},
				d => q{MMM-dd – MMM-dd},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				y => q{y–y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{E, y-MM-dd – E, y-MM-dd},
				d => q{E, y-MM-dd – E, y-MM-dd},
				y => q{E, y-MM-dd – E, y-MM-dd},
			},
			yMMM => {
				M => q{y-MMM – y-MMM},
				y => q{y-MMM – y-MMM},
			},
			yMMMEd => {
				M => q{E, d-'a' 'de' MMM – E, d-'a' 'de' MMM y},
				d => q{E, d-'a' - E, d-'a' 'de' MMM y},
				y => q{E, d-'a' 'de' MMM y – E, d-'a' 'de' MMM y},
			},
			yMMMd => {
				M => q{y-MMM-dd – y-MMM-dd},
				d => q{y-MMM-dd – y-MMM-dd},
				y => q{y-MMM-dd – y-MMM-dd},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(tempo de {0}),
		regionFormat => q(somera tempo de {0}),
		regionFormat => q(norma tempo de {0}),
		fallbackFormat => q({1} ({0})),
		'Africa_Central' => {
			long => {
				'standard' => q#centra afrika tempo#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#orienta afrika tempo#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#suda afrika tempo#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#okcidenta afrika somera tempo#,
				'generic' => q#okcidenta afrika tempo#,
				'standard' => q#okcidenta afrika norma tempo#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#centra nord-amerika somera tempo#,
				'generic' => q#centra nord-amerika tempo#,
				'standard' => q#centra nord-amerika norma tempo#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#orienta nord-amerika somera tempo#,
				'generic' => q#orienta nord-amerika tempo#,
				'standard' => q#orienta nord-amerika norma tempo#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#monta nord-amerika somera tempo#,
				'generic' => q#monta nord-amerika tempo#,
				'standard' => q#monta nord-amerika norma tempo#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#pacifika nord-amerika somera tempo#,
				'generic' => q#pacifika nord-amerika tempo#,
				'standard' => q#pacifika nord-amerika norma tempo#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#araba somera tempo#,
				'generic' => q#araba tempo#,
				'standard' => q#araba norma tempo#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlantika nord-amerika somera tempo#,
				'generic' => q#atlantika nord-amerika tempo#,
				'standard' => q#atlantika nord-amerika norma tempo#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#centra aŭstralia somera tempo#,
				'generic' => q#centra aŭstralia tempo#,
				'standard' => q#centra aŭstralia norma tempo#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#centrokcidenta aŭstralia somera tempo#,
				'generic' => q#centrokcidenta aŭstralia tempo#,
				'standard' => q#centrokcidenta aŭstralia norma tempo#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#orienta aŭstralia somera tempo#,
				'generic' => q#orienta aŭstralia tempo#,
				'standard' => q#orienta aŭstralia norma tempo#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#okcidenta aŭstralia somera tempo#,
				'generic' => q#okcidenta aŭstralia tempo#,
				'standard' => q#okcidenta aŭstralia norma tempo#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ĉina somera tempo#,
				'generic' => q#ĉina tempo#,
				'standard' => q#ĉina norma tempo#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#nekonata urbo#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#centra eŭropa somera tempo#,
				'generic' => q#centra eŭropa tempo#,
				'standard' => q#centra eŭropa norma tempo#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#orienta eŭropa somera tempo#,
				'generic' => q#orienta eŭropa tempo#,
				'standard' => q#orienta eŭropa norma tempo#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#okcidenta eŭropa somera tempo#,
				'generic' => q#okcidenta eŭropa tempo#,
				'standard' => q#okcidenta eŭropa norma tempo#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#universala tempo kunordigita#,
			},
		},
		'India' => {
			long => {
				'standard' => q#barata tempo#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#hindoĉina tempo#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#centra indonezia tempo#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#orienta indonezia tempo#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#okcidenta indonezia tempo#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israela somera tempo#,
				'generic' => q#israela tempo#,
				'standard' => q#israela norma tempo#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japana somera tempo#,
				'generic' => q#japana tempo#,
				'standard' => q#japana norma tempo#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#korea somera tempo#,
				'generic' => q#korea tempo#,
				'standard' => q#korea norma tempo#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#moskva somera tempo#,
				'generic' => q#moskva tempo#,
				'standard' => q#moskva norma tempo#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
