=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cgg - Package for language Chiga

=cut

package Locale::CLDR::Locales::Cgg;
# This file auto generated from Data\common\main\cgg.xml
#	on Tue  5 Dec  1:04:44 pm GMT

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
				'ak' => 'Orukani',
 				'am' => 'Orumariki',
 				'ar' => 'Oruharabu',
 				'be' => 'Oruberarusi',
 				'bg' => 'Oruburugariya',
 				'bn' => 'Orubengari',
 				'cgg' => 'Rukiga',
 				'cs' => 'Oruceeki',
 				'de' => 'Orugirimaani',
 				'el' => 'Oruguriiki',
 				'en' => 'Orungyereza',
 				'es' => 'Orusupaani',
 				'fa' => 'Orupaasiya',
 				'fr' => 'Orufaransa',
 				'ha' => 'Oruhausa',
 				'hi' => 'Oruhindi',
 				'hu' => 'Oruhangare',
 				'id' => 'Oruindonezia',
 				'ig' => 'Oruibo',
 				'it' => 'Oruyitare',
 				'ja' => 'Orujapaani',
 				'jv' => 'Orujava',
 				'km' => 'Orukambodiya',
 				'ko' => 'Orukoreya',
 				'ms' => 'Orumalesiya',
 				'my' => 'Oruburuma',
 				'ne' => 'Orunepali',
 				'nl' => 'Orudaaki',
 				'pa' => 'Orupungyabi',
 				'pl' => 'Orupoori',
 				'pt' => 'Orupocugo',
 				'ro' => 'Oruromania',
 				'ru' => 'Orurrasha',
 				'rw' => 'Orunyarwanda',
 				'so' => 'Orusomaari',
 				'sv' => 'Oruswidi',
 				'ta' => 'Orutamiri',
 				'th' => 'Orutailandi',
 				'tr' => 'Orukuruki',
 				'uk' => 'Orukuraini',
 				'ur' => 'Oru-Urudu',
 				'vi' => 'Oruviyetinaamu',
 				'yo' => 'Oruyoruba',
 				'zh' => 'Oruchaina',
 				'zu' => 'Oruzuru',

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
			'AD' => 'Andora',
 			'AE' => 'Amahanga ga Buharabu ageeteereine',
 			'AF' => 'Afuganistani',
 			'AG' => 'Angiguwa na Babuda',
 			'AI' => 'Angwira',
 			'AL' => 'Arubania',
 			'AM' => 'Arimeniya',
 			'AO' => 'Angora',
 			'AR' => 'Arigentina',
 			'AS' => 'Samowa ya Ameerika',
 			'AT' => 'Osituria',
 			'AU' => 'Ositureeriya',
 			'AW' => 'Aruba',
 			'AZ' => 'Azabagyani',
 			'BA' => 'Boziniya na Hezegovina',
 			'BB' => 'Babadosi',
 			'BD' => 'Bangaradeshi',
 			'BE' => 'Bubirigi',
 			'BF' => 'Bokina Faso',
 			'BG' => 'Burugariya',
 			'BH' => 'Bahareni',
 			'BI' => 'Burundi',
 			'BJ' => 'Benini',
 			'BM' => 'Berimuda',
 			'BN' => 'Burunei',
 			'BO' => 'Boriiviya',
 			'BR' => 'Buraziiri',
 			'BS' => 'Bahama',
 			'BT' => 'Butani',
 			'BW' => 'Botswana',
 			'BY' => 'Bararusi',
 			'BZ' => 'Berize',
 			'CA' => 'Kanada',
 			'CD' => 'Demokoratika Ripaaburika ya Kongo',
 			'CF' => 'Eihanga rya Rwagati ya Afirika',
 			'CG' => 'Kongo',
 			'CH' => 'Swisi',
 			'CI' => 'Aivore Kositi',
 			'CK' => 'Ebizinga bya Kuuku',
 			'CL' => 'Chile',
 			'CM' => 'Kameruuni',
 			'CN' => 'China',
 			'CO' => 'Korombiya',
 			'CR' => 'Kositarika',
 			'CU' => 'Cuba',
 			'CV' => 'Ebizinga bya Kepuvade',
 			'CY' => 'Saipurasi',
 			'CZ' => 'Ripaaburika ya Zeeki',
 			'DE' => 'Bugirimaani',
 			'DJ' => 'Gyibuti',
 			'DK' => 'Deenimaaka',
 			'DM' => 'Dominika',
 			'DO' => 'Ripaaburika ya Dominica',
 			'DZ' => 'Arigyeriya',
 			'EC' => 'Ikweda',
 			'EE' => 'Esitoniya',
 			'EG' => 'Misiri',
 			'ER' => 'Eriteriya',
 			'ES' => 'Sipeyini',
 			'ET' => 'Ethiyopiya',
 			'FI' => 'Bufini',
 			'FJ' => 'Figyi',
 			'FK' => 'Ebizinga bya Faakilanda',
 			'FM' => 'Mikironesiya',
 			'FR' => 'Bufaransa',
 			'GA' => 'Gabooni',
 			'GB' => 'Bungyereza',
 			'GD' => 'Gurenada',
 			'GE' => 'Gyogiya',
 			'GF' => 'Guyana ya Bufaransa',
 			'GH' => 'Gana',
 			'GI' => 'Giburaata',
 			'GL' => 'Guriinirandi',
 			'GM' => 'Gambiya',
 			'GN' => 'Gine',
 			'GP' => 'Gwaderupe',
 			'GQ' => 'Guni',
 			'GR' => 'Guriisi',
 			'GT' => 'Gwatemara',
 			'GU' => 'Gwamu',
 			'GW' => 'Ginebisau',
 			'GY' => 'Guyana',
 			'HN' => 'Hondurasi',
 			'HR' => 'Korasiya',
 			'HT' => 'Haiti',
 			'HU' => 'Hangare',
 			'ID' => 'Indoneeziya',
 			'IE' => 'Irerandi',
 			'IL' => 'Isirairi',
 			'IN' => 'Indiya',
 			'IQ' => 'Iraaka',
 			'IR' => 'Iraani',
 			'IS' => 'Aisilandi',
 			'IT' => 'Itare',
 			'JM' => 'Gyamaika',
 			'JO' => 'Yorudaani',
 			'JP' => 'Gyapaani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizistani',
 			'KH' => 'Kambodiya',
 			'KI' => 'Kiribati',
 			'KM' => 'Koromo',
 			'KN' => 'Senti Kittis na Nevisi',
 			'KP' => 'Koreya Amatemba',
 			'KR' => 'Koreya Amashuuma',
 			'KW' => 'Kuweiti',
 			'KY' => 'Ebizinga bya Kayimani',
 			'KZ' => 'Kazakisitani',
 			'LA' => 'Layosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Senti Rusiya',
 			'LI' => 'Lishenteni',
 			'LK' => 'Siriranka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Lakizembaaga',
 			'LV' => 'Latviya',
 			'LY' => 'Libya',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moridova',
 			'MG' => 'Madagasika',
 			'MH' => 'Ebizinga bya Marshaa',
 			'MK' => 'Masedoonia',
 			'ML' => 'Mari',
 			'MM' => 'Myanamar',
 			'MN' => 'Mongoria',
 			'MP' => 'Ebizinga by’amatemba ga Mariana',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauriteeniya',
 			'MS' => 'Montserrati',
 			'MT' => 'Marita',
 			'MU' => 'Maurishiasi',
 			'MV' => 'Maridives',
 			'MW' => 'Marawi',
 			'MX' => 'Mexico',
 			'MY' => 'marayizia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibiya',
 			'NC' => 'Niukaredonia',
 			'NE' => 'Naigya',
 			'NF' => 'Ekizinga Norifoko',
 			'NG' => 'Naigyeriya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Hoorandi',
 			'NO' => 'Noorwe',
 			'NP' => 'Nepo',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Niuzirandi',
 			'OM' => 'Omaani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia ya Bufaransa',
 			'PG' => 'Papua',
 			'PH' => 'Firipino',
 			'PK' => 'Pakisitaani',
 			'PL' => 'Poorandi',
 			'PM' => 'Senti Piyerre na Mikweron',
 			'PN' => 'Pitkaini',
 			'PR' => 'Pwetoriko',
 			'PT' => 'Pocugo',
 			'PW' => 'Palaawu',
 			'PY' => 'Paragwai',
 			'QA' => 'Kata',
 			'RE' => 'Riyuniyoni',
 			'RO' => 'Romaniya',
 			'RU' => 'Rrasha',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Areebiya',
 			'SB' => 'Ebizinga bya Surimaani',
 			'SC' => 'Shesheresi',
 			'SD' => 'Sudani',
 			'SE' => 'Swideni',
 			'SG' => 'Singapo',
 			'SH' => 'Senti Herena',
 			'SI' => 'Sirovaaniya',
 			'SK' => 'Sirovaakiya',
 			'SL' => 'Sirra Riyooni',
 			'SM' => 'Samarino',
 			'SN' => 'Senego',
 			'SO' => 'Somaariya',
 			'SR' => 'Surinaamu',
 			'ST' => 'Sawo Tome na Purinsipo',
 			'SV' => 'Eri Salivado',
 			'SY' => 'Siriya',
 			'SZ' => 'Swazirandi',
 			'TC' => 'Ebizinga bya Buturuki na Kaiko',
 			'TD' => 'Chadi',
 			'TG' => 'Togo',
 			'TH' => 'Tairandi',
 			'TJ' => 'Tajikisitani',
 			'TK' => 'Tokerawu',
 			'TL' => 'Burugweizooba bwa Timori',
 			'TM' => 'Turukimenisitani',
 			'TN' => 'Tunizia',
 			'TO' => 'Tonga',
 			'TR' => 'Buturuki /Take',
 			'TT' => 'Turinidad na Tobago',
 			'TV' => 'Tuvaru',
 			'TW' => 'Tayiwaani',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukureini',
 			'UG' => 'Uganda',
 			'US' => 'Amerika',
 			'UY' => 'Urugwai',
 			'UZ' => 'Uzibekisitani',
 			'VA' => 'Vatikani',
 			'VC' => 'Senti Vinsent na Gurenadini',
 			'VE' => 'Venezuwera',
 			'VG' => 'Ebizinga bya Virigini ebya Bungyereza',
 			'VI' => 'Ebizinga bya Virigini ebya Amerika',
 			'VN' => 'Viyetinaamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Warris na Futuna',
 			'WS' => 'Samowa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayote',
 			'ZA' => 'Sausi Afirika',
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
	default		=> sub { qr'^(?i:Eego|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ngaaha/apaana|N)$' }
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
				'currency' => q(Dirham za Buharabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza ya Angora),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Doora ya Austureeriya),
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
				'currency' => q(Pura ya Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Doora ya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranga ya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranga ya Swisi),
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
				'currency' => q(Faranga ya Gyibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinari ya Arigyeriya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Paundi ya Misiri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa ya Eritireya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr ya Ethiopiya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Paundi ya Bungyereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi ya Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ya Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ya Guinea),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupiya ya India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ya Japaani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shiringi ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranga ya Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Doora ya Liberia),
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
				'currency' => q(Dirram ya Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariari ya Maragariita),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ougwiya ya Mouriteeniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ougwiya ya Mouriteeniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupiiha ya Mauritiasi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwaca ya Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikari ya Mozambikwi),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Doora ya Namibiya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Naigyeriya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faranga ya Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riya ya Saudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupiiha ya Sherisheri),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinari ya Sudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Paundi ya Sudan),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Paundi ya Senti Herena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Eshiringi ya Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Purinsipo \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Purinsipo),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinari ya Tunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Eshiringi ya Tanzania),
			},
		},
		'UGX' => {
			symbol => 'USh',
			display_name => {
				'currency' => q(Eshiringi ya Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Doora ya America),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga ya CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga ya CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi ya Sausi Afirika),
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
				'currency' => q(Doora ya Zimbabwe),
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
							'KBZ',
							'KBR',
							'KST',
							'KKN',
							'KTN',
							'KMK',
							'KMS',
							'KMN',
							'KMW',
							'KKM',
							'KNK',
							'KNB'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Okwokubanza',
							'Okwakabiri',
							'Okwakashatu',
							'Okwakana',
							'Okwakataana',
							'Okwamukaaga',
							'Okwamushanju',
							'Okwamunaana',
							'Okwamwenda',
							'Okwaikumi',
							'Okwaikumi na kumwe',
							'Okwaikumi na ibiri'
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
						mon => 'ORK',
						tue => 'OKB',
						wed => 'OKS',
						thu => 'OKN',
						fri => 'OKT',
						sat => 'OMK',
						sun => 'SAN'
					},
					wide => {
						mon => 'Orwokubanza',
						tue => 'Orwakabiri',
						wed => 'Orwakashatu',
						thu => 'Orwakana',
						fri => 'Orwakataano',
						sat => 'Orwamukaaga',
						sun => 'Sande'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'K',
						tue => 'R',
						wed => 'S',
						thu => 'N',
						fri => 'T',
						sat => 'M',
						sun => 'S'
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
					wide => {0 => 'KWOTA 1',
						1 => 'KWOTA 2',
						2 => 'KWOTA 3',
						3 => 'KWOTA 4'
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Kurisito Atakaijire',
				'1' => 'Kurisito Yaijire'
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
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
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
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
