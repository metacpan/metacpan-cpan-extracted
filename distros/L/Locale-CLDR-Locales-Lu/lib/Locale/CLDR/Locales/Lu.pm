=head1

Locale::CLDR::Locales::Lu - Package for language Luba-Katanga

=cut

package Locale::CLDR::Locales::Lu;
# This file auto generated from Data\common\main\lu.xml
#	on Fri 29 Apr  7:15:41 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
				'ak' => 'Liakan',
 				'am' => 'Liamhariki',
 				'ar' => 'Arabi',
 				'be' => 'Belarusi',
 				'bg' => 'Bulegari',
 				'bn' => 'Bengali',
 				'cs' => 'Tsheki',
 				'de' => 'Lizelumani',
 				'el' => 'Giliki',
 				'en' => 'Lingelesa',
 				'es' => 'Lihispania',
 				'fa' => 'Mpepajemi',
 				'fr' => 'Mfwàlànsa',
 				'ha' => 'Hausa',
 				'hi' => 'Hindi',
 				'hu' => 'Hongili',
 				'id' => 'Lindonezia',
 				'ig' => 'Igbo',
 				'it' => 'Litali',
 				'ja' => 'Liyapani',
 				'jv' => 'Java',
 				'ko' => 'Likoreya',
 				'lu' => 'Tshiluba',
 				'ms' => 'Limalezia',
 				'ne' => 'nepali',
 				'nl' => 'olandi',
 				'pa' => 'Lipunjabi',
 				'pl' => 'Mpoloni',
 				'pt' => 'Mputulugɛsi',
 				'ro' => 'Liromani',
 				'ru' => 'Lirisi',
 				'rw' => 'kinyarwanda',
 				'so' => 'Lisomali',
 				'sv' => 'Lisuwidi',
 				'ta' => 'Mtamuili',
 				'th' => 'Ntailandi',
 				'tr' => 'Ntuluki',
 				'uk' => 'Nkrani',
 				'ur' => 'Urdu',
 				'vi' => 'Liviyetinamu',
 				'yo' => 'Nyoruba',
 				'zh' => 'shinɛ',
 				'zu' => 'Nzulu',

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
			'AD' => 'Andore',
 			'AE' => 'Lemila alabu',
 			'AF' => 'Afuganisita',
 			'AG' => 'Antiga ne Barbuda',
 			'AI' => 'Angiye',
 			'AL' => 'Alubani',
 			'AM' => 'Ameni',
 			'AO' => 'Angola',
 			'AR' => 'Alijantine',
 			'AS' => 'Samoa wa Ameriki',
 			'AT' => 'Otilisi',
 			'AU' => 'Ositali',
 			'AW' => 'Aruba',
 			'AZ' => 'Ajelbayidja',
 			'BA' => 'Mbosini ne Hezegovine',
 			'BB' => 'Barebade',
 			'BD' => 'Benguladeshi',
 			'BE' => 'Belejiki',
 			'BF' => 'Bukinafaso',
 			'BG' => 'Biligari',
 			'BH' => 'Bahrene',
 			'BI' => 'Burundi',
 			'BJ' => 'Bene',
 			'BM' => 'Bermuda',
 			'BN' => 'Brineyi',
 			'BO' => 'Mbolivi',
 			'BR' => 'Mnulezile',
 			'BS' => 'Bahamase',
 			'BT' => 'Butani',
 			'BW' => 'Mbotswana',
 			'BY' => 'Byelorisi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Ditunga wa Kongu',
 			'CF' => 'Ditunga dya Afrika wa munkatshi',
 			'CG' => 'Kongu',
 			'CH' => 'Swise',
 			'CI' => 'Kotedivuale',
 			'CK' => 'Lutanda lua Kookɛ',
 			'CL' => 'Shili',
 			'CM' => 'Kamerune',
 			'CN' => 'Shine',
 			'CO' => 'Kolombi',
 			'CR' => 'Kositarika',
 			'CU' => 'Kuba',
 			'CV' => 'Lutanda lua Kapevele',
 			'CY' => 'Shipele',
 			'CZ' => 'Ditunga dya Tsheka',
 			'DE' => 'Alemanu',
 			'DJ' => 'Djibuti',
 			'DK' => 'Danemalaku',
 			'DM' => 'Duminiku',
 			'DO' => 'Ditunga wa Duminiku',
 			'DZ' => 'Alijeri',
 			'EC' => 'Ekwatele',
 			'EE' => 'Esitoni',
 			'EG' => 'Mushidi',
 			'ER' => 'Elitele',
 			'ES' => 'Nsipani',
 			'ET' => 'Etshiopi',
 			'FI' => 'Filande',
 			'FJ' => 'Fuji',
 			'FK' => 'Lutanda lua Maluni',
 			'FM' => 'Mikronezi',
 			'FR' => 'Nfalanse',
 			'GA' => 'Ngabu',
 			'GB' => 'Angeletele',
 			'GD' => 'Ngelenade',
 			'GE' => 'Joriji',
 			'GF' => 'Giyane wa Nfalanse',
 			'GH' => 'Ngana',
 			'GI' => 'Jibeletale',
 			'GL' => 'Ngowelande',
 			'GM' => 'Gambi',
 			'GN' => 'Ngine',
 			'GP' => 'Ngwadelupe',
 			'GQ' => 'Gine Ekwatele',
 			'GR' => 'Ngeleka',
 			'GT' => 'Ngwatemala',
 			'GU' => 'Ngwame',
 			'GW' => 'Nginebisau',
 			'GY' => 'Ngiyane',
 			'HN' => 'Ondurase',
 			'HR' => 'Krowasi',
 			'HT' => 'Ayiti',
 			'HU' => 'Ongili',
 			'ID' => 'Indonezi',
 			'IE' => 'Irelande',
 			'IL' => 'Isirayele',
 			'IN' => 'Inde',
 			'IO' => 'Lutanda lwa Angeletele ku mbu wa Indiya',
 			'IQ' => 'Iraki',
 			'IR' => 'Ira',
 			'IS' => 'Isilande',
 			'IT' => 'Itali',
 			'JM' => 'Jamaiki',
 			'JO' => 'Jodani',
 			'JP' => 'Japu',
 			'KE' => 'Kenya',
 			'KG' => 'Kigizisita',
 			'KH' => 'Kambodza',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoru',
 			'KN' => 'Santu krístofe ne Neves',
 			'KP' => 'Kore wa muulu',
 			'KR' => 'Kore wa mwinshi',
 			'KW' => 'Koweti',
 			'KY' => 'Lutanda lua Kayima',
 			'KZ' => 'Kazakusita',
 			'LA' => 'Lawosi',
 			'LB' => 'Liba',
 			'LC' => 'Santu lisi',
 			'LI' => 'Lishuteni',
 			'LK' => 'Sirilanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwani',
 			'LU' => 'Likisambulu',
 			'LV' => 'Letoni',
 			'LY' => 'Libi',
 			'MA' => 'Maroke',
 			'MC' => 'Monaku',
 			'MD' => 'Molidavi',
 			'MG' => 'Madagasikari',
 			'MH' => 'Lutanda lua Marishale',
 			'MK' => 'Masedwane',
 			'ML' => 'Mali',
 			'MM' => 'Myamare',
 			'MN' => 'Mongoli',
 			'MP' => 'Lutanda lua Mariane wa muulu',
 			'MQ' => 'Martiniki',
 			'MR' => 'Moritani',
 			'MS' => 'Musera',
 			'MT' => 'Malite',
 			'MU' => 'Morise',
 			'MV' => 'Madive',
 			'MW' => 'Malawi',
 			'MX' => 'Meksike',
 			'MY' => 'Malezi',
 			'MZ' => 'Mozambiki',
 			'NA' => 'Namibi',
 			'NC' => 'Kaledoni wa mumu',
 			'NE' => 'Nijere',
 			'NF' => 'Lutanda lua Norfok',
 			'NG' => 'Nijerya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Olandɛ',
 			'NO' => 'Noriveje',
 			'NP' => 'Nepálɛ',
 			'NR' => 'Nauru',
 			'NU' => 'Nyue',
 			'NZ' => 'Zelanda wa mumu',
 			'OM' => 'Omane',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinezi wa Nfalanse',
 			'PG' => 'Papwazi wa Nginɛ wa mumu',
 			'PH' => 'Nfilipi',
 			'PK' => 'Pakisita',
 			'PL' => 'Mpoloni',
 			'PM' => 'Santu pététo ne Mikelu',
 			'PN' => 'Pikairni',
 			'PR' => 'Mpotoriku',
 			'PS' => 'Palesine',
 			'PT' => 'Mputulugeshi',
 			'PW' => 'Palau',
 			'PY' => 'Palagwei',
 			'QA' => 'Katari',
 			'RE' => 'Lenyo',
 			'RO' => 'Romani',
 			'RU' => 'Risi',
 			'RW' => 'Rwanda',
 			'SA' => 'Alabu Nsawudi',
 			'SB' => 'Lutanda lua Solomu',
 			'SC' => 'Seshele',
 			'SD' => 'Suda',
 			'SE' => 'Suwedi',
 			'SG' => 'Singapure',
 			'SH' => 'Santu eleni',
 			'SI' => 'Siloveni',
 			'SK' => 'Silovaki',
 			'SL' => 'Siera Leone',
 			'SM' => 'Santu Marine',
 			'SN' => 'Senegale',
 			'SO' => 'Somali',
 			'SR' => 'Suriname',
 			'ST' => 'Sao Tome ne Presipɛ',
 			'SV' => 'Savadore',
 			'SY' => 'Siri',
 			'SZ' => 'Swazilandi',
 			'TC' => 'Lutanda lua Tuluki ne Kaiko',
 			'TD' => 'Tshadi',
 			'TG' => 'Togu',
 			'TH' => 'Tayilanda',
 			'TJ' => 'Tazikisita',
 			'TK' => 'Tokelau',
 			'TL' => 'Timoru wa diboku',
 			'TM' => 'Tukemenisita',
 			'TN' => 'Tinizi',
 			'TO' => 'Tonga',
 			'TR' => 'Tuluki',
 			'TT' => 'Tinidade ne Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tanzani',
 			'UA' => 'Ukreni',
 			'UG' => 'Uganda',
 			'US' => 'Ameriki',
 			'UY' => 'Irigwei',
 			'UZ' => 'Uzibekisita',
 			'VA' => 'Nvatika',
 			'VC' => 'Santu vesa ne Ngelenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Lutanda lua Vierzi wa Angeletele',
 			'VI' => 'Lutanda lua Vierzi wa Ameriki',
 			'VN' => 'Viyetiname',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walise ne Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemenu',
 			'YT' => 'Mayote',
 			'ZA' => 'Afrika ya Súdi',
 			'ZM' => 'Zambi',
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
			auxiliary => qr{(?^u:[g r x])},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{(?^u:[a á à b c d e é è ɛ {ɛ́} {ɛ̀} f h i í ì j k l m n {ng} {ny} o ó ò ɔ {ɔ́} {ɔ̀} p {ph} q s {shi} t u ú ù v w y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Eyo|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:To|T|no|n)$' }
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
			'default' => {
				'standard' => {
					'' => '#,##0.###',
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
				'currency' => q(Ndiriha wa Lemila alabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza wa Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ndola wa Ositali),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Ndina wa Bahrene),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Nfalanga wa Bulundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula wa Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Ndola wa Kanada),
			},
		},
		'CDF' => {
			symbol => 'FC',
			display_name => {
				'currency' => q(Nfalanga wa Kongu),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Nfalanga wa Swise),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuani Renminbi wa Shine),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esikuludo wa Kapevere),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Nfalanga wa Dzibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Ndina wa Alijeri),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pauni wa Mushidi),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa wa Elitle),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bira wa Etshiopi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Iro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pauni wa Angeletele),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi wa Ngana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Ndalasi wa Ngambi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Nfalanga wa Ngina),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi wa Inde),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni wa Zapɔ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Nshili wa Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Nfalanga wa Komoru),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Ndola wa Liberya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti wa Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Ndina wa Libi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Ndiriha wa Maroke),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Nfalanga wa Madagasikare),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya wa Moritani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia wa Morisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwasha wa Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali wa Mozambiki),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Ndola wa Namibi),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira wa Nizerya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Nfalanga wa Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyale wa Alabu Nsawu),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupya wa Seshele),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Ndina wa Suda),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pauni wa Suda),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pauni wa Santu Elena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Nshili wa Somali),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra wa Sao Tome ne Presipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Ndina wa Tinizi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Nshili wa Tanzani),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Nshili wa Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Ndola wa Ameriki),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Nfalanga CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Nfalanga CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rande wa Afrika wa Mwinshi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwasha wa Zambi \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwasha wa Zambi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Ndola wa Zimbabwe),
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
							'Cio',
							'Lui',
							'Lus',
							'Muu',
							'Lum',
							'Luf',
							'Kab',
							'Lush',
							'Lut',
							'Lun',
							'Kas',
							'Cis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ciongo',
							'Lùishi',
							'Lusòlo',
							'Mùuyà',
							'Lumùngùlù',
							'Lufuimi',
							'Kabàlàshìpù',
							'Lùshìkà',
							'Lutongolo',
							'Lungùdi',
							'Kaswèkèsè',
							'Ciswà'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'C',
							'L',
							'L',
							'M',
							'L',
							'L',
							'K',
							'L',
							'L',
							'L',
							'K',
							'C'
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
						mon => 'Nko',
						tue => 'Ndy',
						wed => 'Ndg',
						thu => 'Njw',
						fri => 'Ngv',
						sat => 'Lub',
						sun => 'Lum'
					},
					wide => {
						mon => 'Nkodya',
						tue => 'Ndàayà',
						wed => 'Ndangù',
						thu => 'Njòwa',
						fri => 'Ngòvya',
						sat => 'Lubingu',
						sun => 'Lumingu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'N',
						tue => 'N',
						wed => 'N',
						thu => 'N',
						fri => 'N',
						sat => 'L',
						sun => 'L'
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
					abbreviated => {0 => 'M1',
						1 => 'M2',
						2 => 'M3',
						3 => 'M4'
					},
					wide => {0 => 'Mueji 1',
						1 => 'Mueji 2',
						2 => 'Mueji 3',
						3 => 'Mueji 4'
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
					'pm' => q{Dilolo},
					'am' => q{Dinda},
				},
				'wide' => {
					'pm' => q{Dilolo},
					'am' => q{Dinda},
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
				'0' => 'kmp. Y.K.',
				'1' => 'kny. Y. K.'
			},
			wide => {
				'0' => 'Kumpala kwa Yezu Kli',
				'1' => 'Kunyima kwa Yezu Kli'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/y},
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
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
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
