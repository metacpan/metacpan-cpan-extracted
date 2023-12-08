=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Yo - Package for language Yoruba

=cut

package Locale::CLDR::Locales::Yo;
# This file auto generated from Data\common\main\yo.xml
#	on Tue  5 Dec  1:38:08 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'af' => 'Èdè Afrikani',
 				'ak' => 'Èdè Akani',
 				'am' => 'Èdè Amariki',
 				'ar' => 'Èdè Arabiki',
 				'as' => 'Ti Assam',
 				'az' => 'Èdè Azerbaijani',
 				'be' => 'Èdè Belarusi',
 				'bg' => 'Èdè Bugaria',
 				'bn' => 'Èdè Bengali',
 				'br' => 'Èdè Bretoni',
 				'bs' => 'Èdè Bosnia',
 				'ca' => 'Èdè Catala',
 				'cs' => 'Èdè seeki',
 				'cy' => 'Èdè Welshi',
 				'da' => 'Èdè Ilẹ̀ Denmark',
 				'de' => 'Èdè Ilẹ̀ Gemani',
 				'el' => 'Èdè Giriki',
 				'en' => 'Èdè Gẹ̀ẹ́sì',
 				'eo' => 'Èdè Esperanto',
 				'es' => 'Èdè Sipanisi',
 				'et' => 'Èdè Estonia',
 				'eu' => 'Èdè Baski',
 				'fa' => 'Èdè Pasia',
 				'fi' => 'Èdè Finisi',
 				'fil' => 'Èdè Filipino',
 				'fo' => 'Èdè Faroesi',
 				'fr' => 'Èdè Faransé',
 				'fy' => 'Èdè Frisia',
 				'ga' => 'Èdè Ireland',
 				'gd' => 'Èdè Gaelik ti Ilu Scotland',
 				'gl' => 'Èdè Galicia',
 				'gn' => 'Èdè Guarani',
 				'gu' => 'Èdè Gujarati',
 				'ha' => 'Èdè Hausa',
 				'he' => 'Èdè Heberu',
 				'hi' => 'Èdè Hindi',
 				'hr' => 'Èdè Kroatia',
 				'hu' => 'Èdè Hungaria',
 				'hy' => 'Èdè Ile Armenia',
 				'ia' => 'Èdè pipo',
 				'id' => 'Èdè Indonasia',
 				'ie' => 'Iru Èdè',
 				'ig' => 'Èdè Ibo',
 				'is' => 'Èdè Icelandic',
 				'it' => 'Èdè Italiani',
 				'ja' => 'Èdè Japanisi',
 				'jv' => 'Èdè Javanasi',
 				'ka' => 'Èdè Georgia',
 				'km' => 'Èdè kameri',
 				'kn' => 'Èdè Kannada',
 				'ko' => 'Èdè Koria',
 				'la' => 'Èdè Latini',
 				'lt' => 'Èdè Lithuania',
 				'lv' => 'Èdè Latvianu',
 				'mk' => 'Èdè Macedonia',
 				'mr' => 'Èdè marathi',
 				'ms' => 'Èdè Malaya',
 				'mt' => 'Èdè Malta',
 				'my' => 'Èdè Bumiisi',
 				'ne' => 'Èdè Nepali',
 				'nl' => 'Èdè Duki',
 				'no' => 'Èdè Norway',
 				'oc' => 'Èdè Occitani',
 				'pa' => 'Èdè Punjabi',
 				'pl' => 'Èdè Ilẹ̀ Polandi',
 				'pt' => 'Èdè Pọtugi',
 				'ro' => 'Èdè Romania',
 				'ru' => 'Èdè ̣Rọọsia',
 				'rw' => 'Èdè Ruwanda',
 				'sa' => 'Èdè awon ara Indo',
 				'sd' => 'Èdè Sindhi',
 				'sh' => 'Èdè Serbo-Croatiani',
 				'si' => 'Èdè Sinhalese',
 				'sk' => 'Èdè Slovaki',
 				'sl' => 'Èdè Slovenia',
 				'so' => 'Èdè ara Somalia',
 				'sq' => 'Èdè Albania',
 				'sr' => 'Èdè Serbia',
 				'st' => 'Èdè Sesoto',
 				'su' => 'Èdè Sudani',
 				'sv' => 'Èdè Suwidiisi',
 				'sw' => 'Èdè Swahili',
 				'ta' => 'Èdè Tamili',
 				'te' => 'Èdè Telugu',
 				'th' => 'Èdè Tai',
 				'ti' => 'Èdè Tigrinya',
 				'tk' => 'Èdè Turkmen',
 				'tlh' => 'Èdè Klingoni',
 				'tr' => 'Èdè Tọọkisi',
 				'uk' => 'Èdè Ukania',
 				'ur' => 'Èdè Udu',
 				'uz' => 'Èdè Uzbek',
 				'vi' => 'Èdè Jetinamu',
 				'xh' => 'Èdè Xhosa',
 				'yi' => 'Èdè Yiddishi',
 				'yo' => 'Èdè Yorùbá',
 				'zh' => 'Èdè Mandari',
 				'zu' => 'Èdè Ṣulu',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'AD' => 'Orílẹ́ède Ààndórà',
 			'AE' => 'Orílẹ́ède Ẹmirate ti Awọn Arabu',
 			'AF' => 'Orílẹ́ède Àfùgànístánì',
 			'AG' => 'Orílẹ́ède Ààntígúà àti Báríbúdà',
 			'AI' => 'Orílẹ́ède Ààngúlílà',
 			'AL' => 'Orílẹ́ède Àlùbàníánì',
 			'AM' => 'Orílẹ́ède Améníà',
 			'AO' => 'Orílẹ́ède Ààngólà',
 			'AR' => 'Orílẹ́ède Agentínà',
 			'AS' => 'Sámóánì ti Orílẹ́ède Àméríkà',
 			'AT' => 'Orílẹ́ède Asítíríà',
 			'AU' => 'Orílẹ́ède Ástràlìá',
 			'AW' => 'Orílẹ́ède Árúbà',
 			'AZ' => 'Orílẹ́ède Asẹ́bájánì',
 			'BA' => 'Orílẹ́ède Bọ̀síníà àti Ẹtisẹgófínà',
 			'BB' => 'Orílẹ́ède Bábádósì',
 			'BD' => 'Orílẹ́ède Bángáládésì',
 			'BE' => 'Orílẹ́ède Bégíọ́mù',
 			'BF' => 'Orílẹ́ède Bùùkíná Fasò',
 			'BG' => 'Orílẹ́ède Bùùgáríà',
 			'BH' => 'Orílẹ́ède Báránì',
 			'BI' => 'Orílẹ́ède Bùùrúndì',
 			'BJ' => 'Orílẹ́ède Bẹ̀nẹ̀',
 			'BM' => 'Orílẹ́ède Bémúdà',
 			'BN' => 'Orílẹ́ède Búrúnẹ́lì',
 			'BO' => 'Orílẹ́ède Bọ̀lífíyà',
 			'BR' => 'Orílẹ́ède Bàràsílì',
 			'BS' => 'Orílẹ́ède Bàhámásì',
 			'BT' => 'Orílẹ́ède Bútánì',
 			'BW' => 'Orílẹ́ède Bọ̀tìsúwánà',
 			'BY' => 'Orílẹ́ède Bélárúsì',
 			'BZ' => 'Orílẹ́ède Bèlísẹ̀',
 			'CA' => 'Orílẹ́ède Kánádà',
 			'CD' => 'Orilẹ́ède Kóngò',
 			'CF' => 'Orílẹ́ède Àrin gùngun Áfíríkà',
 			'CG' => 'Orílẹ́ède Kóngò',
 			'CH' => 'Orílẹ́ède switiṣilandi',
 			'CI' => 'Orílẹ́ède Kóútè forà',
 			'CK' => 'Orílẹ́ède Etíokun Kùúkù',
 			'CL' => 'Orílẹ́ède ṣílè',
 			'CM' => 'Orílẹ́ède Kamerúúnì',
 			'CN' => 'Orílẹ́ède ṣáínà',
 			'CO' => 'Orílẹ́ède Kòlómíbìa',
 			'CR' => 'Orílẹ́ède Kuusita Ríkà',
 			'CU' => 'Orílẹ́ède Kúbà',
 			'CV' => 'Orílẹ́ède Etíokun Kápé féndè',
 			'CY' => 'Orílẹ́ède Kúrúsì',
 			'CZ' => 'Orílẹ́ède ṣẹ́ẹ́kì',
 			'DE' => 'Orílẹ́ède Gemani',
 			'DJ' => 'Orílẹ́ède Díbọ́ótì',
 			'DK' => 'Orílẹ́ède Dẹ́mákì',
 			'DM' => 'Orílẹ́ède Dòmíníkà',
 			'DO' => 'Orilẹ́ède Dòmíníkánì',
 			'DZ' => 'Orílẹ́ède Àlùgèríánì',
 			'EC' => 'Orílẹ́ède Ekuádò',
 			'EE' => 'Orílẹ́ède Esitonia',
 			'EG' => 'Orílẹ́ède Égípítì',
 			'ER' => 'Orílẹ́ède Eritira',
 			'ES' => 'Orílẹ́ède Sipani',
 			'ET' => 'Orílẹ́ède Etopia',
 			'FI' => 'Orílẹ́ède Filandi',
 			'FJ' => 'Orílẹ́ède Fiji',
 			'FK' => 'Orílẹ́ède Etikun Fakalandi',
 			'FM' => 'Orílẹ́ède Makoronesia',
 			'FR' => 'Orílẹ́ède Faranse',
 			'GA' => 'Orílẹ́ède Gabon',
 			'GB' => 'Orílẹ́ède Omobabirin',
 			'GD' => 'Orílẹ́ède Genada',
 			'GE' => 'Orílẹ́ède Gọgia',
 			'GF' => 'Orílẹ́ède Firenṣi Guana',
 			'GH' => 'Orílẹ́ède Gana',
 			'GI' => 'Orílẹ́ède Gibaratara',
 			'GL' => 'Orílẹ́ède Gerelandi',
 			'GM' => 'Orílẹ́ède Gambia',
 			'GN' => 'Orílẹ́ède Gene',
 			'GP' => 'Orílẹ́ède Gadelope',
 			'GQ' => 'Orílẹ́ède Ekutoria Gini',
 			'GR' => 'Orílẹ́ède Geriisi',
 			'GT' => 'Orílẹ́ède Guatemala',
 			'GU' => 'Orílẹ́ède Guamu',
 			'GW' => 'Orílẹ́ède Gene-Busau',
 			'GY' => 'Orílẹ́ède Guyana',
 			'HN' => 'Orílẹ́ède Hondurasi',
 			'HR' => 'Orílẹ́ède Kòróátíà',
 			'HT' => 'Orílẹ́ède Haati',
 			'HU' => 'Orílẹ́ède Hungari',
 			'ID' => 'Orílẹ́ède Indonesia',
 			'IE' => 'Orílẹ́ède Ailandi',
 			'IL' => 'Orílẹ́ède Iserẹli',
 			'IN' => 'Orílẹ́ède India',
 			'IO' => 'Orílẹ́ède Etíkun Índíánì ti Ìlú Bírítísì',
 			'IQ' => 'Orílẹ́ède Iraki',
 			'IR' => 'Orílẹ́ède Irani',
 			'IS' => 'Orílẹ́ède Aṣilandi',
 			'IT' => 'Orílẹ́ède Italiyi',
 			'JM' => 'Orílẹ́ède Jamaika',
 			'JO' => 'Orílẹ́ède Jọdani',
 			'JP' => 'Orílẹ́ède Japani',
 			'KE' => 'Orílẹ́ède Kenya',
 			'KG' => 'Orílẹ́ède Kuriṣisitani',
 			'KH' => 'Orílẹ́ède Kàmùbódíà',
 			'KI' => 'Orílẹ́ède Kiribati',
 			'KM' => 'Orílẹ́ède Kòmòrósì',
 			'KN' => 'Orílẹ́ède Kiiti ati Neefi',
 			'KP' => 'Orílẹ́ède Guusu Kọria',
 			'KR' => 'Orílẹ́ède Ariwa Kọria',
 			'KW' => 'Orílẹ́ède Kuweti',
 			'KY' => 'Orílẹ́ède Etíokun Kámánì',
 			'KZ' => 'Orílẹ́ède Kaṣaṣatani',
 			'LA' => 'Orílẹ́ède Laosi',
 			'LB' => 'Orílẹ́ède Lebanoni',
 			'LC' => 'Orílẹ́ède Luṣia',
 			'LI' => 'Orílẹ́ède Lẹṣitẹnisiteni',
 			'LK' => 'Orílẹ́ède Siri Lanka',
 			'LR' => 'Orílẹ́ède Laberia',
 			'LS' => 'Orílẹ́ède Lesoto',
 			'LT' => 'Orílẹ́ède Lituania',
 			'LU' => 'Orílẹ́ède Lusemogi',
 			'LV' => 'Orílẹ́ède Latifia',
 			'LY' => 'Orílẹ́ède Libiya',
 			'MA' => 'Orílẹ́ède Moroko',
 			'MC' => 'Orílẹ́ède Monako',
 			'MD' => 'Orílẹ́ède Modofia',
 			'MG' => 'Orílẹ́ède Madasika',
 			'MH' => 'Orílẹ́ède Etikun Máṣali',
 			'MK' => 'Orílẹ́ède Masidonia',
 			'ML' => 'Orílẹ́ède Mali',
 			'MM' => 'Orílẹ́ède Manamari',
 			'MN' => 'Orílẹ́ède Mogolia',
 			'MP' => 'Orílẹ́ède Etikun Guusu Mariana',
 			'MQ' => 'Orílẹ́ède Matinikuwi',
 			'MR' => 'Orílẹ́ède Maritania',
 			'MS' => 'Orílẹ́ède Motserati',
 			'MT' => 'Orílẹ́ède Malata',
 			'MU' => 'Orílẹ́ède Maritiusi',
 			'MV' => 'Orílẹ́ède Maladifi',
 			'MW' => 'Orílẹ́ède Malawi',
 			'MX' => 'Orílẹ́ède Mesiko',
 			'MY' => 'Orílẹ́ède Malasia',
 			'MZ' => 'Orílẹ́ède Moṣamibiku',
 			'NA' => 'Orílẹ́ède Namibia',
 			'NC' => 'Orílẹ́ède Kaledonia Titun',
 			'NE' => 'Orílẹ́ède Nàìjá',
 			'NF' => 'Orílẹ́ède Etikun Nọ́úfókì',
 			'NG' => 'Orílẹ́ède Nàìjíríà',
 			'NI' => 'Orílẹ́ède NIkaragua',
 			'NL' => 'Orílẹ́ède Nedalandi',
 			'NO' => 'Orílẹ́ède Nọọwii',
 			'NP' => 'Orílẹ́ède Nepa',
 			'NR' => 'Orílẹ́ède Nauru',
 			'NU' => 'Orílẹ́ède Niue',
 			'NZ' => 'Orílẹ́ède ṣilandi Titun',
 			'OM' => 'Orílẹ́ède Ọọma',
 			'PA' => 'Orílẹ́ède Panama',
 			'PE' => 'Orílẹ́ède Peru',
 			'PF' => 'Orílẹ́ède Firenṣi Polinesia',
 			'PG' => 'Orílẹ́ède Paapu ti Giini',
 			'PH' => 'Orílẹ́ède filipini',
 			'PK' => 'Orílẹ́ède Pakisitan',
 			'PL' => 'Orílẹ́ède Polandi',
 			'PM' => 'Orílẹ́ède Pẹẹri ati mikuloni',
 			'PN' => 'Orílẹ́ède Pikarini',
 			'PR' => 'Orílẹ́ède Pọto Riko',
 			'PS' => 'Orílẹ́ède Iwọorun Pakisitian ati Gaṣa',
 			'PT' => 'Orílẹ́ède Pọtugi',
 			'PW' => 'Orílẹ́ède Paalu',
 			'PY' => 'Orílẹ́ède Paraguye',
 			'QA' => 'Orílẹ́ède Kota',
 			'RE' => 'Orílẹ́ède Riuniyan',
 			'RO' => 'Orílẹ́ède Romaniya',
 			'RU' => 'Orílẹ́ède Rọṣia',
 			'RW' => 'Orílẹ́ède Ruwanda',
 			'SA' => 'Orílẹ́ède Saudi Arabia',
 			'SB' => 'Orílẹ́ède Etikun Solomoni',
 			'SC' => 'Orílẹ́ède seṣẹlẹsi',
 			'SD' => 'Orílẹ́ède Sudani',
 			'SE' => 'Orílẹ́ède Swidini',
 			'SG' => 'Orílẹ́ède Singapo',
 			'SH' => 'Orílẹ́ède Hẹlena',
 			'SI' => 'Orílẹ́ède Silofania',
 			'SK' => 'Orílẹ́ède Silofakia',
 			'SL' => 'Orílẹ́ède Siria looni',
 			'SM' => 'Orílẹ́ède Sani Marino',
 			'SN' => 'Orílẹ́ède Sẹnẹga',
 			'SO' => 'Orílẹ́ède Somalia',
 			'SR' => 'Orílẹ́ède Surinami',
 			'SS' => 'Gúúsù Sudan',
 			'ST' => 'Orílẹ́ède Sao tomi ati piriiṣipi',
 			'SV' => 'Orílẹ́ède Ẹẹsáfádò',
 			'SY' => 'Orílẹ́ède Siria',
 			'SZ' => 'Orílẹ́ède Saṣiland',
 			'TC' => 'Orílẹ́ède Tọọki ati Etikun Kakọsi',
 			'TD' => 'Orílẹ́ède ṣààdì',
 			'TG' => 'Orílẹ́ède Togo',
 			'TH' => 'Orílẹ́ède Tailandi',
 			'TJ' => 'Orílẹ́ède Takisitani',
 			'TK' => 'Orílẹ́ède Tokelau',
 			'TL' => 'Orílẹ́ède ÌlàOòrùn Tímọ̀',
 			'TM' => 'Orílẹ́ède Tọọkimenisita',
 			'TN' => 'Orílẹ́ède Tuniṣia',
 			'TO' => 'Orílẹ́ède Tonga',
 			'TR' => 'Orílẹ́ède Tọọki',
 			'TT' => 'Orílẹ́ède Tirinida ati Tobaga',
 			'TV' => 'Orílẹ́ède Tufalu',
 			'TW' => 'Orílẹ́ède Taiwani',
 			'TZ' => 'Orílẹ́ède Tanṣania',
 			'UA' => 'Orílẹ́ède Ukarini',
 			'UG' => 'Orílẹ́ède Uganda',
 			'US' => 'Orílẹ́ède Orilẹede Amerika',
 			'UY' => 'Orílẹ́ède Nruguayi',
 			'UZ' => 'Orílẹ́ède Nṣibẹkisitani',
 			'VA' => 'Ìlú Vatican',
 			'VC' => 'Orílẹ́ède Fisẹnnti ati Genadina',
 			'VE' => 'Orílẹ́ède Fẹnẹṣuẹla',
 			'VG' => 'Orílẹ́ède Etíkun Fágínì ti ìlú Bírítísì',
 			'VI' => 'Orílẹ́ède Etikun Fagini ti Amẹrika',
 			'VN' => 'Orílẹ́ède Fẹtinami',
 			'VU' => 'Orílẹ́ède Faniatu',
 			'WF' => 'Orílẹ́ède Wali ati futuna',
 			'WS' => 'Orílẹ́ède Samọ',
 			'YE' => 'Orílẹ́ède yemeni',
 			'YT' => 'Orílẹ́ède Mayote',
 			'ZA' => 'Orílẹ́ède Ariwa Afirika',
 			'ZM' => 'Orílẹ́ède ṣamibia',
 			'ZW' => 'Orílẹ́ède ṣimibabe',

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
			auxiliary => qr{[c q v x z]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'],
			main => qr{[a á à b d e é è ẹ {ẹ́} {ẹ̀} f g {gb} h i í ì j k l m n o ó ò ọ {ọ́} {ọ̀} p r s ṣ t u ú ù w y]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'], };
},
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

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Bẹ́ẹ̀ni |N|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Bẹ́ẹ̀kọ́|K)$' }
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
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
		'AED' => {
			display_name => {
				'currency' => q(Diami ti Awon Orílẹ́ède Arabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Wansa ti Orílẹ́ède Àngólà),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Ástràlìá),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Báránì),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Bùùrúndì),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ti Orílẹ́ède Bọ̀tìsúwánà),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Kánádà),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Kóngò),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Siwisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Reminibi ti Orílẹ́ède ṣáínà),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kabofediano ti Orílẹ́ède Esuodo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Dibouti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Àlùgèríánì),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(pọọn ti Orílẹ́ède Egipiti),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakifa ti Orílẹ́ède Eriteriani),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Biri ti Orílẹ́ède Eutopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Uro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pọọn ti Orílẹ́ède Bírítísì),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ṣidi ti Orílẹ́ède Gana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ti Orílẹ́ède Gamibia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Gini),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi ti Orílẹ́ède Indina),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ti Orílẹ́ède Japani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(ṣiili ti Orílẹ́ède Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède ṣomoriani),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ti Orílẹ́ède Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Libiya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirami ti Orílẹ́ède Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Malagasi),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya ti Orílẹ́ède Maritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya ti Orílẹ́ède Maritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupi ti Orílẹ́ède Maritiusi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kaṣa ti Orílẹ́ède Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metika ti Orílẹ́ède Mosamibiki),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Namibia),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Naira ti Orílẹ́ède Nàìjíríà),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Ruwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riya ti Orílẹ́ède Saudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupi ti Orílẹ́ède Sayiselesi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Sudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pọọun ti Orílẹ́ède Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pọọun ti Orílẹ́ède ̣Elena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Lioni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Sile ti Orílẹ́ède Somali),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobira ti Orílẹ́ède Sao tome Ati Pirisipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobira ti Orílẹ́ède Sao tome Ati Pirisipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Tunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Sile ti Orílẹ́ède Tansania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Siile ti Orílẹ́ède Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Amerika),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède BEKA),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède BIKEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi ti Orílẹ́ède Ariwa Afirika),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kawaṣa ti Orílẹ́ède Saabia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kawaṣa ti Orílẹ́ède Saabia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Siibabuwe),
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
							'Ṣẹ́rẹ́',
							'Èrèlè',
							'Ẹrẹ̀nà',
							'Ìgbé',
							'Ẹ̀bibi',
							'Òkúdu',
							'Agẹmọ',
							'Ògún',
							'Owewe',
							'Ọ̀wàrà',
							'Bélú',
							'Ọ̀pẹ̀'
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
							'Oṣù Ṣẹ́rẹ́',
							'Oṣù Èrèlè',
							'Oṣù Ẹrẹ̀nà',
							'Oṣù Ìgbé',
							'Oṣù Ẹ̀bibi',
							'Oṣù Òkúdu',
							'Oṣù Agẹmọ',
							'Oṣù Ògún',
							'Oṣù Owewe',
							'Oṣù Ọ̀wàrà',
							'Oṣù Bélú',
							'Oṣù Ọ̀pẹ̀'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ṣẹ́rẹ́',
							'Èrèlè',
							'Ẹrẹ̀nà',
							'Ìgbé',
							'Ẹ̀bibi',
							'Òkúdu',
							'Agẹmọ',
							'Ògún',
							'Owewe',
							'Ọ̀wàrà',
							'Bélú',
							'Ọ̀pẹ̀'
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
							'Oṣù Ṣẹ́rẹ́',
							'Oṣù Èrèlè',
							'Oṣù Ẹrẹ̀nà',
							'Oṣù Ìgbé',
							'Oṣù Ẹ̀bibi',
							'Oṣù Òkúdu',
							'Oṣù Agẹmọ',
							'Oṣù Ògún',
							'Oṣù Owewe',
							'Oṣù Ọ̀wàrà',
							'Oṣù Bélú',
							'Oṣù Ọ̀pẹ̀'
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
						mon => 'Ajé',
						tue => 'Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ẹtì',
						sat => 'Àbámẹ́ta',
						sun => 'Àìkú'
					},
					short => {
						mon => 'Ajé',
						tue => 'Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ẹtì',
						sat => 'Àbámẹ́ta',
						sun => 'Àìkú'
					},
					wide => {
						mon => 'Ọjọ́ Ajé',
						tue => 'Ọjọ́ Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ọjọ́ Ẹtì',
						sat => 'Ọjọ́ Àbámẹ́ta',
						sun => 'Ọjọ́ Àìkú'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Ajé',
						tue => 'Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ẹtì',
						sat => 'Àbámẹ́ta',
						sun => 'Àìkú'
					},
					short => {
						mon => 'Ajé',
						tue => 'Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ẹtì',
						sat => 'Àbámẹ́ta',
						sun => 'Àìkú'
					},
					wide => {
						mon => 'Ọjọ́ Ajé',
						tue => 'Ọjọ́ Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ọjọ́ Ẹtì',
						sat => 'Ọjọ́ Àbámẹ́ta',
						sun => 'Ọjọ́ Àìkú'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Kọ́tà Kínní',
						1 => 'Kọ́tà Kejì',
						2 => 'Kọ́à Keta',
						3 => 'Kọ́tà Kẹrin'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Kọ́tà Kínní',
						1 => 'Kọ́tà Kejì',
						2 => 'Kọ́à Keta',
						3 => 'Kọ́tà Kẹrin'
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
				'abbreviated' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
				},
				'narrow' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
				},
				'wide' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
				},
				'narrow' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
				},
				'wide' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
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
				'0' => 'BCE',
				'1' => 'LK'
			},
			wide => {
				'0' => 'Saju Kristi',
				'1' => 'Lehin Kristi'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
			'full' => q{HH:mm:ss zzzz},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMW => q{'week' W 'of' MMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'week' w 'of' Y},
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
