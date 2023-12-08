=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sbp - Package for language Sangu

=cut

package Locale::CLDR::Locales::Sbp;
# This file auto generated from Data\common\main\sbp.xml
#	on Tue  5 Dec  1:30:02 pm GMT

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
				'ak' => 'Ishiyakani',
 				'am' => 'Ishiyamuhali',
 				'ar' => 'Ishiyalabu',
 				'be' => 'Ishibelalusi',
 				'bg' => 'Ishibulugalia',
 				'bn' => 'Ishibangila',
 				'cs' => 'Ishisheki',
 				'de' => 'Ishijelumani',
 				'el' => 'Ishigiliki',
 				'en' => 'Ishingelesa',
 				'es' => 'Ishihisipaniya',
 				'fa' => 'Ishiajemi',
 				'fr' => 'Ishifalansa',
 				'ha' => 'Ishihawusa',
 				'hi' => 'Ishihindi',
 				'hu' => 'Ishihungali',
 				'id' => 'Ishihindonesia',
 				'ig' => 'Ishihigibo',
 				'it' => 'Ishihitaliyano',
 				'ja' => 'Ishijapani',
 				'jv' => 'Ishijava',
 				'km' => 'Ishikambodia',
 				'ko' => 'Ishikoleya',
 				'ms' => 'Ishimalesiya',
 				'my' => 'Ishibuluma',
 				'ne' => 'Ishinepali',
 				'nl' => 'Ishiholansi',
 				'pa' => 'Ishipunjabi',
 				'pl' => 'Ishipolandi',
 				'pt' => 'Ishileno',
 				'ro' => 'Ishilomaniya',
 				'ru' => 'Ishilusi',
 				'rw' => 'Ishinyalwanda',
 				'sbp' => 'Ishisangu',
 				'so' => 'Ishisomali',
 				'sv' => 'Ishiswidi',
 				'ta' => 'Ishitamili',
 				'th' => 'Ishitayilandi',
 				'tr' => 'Ishituluki',
 				'uk' => 'Ishiyukilaniya',
 				'ur' => 'Ishiwuludi',
 				'vi' => 'Ishivietinamu',
 				'yo' => 'Ishiyoluba',
 				'zh' => 'Ishishina',
 				'zu' => 'Ishisulu',

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
 			'AE' => 'Wutwa wa shiyalabu',
 			'AF' => 'Afuganisitani',
 			'AG' => 'Anitiguya ni Balubuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Alubaniya',
 			'AM' => 'Alimeniya',
 			'AO' => 'Angola',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoya ya Malekani',
 			'AT' => 'Awusitiliya',
 			'AU' => 'Awusitilaliya',
 			'AW' => 'Aluba',
 			'AZ' => 'Asabajani',
 			'BA' => 'Bosiniya ni Hesegovina',
 			'BB' => 'Babadosi',
 			'BD' => 'Bangiladeshi',
 			'BE' => 'Ubeligiji',
 			'BF' => 'Bukinafaso',
 			'BG' => 'Buligaliya',
 			'BH' => 'Bahaleni',
 			'BI' => 'Bulundi',
 			'BJ' => 'Benini',
 			'BM' => 'Belimuda',
 			'BN' => 'Buluneyi',
 			'BO' => 'Boliviya',
 			'BR' => 'Bulasili',
 			'BS' => 'Bahama',
 			'BT' => 'Butani',
 			'BW' => 'Botiswana',
 			'BY' => 'Belalusi',
 			'BZ' => 'Belise',
 			'CA' => 'Kanada',
 			'CD' => 'Jamuhuli ya Kidemokilasiya ya Kongo',
 			'CF' => 'Jamuhuli ya Afilika ya Pakhati',
 			'CG' => 'Kongo',
 			'CH' => 'Uswisi',
 			'CI' => 'Kodivaya',
 			'CK' => 'Figunguli fya Kooki',
 			'CL' => 'Shile',
 			'CM' => 'Kameruni',
 			'CN' => 'Shina',
 			'CO' => 'Kolombiya',
 			'CR' => 'Kositalika',
 			'CU' => 'Kuba',
 			'CV' => 'Kepuvede',
 			'CY' => 'Kupilosi',
 			'CZ' => 'Jamuhuli ya Sheki',
 			'DE' => 'Wujelumani',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denimaki',
 			'DM' => 'Dominika',
 			'DO' => 'Jamuhuli ya Dominika',
 			'DZ' => 'Alijeliya',
 			'EC' => 'Ekwado',
 			'EE' => 'Esitoniya',
 			'EG' => 'Misili',
 			'ER' => 'Elitileya',
 			'ES' => 'Hisipaniya',
 			'ET' => 'Uhabeshi',
 			'FI' => 'Wufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Figunguli fya Fokolendi',
 			'FM' => 'Mikilonesiya',
 			'FR' => 'Wufalansa',
 			'GA' => 'Gaboni',
 			'GB' => 'Uwingelesa',
 			'GD' => 'Gilenada',
 			'GE' => 'Jojiya',
 			'GF' => 'Gwiyana ya Wufalansa',
 			'GH' => 'Khana',
 			'GI' => 'Jibulalita',
 			'GL' => 'Gilinilandi',
 			'GM' => 'Gambiya',
 			'GN' => 'Gine',
 			'GP' => 'Gwadelupe',
 			'GQ' => 'Ginekweta',
 			'GR' => 'Wugiliki',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwamu',
 			'GW' => 'Ginebisawu',
 			'GY' => 'Guyana',
 			'HN' => 'Hondulasi',
 			'HR' => 'Kolasiya',
 			'HT' => 'Hayiti',
 			'HU' => 'Hungaliya',
 			'ID' => 'Indonesiya',
 			'IE' => 'Ayalandi',
 			'IL' => 'Isilaeli',
 			'IN' => 'Indiya',
 			'IO' => 'Uluvala lwa Uwingelesa ku Bahali ya Hindi',
 			'IQ' => 'Ilaki',
 			'IR' => 'Uwajemi',
 			'IS' => 'Ayisilendi',
 			'IT' => 'Italiya',
 			'JM' => 'Jamaika',
 			'JO' => 'Yolodani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kiligisisitani',
 			'KH' => 'Kambodiya',
 			'KI' => 'Kilibati',
 			'KM' => 'Komolo',
 			'KN' => 'Santakitisi ni Nevisi',
 			'KP' => 'Koleya ya luvala lwa Kunyamande',
 			'KR' => 'Koleya ya Kusini',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Figunguli ifya Kayimayi',
 			'KZ' => 'Kasakisitani',
 			'LA' => 'Layosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Santalusiya',
 			'LI' => 'Lisheniteni',
 			'LK' => 'Sililanka',
 			'LR' => 'Libeliya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwaniya',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativiya',
 			'LY' => 'Libiya',
 			'MA' => 'Moloko',
 			'MC' => 'Monako',
 			'MD' => 'Molidova',
 			'MG' => 'Bukini',
 			'MH' => 'Figunguli ifya Malishali',
 			'MK' => 'Masedoniya',
 			'ML' => 'Mali',
 			'MM' => 'Muyama',
 			'MN' => 'Mongoliya',
 			'MP' => 'Figunguli fya Maliyana ifya luvala lwa Kunyamande',
 			'MQ' => 'Malitiniki',
 			'MR' => 'Molitaniya',
 			'MS' => 'Monitiselati',
 			'MT' => 'Malita',
 			'MU' => 'Molisi',
 			'MV' => 'Modivu',
 			'MW' => 'Malawi',
 			'MX' => 'Mekisiko',
 			'MY' => 'Malesiya',
 			'MZ' => 'Musumbiji',
 			'NA' => 'Namibiya',
 			'NC' => 'Nyukaledoniya',
 			'NE' => 'Nijeli',
 			'NF' => 'Shigunguli sha Nolifoki',
 			'NG' => 'Nijeliya',
 			'NI' => 'Nikalagwa',
 			'NL' => 'Wuholansi',
 			'NO' => 'Nolwe',
 			'NP' => 'Nepali',
 			'NR' => 'Nawulu',
 			'NU' => 'Niwue',
 			'NZ' => 'Nyusilendi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Pelu',
 			'PF' => 'Polinesiya ya Wufalansa',
 			'PG' => 'Papuwa',
 			'PH' => 'Filipino',
 			'PK' => 'Pakisitani',
 			'PL' => 'Polandi',
 			'PM' => 'Santapieli ni Mikeloni',
 			'PN' => 'Pitikailini',
 			'PR' => 'Pwetoliko',
 			'PS' => 'Munjema gwa Kusikha nu Luvala lwa Gasa lwa Palesit',
 			'PT' => 'Wuleno',
 			'PW' => 'Palawu',
 			'PY' => 'Palagwayi',
 			'QA' => 'Katali',
 			'RE' => 'Liyunioni',
 			'RO' => 'Lomaniya',
 			'RU' => 'Wulusi',
 			'RW' => 'Lwanda',
 			'SA' => 'Sawudi',
 			'SB' => 'Figunguli fya Solomoni',
 			'SC' => 'Shelisheli',
 			'SD' => 'Sudani',
 			'SE' => 'Uswidi',
 			'SG' => 'Singapoo',
 			'SH' => 'Santahelena',
 			'SI' => 'Siloveniya',
 			'SK' => 'Silovakiya',
 			'SL' => 'Siela Liyoni',
 			'SM' => 'Samalino',
 			'SN' => 'Senegali',
 			'SO' => 'Somaliya',
 			'SR' => 'Sulinamu',
 			'ST' => 'Sayo Tome ni Pilinikipe',
 			'SV' => 'Elisavado',
 			'SY' => 'Siliya',
 			'SZ' => 'Uswasi',
 			'TC' => 'Figunguli fya Tuliki ni Kaiko',
 			'TD' => 'Shadi',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Tajikisitani',
 			'TK' => 'Tokelawu',
 			'TL' => 'Timoli ya kunena',
 			'TM' => 'Tulukimenisitani',
 			'TN' => 'Tunisiya',
 			'TO' => 'Tonga',
 			'TR' => 'Utuluki',
 			'TT' => 'Tilinidadi ni Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tansaniya',
 			'UA' => 'Yukileini',
 			'UG' => 'Uganda',
 			'US' => 'Malekani',
 			'UY' => 'Ulugwayi',
 			'UZ' => 'Usibekisitani',
 			'VA' => 'Vatikani',
 			'VC' => 'Santavisenti na Gilenadini',
 			'VE' => 'Venesuela',
 			'VG' => 'Figunguli ifya Viliginiya ifya Uwingelesa',
 			'VI' => 'Figunguli fya Viliginiya ifya Malekani',
 			'VN' => 'Vietinamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walisi ni Futuna',
 			'WS' => 'Samoya',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayote',
 			'ZA' => 'Afilika Kusini',
 			'ZM' => 'Sambiya',
 			'ZW' => 'Simbabwe',

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
			auxiliary => qr{[q r x z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'S', 'T', 'U', 'V', 'W', 'Y'],
			main => qr{[a b c d e f g h i j k l m n o p s t u v w y]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'S', 'T', 'U', 'V', 'W', 'Y'], };
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
	default		=> sub { qr'^(?i:Ena|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ndaali|N)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
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

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00¤',
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
				'currency' => q(Ihela ya Shitwa sha Shiyalabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Ihela ya Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ihela ya Awusitilaliya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Ihela ya Bahaleni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Ihela ya Bulundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Ihela ya Botiswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Ihela ya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Ihela ya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Ihela ya Uswisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Ihela ya Shina),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Ihela ya Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Ihela ya Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Ihela ya Alijeliya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ihela ya Misili),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Ihela ya Elitileya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ihela ya Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Ihela ya Ulaya),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Ihela ya Uwingelesa),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ihela ya Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Ihela ya Gambiya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Ihela ya Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Ihela ya Indiya),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Ihela ya Japani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Ihela ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Ihela ya Komolo),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Ihela ya Libeliya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Ihela ya Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Ihela ya Libiya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Ihela ya Moloko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ihela ya Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ihela ya Molitaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ihela ya Molitaniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Ihela ya Molisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Ihela ya Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Ihela ya Musumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Ihela ya Namibiya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Ihela ya Nijeliya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ihela ya Lwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Ihela ya Sawudiya),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Ihela ya Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Ihela ya Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Ihela ya Santahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Ihela ya Siela Liyoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Ihela ya Somaliya),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Ihela ya Sao Tome ni Pilinsipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Ihela ya Sao Tome ni Pilinsipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Ihela ya Uswasi),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Ihela ya Tunisiya),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(Ihela ya Tansaniya),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ihela ya Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Ihela ya Malekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Ihela ya CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Ihela ya CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ihela ya Afilika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Ihela ya Sambiya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Ihela ya Sambiya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Ihela ya Simbabwe),
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
							'Mup',
							'Mwi',
							'Msh',
							'Mun',
							'Mag',
							'Muj',
							'Msp',
							'Mpg',
							'Mye',
							'Mok',
							'Mus',
							'Muh'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mupalangulwa',
							'Mwitope',
							'Mushende',
							'Munyi',
							'Mushende Magali',
							'Mujimbi',
							'Mushipepo',
							'Mupuguto',
							'Munyense',
							'Mokhu',
							'Musongandembwe',
							'Muhaano'
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
						mon => 'Jtt',
						tue => 'Jnn',
						wed => 'Jtn',
						thu => 'Alh',
						fri => 'Iju',
						sat => 'Jmo',
						sun => 'Mul'
					},
					wide => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alahamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Mulungu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'J',
						tue => 'J',
						wed => 'J',
						thu => 'A',
						fri => 'I',
						sat => 'J',
						sun => 'M'
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
					'am' => q{Lwamilawu},
					'pm' => q{Pashamihe},
				},
				'wide' => {
					'am' => q{Lwamilawu},
					'pm' => q{Pashamihe},
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
				'0' => 'AK',
				'1' => 'PK'
			},
			wide => {
				'0' => 'Ashanali uKilisito',
				'1' => 'Pamwandi ya Kilisto'
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
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d y},
			yMd => q{M/d/y},
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
