=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Lag - Package for language Langi

=cut

package Locale::CLDR::Locales::Lag;
# This file auto generated from Data\common\main\lag.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ak' => 'Kɨakáani',
 				'am' => 'Kɨmʉháari',
 				'ar' => 'Kɨaráabu',
 				'be' => 'Kɨberalúusi',
 				'bg' => 'Kɨbulugária',
 				'bn' => 'Kɨbangála',
 				'cs' => 'Kɨchéeki',
 				'de' => 'Kɨjerʉmáani',
 				'el' => 'Kɨgiríki',
 				'en' => 'Kɨɨngeréesa',
 				'es' => 'Kɨhispánia',
 				'fa' => 'Kɨajéemi',
 				'fr' => 'Kɨfaráansa',
 				'ha' => 'Kɨhaúusa',
 				'hi' => 'Kɨhíindi',
 				'hu' => 'Kɨhungári',
 				'id' => 'Kɨɨndonésia',
 				'ig' => 'Kiígibo',
 				'it' => 'Kɨtaliáano',
 				'ja' => 'Kɨjapáani',
 				'jv' => 'Kɨjáava',
 				'km' => 'Kɨkambódia',
 				'ko' => 'Kɨkoréa',
 				'lag' => 'Kɨlaangi',
 				'ms' => 'Kɨmelésia',
 				'my' => 'Kɨbáama',
 				'ne' => 'Kɨnepáali',
 				'nl' => 'Kɨholáanzi',
 				'pa' => 'Kɨpúnjabi',
 				'pl' => 'Kɨpólandi',
 				'pt' => 'Kɨréeno',
 				'ro' => 'Kɨromanía',
 				'ru' => 'Kɨrúusi',
 				'rw' => 'Kɨnyarwáanda',
 				'so' => 'Kɨsómáali',
 				'sv' => 'Kɨswíidi',
 				'ta' => 'Kɨtamíili',
 				'th' => 'Kɨtáilandi',
 				'tr' => 'Kɨturúuki',
 				'uk' => 'Kɨukɨranía',
 				'ur' => 'Kɨúrdu',
 				'vi' => 'Kɨvietináamu',
 				'yo' => 'Kɨyorúuba',
 				'zh' => 'Kɨchíina',
 				'zu' => 'Kɨzúulu',

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
			'AD' => 'Andóra',
 			'AE' => 'Ʉtemi wa Kɨaráabu',
 			'AF' => 'Afuganisitáani',
 			'AG' => 'Antigúua na Baribúuda',
 			'AI' => 'Anguíila',
 			'AL' => 'Alubánia',
 			'AM' => 'Ariménia',
 			'AO' => 'Angóola',
 			'AR' => 'Ajentíina',
 			'AS' => 'Samóoa ya Amerɨ́ka',
 			'AT' => 'Áusitiria',
 			'AU' => 'Ausiteréelia',
 			'AW' => 'Arúuba',
 			'AZ' => 'Azabajáani',
 			'BA' => 'Bósinia',
 			'BB' => 'Babadóosi',
 			'BD' => 'Bangaladéeshi',
 			'BE' => 'Ʉbeligíiji',
 			'BF' => 'Bukinafáaso',
 			'BG' => 'Buligaría',
 			'BH' => 'Baharéeni',
 			'BI' => 'Burúundi',
 			'BJ' => 'Beníini',
 			'BM' => 'Berimúuda',
 			'BN' => 'Burunéei',
 			'BO' => 'Bolívia',
 			'BR' => 'Brasíili',
 			'BS' => 'Baháama',
 			'BT' => 'Butáani',
 			'BW' => 'Botiswáana',
 			'BY' => 'Belarúusi',
 			'BZ' => 'Belíise',
 			'CA' => 'Kánada',
 			'CD' => 'Jamuhúuri ya Kɨdemokurasía ya Kóongo',
 			'CF' => 'Juhúuri ya Afɨrɨka ya katɨ katɨ',
 			'CG' => 'Kóongo',
 			'CH' => 'Uswíisi',
 			'CI' => 'Ivori Kositi',
 			'CK' => 'Visíiwa vya Kúuku',
 			'CL' => 'Chíile',
 			'CM' => 'Kamerúuni',
 			'CN' => 'Chíina',
 			'CO' => 'Kolómbia',
 			'CR' => 'Kósita Rɨ́ɨka',
 			'CU' => 'Kyúuba',
 			'CV' => 'Kepuvéede',
 			'CY' => 'Kupuróosi',
 			'CZ' => 'Jamuhúuri ya Chéeki',
 			'DE' => 'Ʉjerumáani',
 			'DJ' => 'Jibúuti',
 			'DK' => 'Denimaki',
 			'DM' => 'Domínɨka',
 			'DO' => 'Jamuhúuri ya Dominɨka',
 			'DZ' => 'Alijéria',
 			'EC' => 'Íkwado',
 			'EE' => 'Estonía',
 			'EG' => 'Mísiri',
 			'ER' => 'Eriterea',
 			'ES' => 'Hisipánia',
 			'ET' => 'Ʉhabéeshi',
 			'FI' => 'Ufíini',
 			'FJ' => 'Fíiji',
 			'FK' => 'Visíiwa vya Fakulandi',
 			'FM' => 'Mikironésia',
 			'FR' => 'Ʉfaráansa',
 			'GA' => 'Gabóoni',
 			'GB' => 'Ʉɨngeréesa',
 			'GD' => 'Girenáada',
 			'GE' => 'Jójia',
 			'GF' => 'Gwiyáana yʉ Ʉfaráansa',
 			'GH' => 'Gáana',
 			'GI' => 'Jiburálita',
 			'GL' => 'Giriniláandi',
 			'GM' => 'Gámbia',
 			'GN' => 'Gíine',
 			'GP' => 'Gwadelúupe',
 			'GQ' => 'Gíine Ikwéeta',
 			'GR' => 'Ugiríki',
 			'GT' => 'Gwatemáala',
 			'GU' => 'Gwani',
 			'GW' => 'Gíine Bisáau',
 			'GY' => 'Guyáana',
 			'HN' => 'Honduráasi',
 			'HR' => 'Koréshia',
 			'HT' => 'Haíiti',
 			'HU' => 'Hungária',
 			'ID' => 'Indonésia',
 			'IE' => 'Ayaláandi',
 			'IL' => 'Isiraéeli',
 			'IN' => 'Índia',
 			'IO' => 'Ɨsɨ yʉ Ʉɨngeréesa irivii ra Híindi',
 			'IQ' => 'Iráaki',
 			'IR' => 'Ʉajéemi',
 			'IS' => 'Aisiláandi',
 			'IT' => 'Itália',
 			'JM' => 'Jamáika',
 			'JO' => 'Jódani',
 			'JP' => 'Japáani',
 			'KE' => 'Kéenya',
 			'KG' => 'Kirigisitáani',
 			'KH' => 'Kambódia',
 			'KI' => 'Kiribáati',
 			'KM' => 'Komóoro',
 			'KN' => 'Mʉtakatíifu kitisi na Nevíisi',
 			'KP' => 'Koréa yʉ ʉtʉrʉko',
 			'KR' => 'Koréa ya Saame',
 			'KW' => 'Kʉwáiti',
 			'KY' => 'Visíiwa vya Kayimani',
 			'KZ' => 'Kazakasitáani',
 			'LA' => 'Laóosi',
 			'LB' => 'Lebanóoni',
 			'LC' => 'Mʉtakatíifu Lusíia',
 			'LI' => 'Lishentéeni',
 			'LK' => 'Siriláanka',
 			'LR' => 'Liibéria',
 			'LS' => 'Lesóoto',
 			'LT' => 'Lisuánia',
 			'LU' => 'Lasembáagi',
 			'LV' => 'Lativia',
 			'LY' => 'Líbia',
 			'MA' => 'Moróoko',
 			'MC' => 'Monáako',
 			'MD' => 'Molidóova',
 			'MG' => 'Bukíini',
 			'MH' => 'Visíiwa vya Marisháali',
 			'ML' => 'Máali',
 			'MM' => 'Miáama',
 			'MN' => 'Mongólia',
 			'MP' => 'Visiwa vya Mariana vya Kaskazini',
 			'MQ' => 'Maritiníiki',
 			'MR' => 'Moritánia',
 			'MS' => 'Monteráati',
 			'MT' => 'Málita',
 			'MU' => 'Moríisi',
 			'MV' => 'Modíivu',
 			'MW' => 'Maláawi',
 			'MX' => 'Mekisiko',
 			'MY' => 'Maleísia',
 			'MZ' => 'Musumbíiji',
 			'NA' => 'Namíbia',
 			'NC' => 'Kaledónia Ifya',
 			'NE' => 'Níija',
 			'NF' => 'Kisíiwa cha Nofifóoki',
 			'NG' => 'Niijéria',
 			'NI' => 'Nikarágʉa',
 			'NL' => 'Ʉholáanzi',
 			'NO' => 'Norwe',
 			'NP' => 'Nepáali',
 			'NR' => 'Naúuru',
 			'NU' => 'Niúue',
 			'NZ' => 'Nyuzílandi',
 			'OM' => 'Ómani',
 			'PA' => 'Panáama',
 			'PE' => 'Péeru',
 			'PF' => 'Polinésia yʉ Ʉfaráansa',
 			'PG' => 'Papúua',
 			'PH' => 'Ufilipíino',
 			'PK' => 'Pakisitáani',
 			'PL' => 'Pólandi',
 			'PM' => 'Mʉtakatíifu Peéteri na Mɨkaéeli',
 			'PN' => 'Patikaírini',
 			'PR' => 'Pwetorɨ́ɨko',
 			'PS' => 'Mweemberera wa kʉmweeri wa Gáaza',
 			'PT' => 'Ʉréeno',
 			'PW' => 'Paláau',
 			'PY' => 'Paraguáai',
 			'QA' => 'Katáari',
 			'RE' => 'Reyunióoni',
 			'RO' => 'Romaníia',
 			'RU' => 'Urúusi',
 			'RW' => 'Rwáanda',
 			'SA' => 'Saudíia Arabíia',
 			'SB' => 'Visíiwa vya Solomóoni',
 			'SC' => 'Shelishéeli',
 			'SD' => 'Sudáani',
 			'SE' => 'Uswíidi',
 			'SG' => 'Singapoo',
 			'SH' => 'Mʉtakatíifu Heléena',
 			'SI' => 'Sulovénia',
 			'SK' => 'Sulováakia',
 			'SL' => 'Seraleóoni',
 			'SM' => 'Samaríino',
 			'SN' => 'Senegáali',
 			'SO' => 'Somália',
 			'SR' => 'Surináamu',
 			'ST' => 'Sao Tóome na Pirinsipe',
 			'SV' => 'Elisalivado',
 			'SY' => 'Síria',
 			'SZ' => 'Ʉswáazi',
 			'TC' => 'Visíiwa vya Turíiki na Kaíiko',
 			'TD' => 'Cháadi',
 			'TG' => 'Tóogo',
 			'TH' => 'Táilandi',
 			'TJ' => 'Tajikisitáani',
 			'TK' => 'Tokeláau',
 			'TL' => 'Timóori yi Itʉʉmba',
 			'TM' => 'Uturukimenisitáani',
 			'TN' => 'Tunísia',
 			'TO' => 'Tóonga',
 			'TR' => 'Uturúuki',
 			'TT' => 'Tiriníida ya Tobáago',
 			'TV' => 'Tuváalu',
 			'TW' => 'Taiwáani',
 			'TZ' => 'Taansanía',
 			'UA' => 'Ʉkɨréeni',
 			'UG' => 'Ʉgáanda',
 			'US' => 'Amerɨka',
 			'UY' => 'Uruguáai',
 			'UZ' => 'Usibekisitáani',
 			'VA' => 'Vatikáani',
 			'VC' => 'Mʉtakatíifu Viséenti na Gernadíini',
 			'VE' => 'Venezuéela',
 			'VG' => 'Visíiwa vya Vigíini vya Ʉɨngeréesa',
 			'VI' => 'Visíiwa vya Vigíini vya Amerɨ́ka',
 			'VN' => 'Vietináamu',
 			'VU' => 'Vanuáatu',
 			'WF' => 'Walíisi na Futúuna',
 			'WS' => 'Samóoa',
 			'YE' => 'Yémeni',
 			'YT' => 'Mayóote',
 			'ZA' => 'Afɨrɨka ya Saame',
 			'ZM' => 'Sámbia',
 			'ZW' => 'Simbáabwe',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'Ɨ', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ʉ', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aá b c d eé f g h ií ɨ j k l m n oó p q r s t uú ʉ v w x y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'Ɨ', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ʉ', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hɨɨ|H|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Tʉkʉ|T|no|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(Diriháamu ya Ʉtemi wa Kɨaráabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwáanza ya Angóola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dóola ya Ausitereelía),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dináari ya Baharéeni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faráanga ya Burúundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Púula ya Botiswáana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dóola ya Kánada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faráanga ya Kóongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faráaka ya Uswíisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yúani Renimínibi ya Chíina),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esikúudo ya Kepuvéede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faráanga ya Jibóuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dináairi ya Alijéria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Páundi ya Mísiri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nákɨfa ya Eriterea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bíiri ya Ʉhabéeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yúuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Páundi ya Ʉɨngɨréesa),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Séedi ya Gáana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Daláasi ya Gámbia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faráanga ya Gíine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupía ya Índia),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yéeni ya Japáani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilíingi ya Kéenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faráanga ya Komóoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dóola ya Libéria),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lóoti ya Lesóoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dináari ya Líbia),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Diriháamu ya Moróoko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Mpía ya bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ungwíiya ya Moritánia \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ungwíiya ya Moritánia),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupía ya Moríisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwáacha ya Maláawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikáali ya Musumbíiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dóola ya Namíbia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naíira ya Niijéria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faráanga ya Rwáanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyáali ya Saudía),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupía ya Shelishéeli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Páundi ya Sudáani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Páundi ya Mʉtakatíifu Heléena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leóoni),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leóoni \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilíingi ya Somália),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dóbura ya SaoTóome na Pirínsipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dóbura ya SaoTóome na Pirínsipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilengéeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dináari ya Tunísia),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(Shilíingi ya Taansanía),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilíingi ya Ugáanda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dóola ya Amerɨ́ka),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faráanga ya CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faráanga ya CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ráandi ya Afɨrɨka ya Saame),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwácha ya Sámbia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwácha ya Sámbia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dóola ya Simbáabwe),
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
							'Fúngatɨ',
							'Naanɨ',
							'Keenda',
							'Ikúmi',
							'Inyambala',
							'Idwaata',
							'Mʉʉnchɨ',
							'Vɨɨrɨ',
							'Saatʉ',
							'Inyi',
							'Saano',
							'Sasatʉ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Kʉfúngatɨ',
							'Kʉnaanɨ',
							'Kʉkeenda',
							'Kwiikumi',
							'Kwiinyambála',
							'Kwiidwaata',
							'Kʉmʉʉnchɨ',
							'Kʉvɨɨrɨ',
							'Kʉsaatʉ',
							'Kwiinyi',
							'Kʉsaano',
							'Kʉsasatʉ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'F',
							'N',
							'K',
							'I',
							'I',
							'I',
							'M',
							'V',
							'S',
							'I',
							'S',
							'S'
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
						mon => 'Táatu',
						tue => 'Íne',
						wed => 'Táano',
						thu => 'Alh',
						fri => 'Ijm',
						sat => 'Móosi',
						sun => 'Píili'
					},
					wide => {
						mon => 'Jumatátu',
						tue => 'Jumaíne',
						wed => 'Jumatáano',
						thu => 'Alamíisi',
						fri => 'Ijumáa',
						sat => 'Jumamóosi',
						sun => 'Jumapíiri'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'T',
						tue => 'E',
						wed => 'O',
						thu => 'A',
						fri => 'I',
						sat => 'M',
						sun => 'P'
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
					abbreviated => {0 => 'Ncho 1',
						1 => 'Ncho 2',
						2 => 'Ncho 3',
						3 => 'Ncho 4'
					},
					wide => {0 => 'Ncholo ya 1',
						1 => 'Ncholo ya 2',
						2 => 'Ncholo ya 3',
						3 => 'Ncholo ya 4'
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
					'am' => q{TOO},
					'pm' => q{MUU},
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
				'0' => 'KSA',
				'1' => 'KA'
			},
			wide => {
				'0' => 'Kɨrɨsitʉ sɨ anavyaal',
				'1' => 'Kɨrɨsitʉ akavyaalwe'
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
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
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
	} },
);

no Moo;

1;

# vim: tabstop=4
