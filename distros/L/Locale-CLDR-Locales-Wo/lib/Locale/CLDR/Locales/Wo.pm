=encoding utf8

=head1

Locale::CLDR::Locales::Wo - Package for language Wolof

=cut

package Locale::CLDR::Locales::Wo;
# This file auto generated from Data/common/main/wo.xml
#	on Mon 11 Apr  5:41:11 pm GMT

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
				'af' => 'Afrikaans',
 				'am' => 'Amharik',
 				'ar' => 'Araab',
 				'as' => 'Asame',
 				'az' => 'Aserbayjane',
 				'ba' => 'Baskir',
 				'ban' => 'Bali',
 				'be' => 'Belaris',
 				'bem' => 'Bemba',
 				'bg' => 'Bilgaar',
 				'bn' => 'Baŋla',
 				'bo' => 'Tibetan',
 				'br' => 'Breton',
 				'bs' => 'Bosñak',
 				'ca' => 'Katalan',
 				'ceb' => 'Sibiyanoo',
 				'chm' => 'Mari',
 				'chr' => 'Ceroki',
 				'ckb' => 'Kurdi gu Diggu',
 				'co' => 'Kors',
 				'cs' => 'Cek',
 				'cy' => 'Wels',
 				'da' => 'Danuwa',
 				'de' => 'Almaa',
 				'dsb' => 'Sorab-Suuf',
 				'dv' => 'Diweyi',
 				'dz' => 'Dsongkaa',
 				'el' => 'Gereg',
 				'en' => 'Àngale',
 				'en_GB@alt=short' => 'Àngale (RI)',
 				'en_US@alt=short' => 'Àngale (ES)',
 				'eo' => 'Esperantoo',
 				'es' => 'Español',
 				'es_419' => 'Español (Amerik Latin)',
 				'et' => 'Estoñiye',
 				'eu' => 'Bask',
 				'fa' => 'Pers',
 				'ff' => 'Pël',
 				'fi' => 'Feylànde',
 				'fil' => 'Filipiye',
 				'fo' => 'Feroos',
 				'fr' => 'Farañse',
 				'ga' => 'Irlànde',
 				'gd' => 'Galuwaa bu Ekos',
 				'gl' => 'Galisiye',
 				'gn' => 'Garani',
 				'gu' => 'Gujarati',
 				'ha' => 'Hawsa',
 				'haw' => 'Hawaye',
 				'he' => 'Ebrë',
 				'hi' => 'Endo',
 				'hil' => 'Hiligaynon',
 				'hr' => 'Krowat',
 				'hsb' => 'Sorab-Kaw',
 				'ht' => 'Kereyolu Ayti',
 				'hu' => 'Ongruwaa',
 				'hy' => 'Armaniye',
 				'hz' => 'Herero',
 				'ibb' => 'Ibibiyo',
 				'id' => 'Endonesiye',
 				'ig' => 'Igbo',
 				'is' => 'Islànde',
 				'it' => 'Italiye',
 				'iu' => 'Inuktitit',
 				'ja' => 'Sapone',
 				'ka' => 'Sorsiye',
 				'kk' => 'Kasax',
 				'km' => 'Xmer',
 				'kn' => 'Kannadaa',
 				'ko' => 'Koreye',
 				'kok' => 'Konkani',
 				'kr' => 'Kanuri',
 				'kru' => 'Kuruks',
 				'ks' => 'Kashmiri',
 				'ku' => 'Kurdi',
 				'ky' => 'Kirgiis',
 				'la' => 'Latin',
 				'lb' => 'Liksàmbursuwaa',
 				'lo' => 'Laaw',
 				'lt' => 'Lituyaniye',
 				'lv' => 'Letoniye',
 				'men' => 'Mende',
 				'mg' => 'Malagasi',
 				'mi' => 'Mawri',
 				'mk' => 'Maseduwaane',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoliye',
 				'mni' => 'Manipuri',
 				'moh' => 'Mowak',
 				'mr' => 'Marati',
 				'ms' => 'Malay',
 				'mt' => 'Malt',
 				'my' => 'Birmes',
 				'ne' => 'Nepale',
 				'niu' => 'Niweyan',
 				'nl' => 'Neyerlànde',
 				'no' => 'Nerwesiye',
 				'ny' => 'Sewa',
 				'oc' => 'Ositan',
 				'om' => 'Oromo',
 				'or' => 'Oja',
 				'pa' => 'Punjabi',
 				'pap' => 'Papiyamento',
 				'pl' => 'Polone',
 				'ps' => 'Pasto',
 				'pt' => 'Purtugees',
 				'qu' => 'Kesuwa',
 				'quc' => 'Kishe',
 				'rm' => 'Romaas',
 				'ro' => 'Rumaniyee',
 				'ru' => 'Rus',
 				'rw' => 'Kinyarwànda',
 				'sa' => 'Sanskrit',
 				'sah' => 'Saxa',
 				'sat' => 'Santali',
 				'sd' => 'Sindi',
 				'se' => 'Penku Sami',
 				'si' => 'Sinala',
 				'sk' => 'Eslowaki (Eslowak)',
 				'sl' => 'Esloweniye',
 				'sma' => 'Sami gu Saalum',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Eskolt Sami',
 				'so' => 'Somali (làkk)',
 				'sq' => 'Albane',
 				'sr' => 'Serb',
 				'sv' => 'Suweduwaa',
 				'syr' => 'Siryak',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'tg' => 'Tajis',
 				'th' => 'Tay',
 				'ti' => 'Tigriña',
 				'tk' => 'Tirkmen',
 				'to' => 'Tongan',
 				'tr' => 'Tirk',
 				'tt' => 'Tatar',
 				'tzm' => 'Tamasis gu Digg Atlaas',
 				'ug' => 'Uygur',
 				'uk' => 'Ikreniye',
 				'und' => 'Làkk wuñ xamul',
 				'ur' => 'Urdu',
 				'uz' => 'Usbek',
 				've' => 'Wenda',
 				'vi' => 'Wiyetnaamiye',
 				'wo' => 'Wolof',
 				'yi' => 'Yidis',
 				'yo' => 'Yoruba',
 				'zh' => 'Sinuwaa',
 				'zh_Hans' => 'Sinuwaa buñ woyofal',
 				'zh_Hant' => 'Sinuwaa bu cosaan',

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
			'Arab' => 'Araab',
 			'Cyrl' => 'Sirilik',
 			'Hans' => 'Buñ woyofal',
 			'Hans@alt=stand-alone' => 'Han buñ woyofal',
 			'Hant' => 'Cosaan',
 			'Hant@alt=stand-alone' => 'Han u cosaan',
 			'Latn' => 'Latin',
 			'Zxxx' => 'Luñ bindul',
 			'Zzzz' => 'Mbind muñ xamul',

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
			'AD' => 'Andoor',
 			'AE' => 'Emira Arab Ini',
 			'AF' => 'Afganistaŋ',
 			'AG' => 'Antiguwa ak Barbuda',
 			'AI' => 'Angiiy',
 			'AL' => 'Albani',
 			'AM' => 'Armeni',
 			'AO' => 'Àngolaa',
 			'AQ' => 'Antarktik',
 			'AR' => 'Arsàntin',
 			'AS' => 'Samowa bu Amerig',
 			'AT' => 'Ótiriis',
 			'AU' => 'Ostarali',
 			'AW' => 'Aruba',
 			'AX' => 'Duni Aalànd',
 			'AZ' => 'Aserbayjaŋ',
 			'BA' => 'Bosni Ersegowin',
 			'BB' => 'Barbad',
 			'BD' => 'Bengalades',
 			'BE' => 'Belsig',
 			'BF' => 'Burkina Faaso',
 			'BG' => 'Bilgari',
 			'BH' => 'Bahreyin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benee',
 			'BL' => 'Saŋ Bartalemi',
 			'BM' => 'Bermid',
 			'BN' => 'Burney',
 			'BO' => 'Boliwi',
 			'BR' => 'Beresil',
 			'BS' => 'Bahamas',
 			'BT' => 'Butaŋ',
 			'BV' => 'Dunu Buwet',
 			'BW' => 'Botswana',
 			'BY' => 'Belaris',
 			'BZ' => 'Belis',
 			'CA' => 'Kanadaa',
 			'CC' => 'Duni Koko (Kilin)',
 			'CD@alt=variant' => 'Kongo (R K D)',
 			'CF' => 'Repiblik Sàntar Afrik',
 			'CG@alt=variant' => 'Réewum Kongo',
 			'CH' => 'Siwis',
 			'CI' => 'Kodiwaar (Côte d’Ivoire)',
 			'CK' => 'Duni Kuuk',
 			'CL' => 'Sili',
 			'CM' => 'Kamerun',
 			'CN' => 'Siin',
 			'CO' => 'Kolombi',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabo Werde',
 			'CW' => 'Kursawo',
 			'CX' => 'Dunu Kirismas',
 			'CY' => 'Siipar',
 			'CZ' => 'Réewum Cek',
 			'DE' => 'Almaañ',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danmàrk',
 			'DM' => 'Dominik',
 			'DO' => 'Repiblik Dominiken',
 			'DZ' => 'Alseri',
 			'EC' => 'Ekwaatër',
 			'EE' => 'Estoni',
 			'EG' => 'Esipt',
 			'ER' => 'Eritere',
 			'ES' => 'Españ',
 			'ET' => 'Ecopi',
 			'FI' => 'Finlànd',
 			'FJ' => 'Fijji',
 			'FK' => 'Duni Falkland',
 			'FM' => 'Mikoronesi',
 			'FO' => 'Duni Faro',
 			'FR' => 'Faraans',
 			'GA' => 'Gaboŋ',
 			'GB' => 'Ruwaayom Ini',
 			'GD' => 'Garanad',
 			'GE' => 'Seworsi',
 			'GF' => 'Guyaan Farañse',
 			'GG' => 'Gernase',
 			'GH' => 'Gana',
 			'GI' => 'Sibraltaar',
 			'GL' => 'Girinlànd',
 			'GM' => 'Gàmbi',
 			'GN' => 'Gine',
 			'GP' => 'Guwaadelup',
 			'GQ' => 'Gine Ekuwatoriyal',
 			'GR' => 'Gerees',
 			'GS' => 'Seworsi di Sid ak Duni Sàndwiis di Sid',
 			'GT' => 'Guwatemala',
 			'GU' => 'Guwam',
 			'GW' => 'Gine-Bisaawóo',
 			'GY' => 'Giyaan',
 			'HK@alt=short' => 'Ooŋ Koŋ',
 			'HM' => 'Duni Hërd ak Duni MakDonald',
 			'HN' => 'Onduraas',
 			'HR' => 'Korowasi',
 			'HT' => 'Ayti',
 			'HU' => 'Ongari',
 			'ID' => 'Indonesi',
 			'IE' => 'Irlànd',
 			'IL' => 'Israyel',
 			'IM' => 'Dunu Maan',
 			'IN' => 'End',
 			'IO' => 'Terituwaaru Brëtaañ ci Oseyaa Enjeŋ',
 			'IQ' => 'Irag',
 			'IR' => 'Iraŋ',
 			'IS' => 'Islànd',
 			'IT' => 'Itali',
 			'JE' => 'Serse',
 			'JM' => 'Samayig',
 			'JO' => 'Sordani',
 			'JP' => 'Sàppoŋ',
 			'KE' => 'Keeña',
 			'KG' => 'Kirgistaŋ',
 			'KH' => 'Kàmboj',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoor',
 			'KN' => 'Saŋ Kits ak Newis',
 			'KP' => 'Kore Noor',
 			'KW' => 'Kowet',
 			'KY' => 'Duni Kaymaŋ',
 			'KZ' => 'Kasaxstaŋ',
 			'LA' => 'Lawos',
 			'LB' => 'Libaa',
 			'LC' => 'Saŋ Lusi',
 			'LI' => 'Liktensteyin',
 			'LK' => 'Siri Lànka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litiyani',
 			'LU' => 'Liksàmbur',
 			'LV' => 'Letoni',
 			'LY' => 'Libi',
 			'MA' => 'Marog',
 			'MC' => 'Monako',
 			'MD' => 'Moldawi',
 			'ME' => 'Montenegoro',
 			'MF' => 'Saŋ Marteŋ',
 			'MG' => 'Madagaskaar',
 			'MH' => 'Duni Marsaal',
 			'MK' => 'Maseduwaan',
 			'MK@alt=variant' => 'Maseduwaan (Réewum yugoslawi gu yàgg ga)',
 			'ML' => 'Mali',
 			'MM' => 'Miyanmaar',
 			'MN' => 'Mongoli',
 			'MO@alt=short' => 'Makaawo',
 			'MP' => 'Duni Mariyaan Noor',
 			'MQ' => 'Martinik',
 			'MR' => 'Mooritani',
 			'MS' => 'Mooseraa',
 			'MT' => 'Malt',
 			'MU' => 'Moriis',
 			'MV' => 'Maldiiw',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesi',
 			'MZ' => 'Mosàmbig',
 			'NA' => 'Namibi',
 			'NC' => 'Nuwel Kaledoni',
 			'NE' => 'Niiseer',
 			'NF' => 'Dunu Norfolk',
 			'NG' => 'Niseriya',
 			'NI' => 'Nikaraguwa',
 			'NL' => 'Peyi Baa',
 			'NO' => 'Norwees',
 			'NP' => 'Nepaal',
 			'NR' => 'Nawru',
 			'NU' => 'Niw',
 			'NZ' => 'Nuwel Selànd',
 			'OM' => 'Omaan',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesi Farañse',
 			'PG' => 'Papuwasi Gine Gu Bees',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistaŋ',
 			'PL' => 'Poloñ',
 			'PM' => 'Saŋ Peer ak Mikeloŋ',
 			'PN' => 'Duni Pitkayirn',
 			'PR' => 'Porto Riko',
 			'PT' => 'Portigaal',
 			'PW' => 'Palaw',
 			'PY' => 'Paraguwe',
 			'QA' => 'Kataar',
 			'RE' => 'Reeñoo',
 			'RO' => 'Rumani',
 			'RS' => 'Serbi',
 			'RU' => 'Risi',
 			'RW' => 'Ruwànda',
 			'SA' => 'Arabi Sawudi',
 			'SB' => 'Duni Salmoon',
 			'SC' => 'Seysel',
 			'SD' => 'Sudaŋ',
 			'SE' => 'Suwed',
 			'SG' => 'Singapuur',
 			'SH' => 'Saŋ Eleen',
 			'SI' => 'Esloweni',
 			'SJ' => 'Swalbaar ak Jan Mayen',
 			'SK' => 'Eslowaki',
 			'SL' => 'Siyera Lewon',
 			'SM' => 'San Marino',
 			'SN' => 'Senegaal',
 			'SO' => 'Somali',
 			'SR' => 'Sirinam',
 			'SS' => 'Sudaŋ di Sid',
 			'ST' => 'Sawo Tome ak Pirinsipe',
 			'SV' => 'El Salwadoor',
 			'SX' => 'Sin Marten',
 			'SY' => 'Siri',
 			'SZ' => 'Suwasilànd',
 			'TC' => 'Duni Tirk ak Kaykos',
 			'TD' => 'Càdd',
 			'TF' => 'Teer Ostraal gu Fraas',
 			'TG' => 'Togo',
 			'TH' => 'Taylànd',
 			'TJ' => 'Tajikistaŋ',
 			'TK' => 'Tokoloo',
 			'TL' => 'Timor Leste',
 			'TM' => 'Tirkmenistaŋ',
 			'TN' => 'Tinisi',
 			'TO' => 'Tonga',
 			'TR' => 'Tirki',
 			'TT' => 'Tirinite ak Tobago',
 			'TV' => 'Tuwalo',
 			'TW' => 'Taywan',
 			'TZ' => 'Taŋsani',
 			'UA' => 'Ikeren',
 			'UG' => 'Ugànda',
 			'UM' => 'Duni Amerig Utar meer',
 			'US' => 'Etaa Sini',
 			'UY' => 'Uruge',
 			'UZ' => 'Usbekistaŋ',
 			'VA' => 'Site bu Watikaa',
 			'VC' => 'Saŋ Weesaa ak Garanadin',
 			'VE' => 'Wenesiyela',
 			'VG' => 'Duni Wirsin yu Brëtaañ',
 			'VI' => 'Duni Wirsin yu Etaa-sini',
 			'VN' => 'Wiyetnam',
 			'VU' => 'Wanuatu',
 			'WF' => 'Walis ak Futuna',
 			'WS' => 'Samowa',
 			'XK' => 'Kosowo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayot',
 			'ZA' => 'Afrik di Sid',
 			'ZM' => 'Sàmbi',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Gox buñ xamul',

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
 				'gregorian' => q{Arminaatu Gregoriyee},
 			},
 			'collation' => {
 				'standard' => q{SSO (Toftalin wiñ gën a xam)},
 			},
 			'numbers' => {
 				'latn' => q{Siifari Tugal},
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
			'metric' => q{Metrik},
 			'UK' => q{UK},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[ã h v z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a à b c d e é ë f g i j k l m n ñ ŋ o ó p q r s t u w x y]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:waaw|wa|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:déedet|dé|no|n)$' }
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real bu Bresil),
				'other' => q(Real yu Bresil),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan bu Siin),
				'other' => q(Yuan yu Siin),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Pound bu Grànd Brëtaañ),
				'other' => q(Pound yu Grànd Brëtaañ),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupee bu End),
				'other' => q(Rupee yu End),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yen bu Sapoŋ),
				'other' => q(Yen yu Sapoŋ),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Ruble bi Rsis),
				'other' => q(Ruble yu Risi),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dolaaru US),
				'other' => q(Dolaari US),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Franc CFA bu Afrik Sowwu-jant),
				'other' => q(Franc CFA yu Afrik Sowwu-jant),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Xaalis buñ Xamul),
				'other' => q(\(xaalis buñ xamul\)),
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
							'Sam',
							'Few',
							'Mar',
							'Awr',
							'Mee',
							'Suw',
							'Sul',
							'Ut',
							'Sàt',
							'Okt',
							'Now',
							'Des'
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
							'Samwiyee',
							'Fewriyee',
							'Mars',
							'Awril',
							'Mee',
							'Suwe',
							'Sulet',
							'Ut',
							'Sàttumbar',
							'Oktoobar',
							'Nowàmbar',
							'Desàmbar'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Sam',
							'Few',
							'Mar',
							'Awr',
							'Mee',
							'Suw',
							'Sul',
							'Ut',
							'Sàt',
							'Okt',
							'Now',
							'Des'
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
							'Samwiyee',
							'Fewriyee',
							'Mars',
							'Awril',
							'Mee',
							'Suwe',
							'Sulet',
							'Ut',
							'Sàttumbar',
							'Oktoobar',
							'Nowàmbar',
							'Desàmbar'
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
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					narrow => {
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					short => {
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					wide => {
						mon => 'Altine',
						tue => 'Talaata',
						wed => 'Àlarba',
						thu => 'Alxamis',
						fri => 'Àjjuma',
						sat => 'Aseer',
						sun => 'Dibéer'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					narrow => {
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					short => {
						mon => 'Alt',
						tue => 'Tal',
						wed => 'Àla',
						thu => 'Alx',
						fri => 'Àjj',
						sat => 'Ase',
						sun => 'Dib'
					},
					wide => {
						mon => 'Altine',
						tue => 'Talaata',
						wed => 'Àlarba',
						thu => 'Alxamis',
						fri => 'Àjjuma',
						sat => 'Aseer',
						sun => 'Dibéer'
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
					abbreviated => {0 => '1er Tri',
						1 => '2e Tri',
						2 => '3e Tri',
						3 => '4e Tri'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1er Trimestar',
						1 => '2e Trimestar',
						2 => '3e Trimestar',
						3 => '4e Trimestar'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1er Tri',
						1 => '2e Tri',
						2 => '3e Tri',
						3 => '4e Tri'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1er Trimestar',
						1 => '2e Trimestar',
						2 => '3e Trimestar',
						3 => '4e Trimestar'
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
					'am' => q{Sub},
					'pm' => q{Ngo},
				},
				'narrow' => {
					'am' => q{Sub},
					'pm' => q{Ngo},
				},
				'wide' => {
					'am' => q{Sub},
					'pm' => q{Ngo},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{Sub},
					'pm' => q{Ngo},
				},
				'narrow' => {
					'am' => q{Sub},
					'pm' => q{Ngo},
				},
				'wide' => {
					'am' => q{Sub},
					'pm' => q{Ngo},
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
				'0' => 'JC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'av. JC',
				'1' => 'AD'
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
			'full' => q{EEEE, d MMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{dd-MM-y},
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
			'full' => q{{1} 'ci' {0}},
			'long' => q{{1} 'ci' {0}},
			'medium' => q{{1} - {0}},
			'short' => q{{1} - {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'ci' {0}},
			'long' => q{{1} 'ci' {0}},
			'medium' => q{{1} - {0}},
			'short' => q{{1} - {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			E => q{ccc},
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			M => q{L},
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d/MM/y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
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
			fallback => '{0} – {1}',
		},
		'gregorian' => {
			fallback => '{0} – {1}',
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
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#CDT (waxtu bëccëgu sàntaraal#,
				'generic' => q#CT (waxtu sàntaral)#,
				'standard' => q#CST (waxtu estàndaaru sàntaraal)#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#EDT (waxtu bëccëgu penku)#,
				'generic' => q#ET waxtu penku#,
				'standard' => q#EST (waxtu estàndaaru penku)#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#MDT (waxtu bëccëgu tundu)#,
				'generic' => q#MT (waxtu tundu)#,
				'standard' => q#MST (waxtu estàndaaru tundu)#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#PDT (waxtu bëccëgu pasifik)#,
				'generic' => q#PT (waxtu pasifik)#,
				'standard' => q#PST (waxtu estàndaaru pasifik)#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ADT (waxtu bëccëgu atlàntik)#,
				'generic' => q#AT (waxtu atlàntik)#,
				'standard' => q#AST (waxtu estàndaaru penku)#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#CUT (waxtu iniwelsel yuñ boole)#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Dëkk buñ xamul#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#CEST (waxtu ete wu ëroop sàntaraal)#,
				'generic' => q#CTE (waxtu ëroop sàntaraal)#,
				'standard' => q#CEST (waxtu estàndaaru ëroop sàntaraal)#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#EEST (waxtu ete wu ëroop u penku)#,
				'generic' => q#EET (waxtu ëroop u penku)#,
				'standard' => q#EEST (waxtu estàndaaru ëroop u penku)#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#WEST (waxtu ete wu ëroop u sowwu-jant)#,
				'generic' => q#WET (waxtu ëroop u sowwu-jant#,
				'standard' => q#WEST (waxtu estàndaaru ëroop u sowwu-jant)#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#GMT (waxtu Greenwich)#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
