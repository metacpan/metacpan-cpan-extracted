=encoding utf8

=head1

Locale::CLDR::Locales::Kde - Package for language Makonde

=cut

package Locale::CLDR::Locales::Kde;
# This file auto generated from Data\common\main\kde.xml
#	on Sun  3 Feb  2:00:01 pm GMT

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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ak' => 'Chakan',
 				'am' => 'Chamhali',
 				'ar' => 'Chalabu',
 				'be' => 'Chibelalusi',
 				'bg' => 'Chibulgalia',
 				'bn' => 'Chibangla',
 				'cs' => 'Chichechi',
 				'de' => 'Chidyelumani',
 				'el' => 'Chigilichi',
 				'en' => 'Chiingeleza',
 				'es' => 'Chihispania',
 				'fa' => 'Chiajemi',
 				'fr' => 'Chifalansa',
 				'ha' => 'Chihausa',
 				'hi' => 'Chihindi',
 				'hu' => 'Chihungali',
 				'id' => 'Chiiongonesia',
 				'ig' => 'Chiigbo',
 				'it' => 'Chiitaliano',
 				'ja' => 'Chidyapani',
 				'jv' => 'Chidyava',
 				'kde' => 'Chimakonde',
 				'km' => 'Chikambodia',
 				'ko' => 'Chikolea',
 				'ms' => 'Chimalesia',
 				'my' => 'Chibulma',
 				'ne' => 'Chinepali',
 				'nl' => 'Chiholanzi',
 				'pa' => 'Chipunjabi',
 				'pl' => 'Chipolandi',
 				'pt' => 'Chileno',
 				'ro' => 'Chilomania',
 				'ru' => 'Chilusi',
 				'rw' => 'Chinyalwanda',
 				'so' => 'Chisomali',
 				'sv' => 'Chiswidi',
 				'ta' => 'Chitamil',
 				'th' => 'Chitailandi',
 				'tr' => 'Chituluchi',
 				'uk' => 'Chiuklania',
 				'ur' => 'Chiuldu',
 				'vi' => 'Chivietinamu',
 				'yo' => 'Chiyoluba',
 				'zh' => 'Chichina',
 				'zu' => 'Chizulu',

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
			'AD' => 'Andola',
 			'AE' => 'Dimiliki dya Vakulungwa va Chalabu',
 			'AF' => 'Afuganistani',
 			'AG' => 'Antigua na Balbuda',
 			'AI' => 'Angwila',
 			'AL' => 'Albania',
 			'AM' => 'Almenia',
 			'AO' => 'Angola',
 			'AR' => 'Adyentina',
 			'AS' => 'Samoa ya Malekani',
 			'AT' => 'Austlia',
 			'AU' => 'Austlalia',
 			'AW' => 'Aluba',
 			'AZ' => 'Azabadyani',
 			'BA' => 'Bosnia na Hezegovina',
 			'BB' => 'Babadosi',
 			'BD' => 'Bangladeshi',
 			'BE' => 'Ubelgidi',
 			'BF' => 'Buchinafaso',
 			'BG' => 'Bulgalia',
 			'BH' => 'Bahaleni',
 			'BI' => 'Bulundi',
 			'BJ' => 'Benini',
 			'BM' => 'Belmuda',
 			'BN' => 'Blunei',
 			'BO' => 'Bolivia',
 			'BR' => 'Blazili',
 			'BS' => 'Bahama',
 			'BT' => 'Butani',
 			'BW' => 'Botswana',
 			'BY' => 'Belalusi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Jamuhuli ya Chidemoklasia ya kuKongo',
 			'CF' => 'Jamuhuli ya Afilika ya Paching’ati',
 			'CG' => 'Kongo',
 			'CH' => 'Uswisi',
 			'CI' => 'Kodivaa',
 			'CK' => 'Chisiwa cha Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameluni',
 			'CN' => 'China',
 			'CO' => 'Kolombia',
 			'CR' => 'Kostalika',
 			'CU' => 'Kuba',
 			'CV' => 'Kepuvede',
 			'CY' => 'Kuplosi',
 			'CZ' => 'Jamuhuli ya Chechi',
 			'DE' => 'Udyerumani',
 			'DJ' => 'Dyibuti',
 			'DK' => 'Denmaki',
 			'DM' => 'Dominika',
 			'DO' => 'Jamuhuli ya Dominika',
 			'DZ' => 'Aljelia',
 			'EC' => 'Ekwado',
 			'EE' => 'Estonia',
 			'EG' => 'Misli',
 			'ER' => 'Elitilea',
 			'ES' => 'Hispania',
 			'ET' => 'Uhabeshi',
 			'FI' => 'Ufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Chisiwa cha Falkland',
 			'FM' => 'Mikilonesia',
 			'FR' => 'Ufalansa',
 			'GA' => 'Gaboni',
 			'GB' => 'Nngalesa',
 			'GD' => 'Glenada',
 			'GE' => 'Dyodya',
 			'GF' => 'Gwiyana ya Ufalansa',
 			'GH' => 'Ghana',
 			'GI' => 'Diblalta',
 			'GL' => 'Glinlandi',
 			'GM' => 'Gambia',
 			'GN' => 'Gine',
 			'GP' => 'Gwadelupe',
 			'GQ' => 'Ginekweta',
 			'GR' => 'Ugilichi',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwam',
 			'GW' => 'Ginebisau',
 			'GY' => 'Guyana',
 			'HN' => 'Hondulasi',
 			'HR' => 'Kolasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungalia',
 			'ID' => 'Indonesia',
 			'IE' => 'Ayalandi',
 			'IL' => 'Islaeli',
 			'IN' => 'India',
 			'IO' => 'Lieneo lyaki Nngalesa Nbahali ya Hindi',
 			'IQ' => 'Ilaki',
 			'IR' => 'Uadyemi',
 			'IS' => 'Aislandi',
 			'IT' => 'Italia',
 			'JM' => 'Dyamaika',
 			'JO' => 'Yordani',
 			'JP' => 'Dyapani',
 			'KE' => 'Kenya',
 			'KG' => 'Kiligizistani',
 			'KH' => 'Kambodia',
 			'KI' => 'Kilibati',
 			'KM' => 'Komolo',
 			'KN' => 'Santakitzi na Nevis',
 			'KP' => 'Kolea Kasikazini',
 			'KR' => 'Kolea Kusini',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Chisiwa cha Kemen',
 			'KZ' => 'Kazachistani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Santalusia',
 			'LI' => 'Lishenteni',
 			'LK' => 'Sililanka',
 			'LR' => 'Libelia',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwania',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'LY' => 'Libya',
 			'MA' => 'Moloko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'MG' => 'Bukini',
 			'MH' => 'Chisiwa cha Malushal',
 			'MK' => 'Masedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myama',
 			'MN' => 'Mongolia',
 			'MP' => 'Chisiwa cha Marian cha Kasikazini',
 			'MQ' => 'Malitiniki',
 			'MR' => 'Molitania',
 			'MS' => 'Monselati',
 			'MT' => 'Malta',
 			'MU' => 'Molisi',
 			'MV' => 'Modivu',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesia',
 			'MZ' => 'Msumbiji',
 			'NA' => 'Namibia',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nidyeli',
 			'NF' => 'Chisiwa cha Nolufok',
 			'NG' => 'Nidyelia',
 			'NI' => 'Nikalagwa',
 			'NL' => 'Uholanzi',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'NR' => 'Naulu',
 			'NU' => 'Niue',
 			'NZ' => 'Nyuzilandi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Pelu',
 			'PF' => 'Polinesia ya Ufalansa',
 			'PG' => 'Papua',
 			'PH' => 'Filipino',
 			'PK' => 'Pakistani',
 			'PL' => 'Polandi',
 			'PM' => 'Santapieli na Mikeloni',
 			'PN' => 'Pitikeluni',
 			'PR' => 'Pwetoliko',
 			'PS' => 'Nchingu wa Magalibi wa Mpanda wa kuGaza wa kuPales',
 			'PT' => 'Uleno',
 			'PW' => 'Palau',
 			'PY' => 'Palagwai',
 			'QA' => 'Katali',
 			'RE' => 'Liyunioni',
 			'RO' => 'Lomania',
 			'RU' => 'Ulusi',
 			'RW' => 'Lwanda',
 			'SA' => 'Saudia',
 			'SB' => 'Chisiwa cha Solomon',
 			'SC' => 'Shelisheli',
 			'SD' => 'Sudani',
 			'SE' => 'Uswidi',
 			'SG' => 'Singapoo',
 			'SH' => 'Santahelena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Siela Leoni',
 			'SM' => 'Samalino',
 			'SN' => 'Senegali',
 			'SO' => 'Somalia',
 			'SR' => 'Sulinamu',
 			'ST' => 'Saotome na Prinsipe',
 			'SV' => 'Elsavado',
 			'SY' => 'Silia',
 			'SZ' => 'Uswazi',
 			'TC' => 'Chisiwa cha Tuluchi na Kaiko',
 			'TD' => 'Chadi',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Tadikistani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timoli ya Mashaliki',
 			'TM' => 'Tuluchimenistani',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Utuluchi',
 			'TT' => 'Tilinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tanzania',
 			'UA' => 'Uklaini',
 			'UG' => 'Uganda',
 			'US' => 'Malekani',
 			'UY' => 'Ulugwai',
 			'UZ' => 'Uzibechistani',
 			'VA' => 'Vatikani',
 			'VC' => 'Santavisenti na Glenadini',
 			'VE' => 'Venezuela',
 			'VG' => 'Chisiwa Chivihi cha Wingalesa',
 			'VI' => 'Chisiwa Chivihi cha Malekani',
 			'VN' => 'Vietinamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walis na Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemeni',
 			'YT' => 'Maole',
 			'ZA' => 'Afilika Kusini',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Elo|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Nanga|N)$' }
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
				'currency' => q(Dirham ya Falme za Chiarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza ya Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dola ya Australia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinari ya Bahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faranga ya Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ya Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola ya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranga ya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranga ya Uswisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Renminbi ya China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Eskudo ya Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faranga ya Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinari ya Aljeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pauni ya Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa ya Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bir ya Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pauni ya Uingereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ya Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ya Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia ya India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Sarafu ya Chijapani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilingi ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranga ya Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola ya Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinari ya Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham ya Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Faranga ya Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya ya Moritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ugwiya ya Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia ya Morisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha ya Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali ya Msumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dola ya Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Nijeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faranga ya Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal ya Saudia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia ya Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinari ya Sudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pauni ya Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pauni ya Santahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilingi ya Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinari ya Tunisia),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(Shilingi ya Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingi ya Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dola ya Marekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi ya Afrika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola ya Zimbabwe),
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
							'Jan',
							'Feb',
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ago',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mwedi Ntandi',
							'Mwedi wa Pili',
							'Mwedi wa Tatu',
							'Mwedi wa Nchechi',
							'Mwedi wa Nnyano',
							'Mwedi wa Nnyano na Umo',
							'Mwedi wa Nnyano na Mivili',
							'Mwedi wa Nnyano na Mitatu',
							'Mwedi wa Nnyano na Nchechi',
							'Mwedi wa Nnyano na Nnyano',
							'Mwedi wa Nnyano na Nnyano na U',
							'Mwedi wa Nnyano na Nnyano na M'
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
						mon => 'Ll3',
						tue => 'Ll4',
						wed => 'Ll5',
						thu => 'Ll6',
						fri => 'Ll7',
						sat => 'Ll1',
						sun => 'Ll2'
					},
					wide => {
						mon => 'Liduva lyatatu',
						tue => 'Liduva lyanchechi',
						wed => 'Liduva lyannyano',
						thu => 'Liduva lyannyano na linji',
						fri => 'Liduva lyannyano na mavili',
						sat => 'Liduva litandi',
						sun => 'Liduva lyapili'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => '3',
						tue => '4',
						wed => '5',
						thu => '6',
						fri => '7',
						sat => '1',
						sun => '2'
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
					abbreviated => {0 => 'L1',
						1 => 'L2',
						2 => 'L3',
						3 => 'L4'
					},
					wide => {0 => 'Lobo 1',
						1 => 'Lobo 2',
						2 => 'Lobo 3',
						3 => 'Lobo 4'
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
					'pm' => q{Chilo},
					'am' => q{Muhi},
				},
				'wide' => {
					'am' => q{Muhi},
					'pm' => q{Chilo},
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
				'0' => 'AY',
				'1' => 'NY'
			},
			wide => {
				'0' => 'Akanapawa Yesu',
				'1' => 'Nankuida Yesu'
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
		'gregorian' => {
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
