=head1

Locale::CLDR::Locales::Nmg - Package for language Kwasio

=cut

package Locale::CLDR::Locales::Nmg;
# This file auto generated from Data\common\main\nmg.xml
#	on Fri 29 Apr  7:20:12 pm GMT

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
				'ak' => 'Kiɛl akan',
 				'am' => 'Kiɛl amaria',
 				'ar' => 'Kiɛl b’árabe',
 				'be' => 'Kiɛl belarussie',
 				'bg' => 'Kiɛl bulgaria',
 				'bn' => 'Kiɛl bengalia',
 				'cs' => 'Kiɛl bó tchɛk',
 				'de' => 'Jáman',
 				'el' => 'Kiɛl bó grɛk',
 				'en' => 'Ngɛ̄lɛ̄n',
 				'es' => 'Paŋá',
 				'fa' => 'Kiɛl pɛrsia',
 				'fr' => 'Fala',
 				'ha' => 'Kiɛl máwúsá',
 				'hi' => 'Kiɛl b’indien',
 				'hu' => 'Kiɛl b’ɔ́ngrois',
 				'id' => 'Kiɛl indonesie',
 				'ig' => 'Kiɛl ikbo',
 				'it' => 'Kiɛl italia',
 				'ja' => 'Kiɛl bó japonɛ̌',
 				'jv' => 'Kiɛl bó javanɛ̌',
 				'km' => 'Kiɛl bó mɛr',
 				'ko' => 'Kiɛl koré',
 				'ms' => 'Kiɛl Malɛ̌siā',
 				'my' => 'Kiɛl birmania',
 				'ne' => 'Kiɛl nepal',
 				'nl' => 'Kiɛl bóllandais',
 				'nmg' => 'Kwasio',
 				'pa' => 'Kiɛl pɛndjabi',
 				'pl' => 'Kiɛl pɔlɔŋe',
 				'pt' => 'Kiɛl bó pɔ̄rtugɛ̂',
 				'ro' => 'Kiɛl bó rumɛ̂n',
 				'ru' => 'Kiɛl russia',
 				'rw' => 'Kiɛl rwandā',
 				'so' => 'Kiɛl somaliā',
 				'sv' => 'Kiɛl bó suedois',
 				'ta' => 'Kiɛl tamul',
 				'th' => 'Kiɛl thaï',
 				'tr' => 'Kiɛl bó turk',
 				'uk' => 'Kiɛl b’ukrɛ̄nien',
 				'ur' => 'Kiɛl úrdu',
 				'vi' => 'Kiɛl viɛtnam',
 				'yo' => 'Yorúbâ',
 				'zh' => 'Kiɛl bó chinois',
 				'zu' => 'Zulu',

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
			'AD' => 'Andɔ́ra',
 			'AE' => 'Minlambɔ́ Nsaŋ́nsa mí Arabia',
 			'AF' => 'Afganistaŋ',
 			'AG' => 'Antíga bá Barbúda',
 			'AI' => 'Anguílla',
 			'AL' => 'Albania',
 			'AM' => 'Arménia',
 			'AO' => 'Angola',
 			'AR' => 'Argentína',
 			'AS' => 'Samoa m ́Amɛ́rka',
 			'AT' => 'Ötrish',
 			'AU' => 'Östraliá',
 			'AW' => 'Árúba',
 			'AZ' => 'Azerbaïjaŋ',
 			'BA' => 'Bosnia na Ɛrzegovina',
 			'BB' => 'Barbado',
 			'BD' => 'Bɛŋgladɛsh',
 			'BE' => 'Bɛlgik',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BM' => 'Bɛrmuda',
 			'BN' => 'Brunɛi',
 			'BO' => 'Bolivia',
 			'BR' => 'Brésil',
 			'BS' => 'Bahamas',
 			'BT' => 'Butaŋ',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Bɛliz',
 			'CA' => 'Kanada',
 			'CD' => 'Kongó Zaïre',
 			'CF' => 'Sentrafríka',
 			'CG' => 'Kongo',
 			'CH' => 'Switzɛrland',
 			'CI' => 'Kote d´Ivoire',
 			'CK' => 'Maŋ́ má Kook',
 			'CL' => 'Tshili',
 			'CM' => 'Kamerun',
 			'CN' => 'Shine',
 			'CO' => 'Kɔlɔ́mbia',
 			'CR' => 'Kosta Ríka',
 			'CU' => 'Kuba',
 			'CV' => 'Maŋ́ má Kapvɛr',
 			'CY' => 'Sipria',
 			'CZ' => 'Nlambɔ́ bó tschɛk',
 			'DE' => 'Jaman',
 			'DJ' => 'Jibúti',
 			'DK' => 'Danemark',
 			'DM' => 'Dominíka',
 			'DO' => 'Nlambɔ́ Dominíka',
 			'DZ' => 'Algeria',
 			'EC' => 'Ekuateur',
 			'EE' => 'Ɛstonia',
 			'EG' => 'Ägyptɛn',
 			'ER' => 'Erytrea',
 			'ES' => 'Paŋá',
 			'ET' => 'Ethiopiá',
 			'FI' => 'Finlande',
 			'FJ' => 'Fijiá',
 			'FK' => 'Maŋ má Falkland',
 			'FM' => 'Mikronesia',
 			'FR' => 'Fala',
 			'GA' => 'Gabɔŋ',
 			'GB' => 'Nlambɔ́ Ngɛlɛn',
 			'GD' => 'Grenada',
 			'GE' => 'Jɔrgia',
 			'GF' => 'Guyane Fala',
 			'GH' => 'Gána',
 			'GI' => 'Gilbratar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guine',
 			'GP' => 'Guadeloup',
 			'GQ' => 'Guine Ekuatorial',
 			'GR' => 'Grɛce',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guine Bisso',
 			'GY' => 'Guyana',
 			'HN' => 'Ɔndúras',
 			'HR' => 'Kroasia',
 			'HT' => 'Haïti',
 			'HU' => 'Ɔngría',
 			'ID' => 'Indonesia',
 			'IE' => 'Irland',
 			'IL' => 'Äsrɛl',
 			'IN' => 'India',
 			'IO' => 'Nlambɔ́ ngɛlɛn ma yí maŋ ntsiɛh',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italia',
 			'JM' => 'Jamaika',
 			'JO' => 'Jɔrdania',
 			'JP' => 'Japɔn',
 			'KE' => 'Kɛnya',
 			'KG' => 'Kyrgystaŋ',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Kɔmɔr',
 			'KN' => 'Saint Kitts na Nevis',
 			'KP' => 'Koré yí bvuɔ',
 			'KR' => 'Koré yí sí',
 			'KW' => 'Kowɛit',
 			'KY' => 'Maŋ́ má kumbi',
 			'KZ' => 'Kazakstaŋ',
 			'LA' => 'Laos',
 			'LB' => 'Libaŋ',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Lishenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituaniá',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Marɔk',
 			'MC' => 'Monako',
 			'MD' => 'Mɔldavia',
 			'MG' => 'Madagaskar',
 			'MH' => 'Maŋ́ má Marshall',
 			'MK' => 'Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mɔngolia',
 			'MP' => 'Maŋ́ Mariá',
 			'MQ' => 'Martinika',
 			'MR' => 'Moritania',
 			'MS' => 'Mɔnserrat',
 			'MT' => 'Malta',
 			'MU' => 'Morisse',
 			'MV' => 'Maldivia',
 			'MW' => 'Malawi',
 			'MX' => 'Mɛxik',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibia',
 			'NC' => 'Kaledoni nwanah',
 			'NE' => 'Niger',
 			'NF' => 'Maŋ́ má Nɔrfɔrk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Nedɛrland',
 			'NO' => 'Nɔrvɛg',
 			'NP' => 'Nepal',
 			'NR' => 'Noru',
 			'NU' => 'Niuɛ',
 			'NZ' => 'Zeland nwanah',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polynesia Fala',
 			'PG' => 'Guine Papuasi',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistan',
 			'PL' => 'Pɔlɔŋ',
 			'PM' => 'Saint Peter ba Mikelɔn',
 			'PN' => 'Pitkairn',
 			'PR' => 'Puɛrto Riko',
 			'PS' => 'Palɛstin',
 			'PT' => 'Pɔrtugal',
 			'PW' => 'Palo',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'RE' => 'Réuniɔn',
 			'RO' => 'Roumania',
 			'RU' => 'Russi',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Maŋ́ má Salomɔn',
 			'SC' => 'Seychɛlle',
 			'SD' => 'Sudaŋ',
 			'SE' => 'Suɛd',
 			'SG' => 'Singapur',
 			'SH' => 'Saint Lina',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leɔn',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somália',
 			'SR' => 'Surinam',
 			'ST' => 'Sao Tomé ba Prinship',
 			'SV' => 'Salvadɔr',
 			'SY' => 'Syria',
 			'SZ' => 'Swaziland',
 			'TC' => 'Maŋ́ má Turk na Kaiko',
 			'TD' => 'Tshad',
 			'TG' => 'Togo',
 			'TH' => 'Taïland',
 			'TJ' => 'Tajikistaŋ',
 			'TK' => 'Tokelo',
 			'TL' => 'Timɔr tsindikēh',
 			'TM' => 'Turkmɛnistaŋ',
 			'TN' => 'Tunisiá',
 			'TO' => 'Tɔnga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad ba Tobágó',
 			'TV' => 'Tuvalú',
 			'TW' => 'Taïwan',
 			'TZ' => 'Tanzánía',
 			'UA' => 'Ukrɛn',
 			'UG' => 'Uganda',
 			'US' => 'Amɛŕka',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbǝkistaŋ',
 			'VA' => 'Vatikaŋ',
 			'VC' => 'Saint Vincent ba Grenadines',
 			'VE' => 'Vǝnǝzuela',
 			'VG' => 'Minsilɛ́ mímaŋ mí ngɛ̄lɛ̄n',
 			'VI' => 'Minsilɛ mí maŋ́ m´Amɛrka',
 			'VN' => 'Viɛtnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ba Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yǝmɛn',
 			'YT' => 'Mayɔt',
 			'ZA' => 'Afríka yí sí',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwǝ',

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
			auxiliary => qr{(?^u:[q x z])},
			index => ['A', 'B', 'Ɓ', 'C', 'D', 'E', 'Ǝ', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'],
			main => qr{(?^u:[a á â ǎ ä ā b ɓ c d e é ê ě ē ǝ {ǝ́} {ǝ̂} {ǝ̌} {ǝ̄} ɛ {ɛ́} {ɛ̂} {ɛ̌} {ɛ̄} f g h i í î ǐ ï ī j k l m n ń ŋ o ó ô ǒ ö ō ɔ {ɔ́} {ɔ̂} {ɔ̌} {ɔ̄} p r ŕ s t u ú û ǔ ū v w y])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ɓ', 'C', 'D', 'E', 'Ǝ', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'], };
},
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

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Yaŋ|Y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Nzúl|N)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
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
		percentFormat => {
			'default' => {
				'standard' => {
					'' => '#,##0%',
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
		'AED' => {
			display_name => {
				'currency' => q(Mɔn B ´Arabe),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Mɔn Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dɔ́llɔ Ɔstralia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Mɔn Bahrein),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Fraŋ Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Mɔn Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dɔ́llɔ Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Fraŋ bó Kongolɛ̌),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Fraŋ Suisse),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Mɔn bó Chinois),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Mɔn Kapvɛrt),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Fraŋ Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Mɔn Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Mɔn Ägyptɛn),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Mɔn Erytré),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Mɔn Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Mɔn Ngɛ̄lɛ̄n),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Mɔn Gana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Mɔn Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Fraŋ Guiné),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Mɔn India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Mɔn Japɔn),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Mɔn Kɛnya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Fraŋ bó Kɔmɔr),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dɔ́llɔ Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Mɔn Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Mɔn Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Mɔn Marɔk),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Mɔn Madagaskar),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mɔn Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mɔn Moriss),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Mɔn Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mɔn Mozambik),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dɔ́llɔ Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naïra Nigeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Fraŋ Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Mɔn Saudi Arabia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Mɔn Seychɛlle),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Mɔn Sudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Mɔn Sudan \(1957–1998\)),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Mɔn má Saint Lina),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Mɔn Leɔne),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Mɔn Somalía),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Mɔn Sao tomé na prinship),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Mɔn Ligangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Mɔn Tunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Mɔn Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Mɔn Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dɔ́llɔ Amɛŕka),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Fraŋ CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Fraŋ CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Mɔn Afrik yí sí),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Mɔn Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Mɔn Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dɔ́llɔ Zimbabwǝ \(1980–2008\)),
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
							'ng1',
							'ng2',
							'ng3',
							'ng4',
							'ng5',
							'ng6',
							'ng7',
							'ng8',
							'ng9',
							'ng10',
							'ng11',
							'kris'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ngwɛn matáhra',
							'ngwɛn ńmba',
							'ngwɛn ńlal',
							'ngwɛn ńna',
							'ngwɛn ńtan',
							'ngwɛn ńtuó',
							'ngwɛn hɛmbuɛrí',
							'ngwɛn lɔmbi',
							'ngwɛn rɛbvuâ',
							'ngwɛn wum',
							'ngwɛn wum navǔr',
							'krísimin'
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
						mon => 'mɔ́n',
						tue => 'smb',
						wed => 'sml',
						thu => 'smn',
						fri => 'mbs',
						sat => 'sas',
						sun => 'sɔ́n'
					},
					wide => {
						mon => 'mɔ́ndɔ',
						tue => 'sɔ́ndɔ mafú mába',
						wed => 'sɔ́ndɔ mafú málal',
						thu => 'sɔ́ndɔ mafú mána',
						fri => 'mabágá má sukul',
						sat => 'sásadi',
						sun => 'sɔ́ndɔ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'm',
						tue => 's',
						wed => 's',
						thu => 's',
						fri => 'm',
						sat => 's',
						sun => 's'
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => 'Tindɛ nvúr',
						1 => 'Tindɛ ńmba',
						2 => 'Tindɛ ńlal',
						3 => 'Tindɛ ńna'
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
					'am' => q{maná},
					'pm' => q{kugú},
				},
				'wide' => {
					'pm' => q{kugú},
					'am' => q{maná},
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
				'0' => 'BL',
				'1' => 'PB'
			},
			wide => {
				'0' => 'Bó Lahlɛ̄',
				'1' => 'Pfiɛ Burī'
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
