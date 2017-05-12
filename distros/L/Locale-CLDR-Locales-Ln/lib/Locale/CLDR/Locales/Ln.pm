=head1

Locale::CLDR::Locales::Ln - Package for language Lingala

=cut

package Locale::CLDR::Locales::Ln;
# This file auto generated from Data\common\main\ln.xml
#	on Fri 29 Apr  7:14:37 pm GMT

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
				'af' => 'afrikansi',
 				'ak' => 'akan',
 				'am' => 'liamariki',
 				'ar' => 'lialabo',
 				'be' => 'libyelorisí',
 				'bg' => 'libiligali',
 				'bn' => 'libengali',
 				'cs' => 'litshekɛ',
 				'de' => 'lialemá',
 				'de_AT' => 'lialémani ya Otrish',
 				'de_CH' => 'lialémani ya Swisi',
 				'el' => 'ligeleki',
 				'en' => 'lingɛlɛ́sa',
 				'en_CA' => 'lingɛlɛ́sa ya Kanadá',
 				'en_GB' => 'lingɛlɛ́sa ya Ingɛlɛ́tɛlɛ',
 				'es' => 'lisipanye',
 				'es_419' => 'lispanyoli ya Ameríka Latína',
 				'es_ES' => 'lispanyoli ya Erópa',
 				'fa' => 'lipelésanɛ',
 				'fr' => 'lifalansɛ́',
 				'fr_CA' => 'lifalansɛ́ ya Kanadá',
 				'fr_CH' => 'lifalansɛ́ ya Swisi',
 				'gsw' => 'lialemaniki',
 				'ha' => 'hausa',
 				'he' => 'liébeleo',
 				'hi' => 'lihindi',
 				'hu' => 'liongili',
 				'id' => 'lindonezi',
 				'ig' => 'igbo',
 				'it' => 'litaliano',
 				'ja' => 'lizapɔ',
 				'jv' => 'lizava',
 				'kg' => 'kikɔ́ngɔ',
 				'km' => 'likambodza',
 				'ko' => 'likoreya',
 				'la' => 'latina',
 				'ln' => 'lingála',
 				'lu' => 'kiluba',
 				'lua' => 'ciluba',
 				'ms' => 'limalezi',
 				'my' => 'libilimá',
 				'ne' => 'linepalɛ',
 				'nl' => 'lifalamá',
 				'pa' => 'lipendzabi',
 				'pl' => 'lipolonɛ',
 				'pt' => 'lipulutugɛ́si',
 				'pt_BR' => 'lipulutugɛ́si ya Brazil',
 				'pt_PT' => 'lipulutugɛ́si ya Erópa',
 				'rm' => 'liromansh',
 				'ro' => 'liromani',
 				'ru' => 'lirisí',
 				'rw' => 'kinyarwanda',
 				'so' => 'lisomali',
 				'sv' => 'lisuwedɛ',
 				'sw' => 'kiswahíli',
 				'ta' => 'litamuli',
 				'th' => 'litaye',
 				'tr' => 'litiliki',
 				'uk' => 'likrɛni',
 				'ur' => 'liurdu',
 				'vi' => 'liviyetinámi',
 				'yo' => 'yoruba',
 				'zh' => 'lisinwa',
 				'zu' => 'zulu',

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
			'001' => 'Mabelé',
 			'002' => 'Afríka',
 			'003' => 'Ameríka ya Nola',
 			'005' => 'Ameríka ya Sidi',
 			'011' => 'Afríka ya Wɛ́sita',
 			'013' => 'Ameríka ya káti',
 			'014' => 'Afríka ya Ɛ́sita',
 			'015' => 'Afríka ya Nola',
 			'017' => 'Afríka ya Katikáti',
 			'018' => 'Afríka ya Sidi',
 			'019' => 'Ameríka',
 			'030' => 'Azía ya Ɛ́sita',
 			'034' => 'Azía ya Sidi',
 			'035' => 'Azía ya Sidi-Ɛ́sita',
 			'039' => 'Erópa ya Sidi',
 			'142' => 'Azía',
 			'143' => 'Azía ya Katikáti',
 			'145' => 'Azía ya Wɛ́sita',
 			'150' => 'Erópa',
 			'151' => 'Erópa ya Ɛ́sita',
 			'154' => 'Erópa ya Nola',
 			'155' => 'Erópa ya Wɛ́sita',
 			'419' => 'Ameríka Latína',
 			'AC' => 'Esenga ya Mbuta o likoló',
 			'AD' => 'Andorɛ',
 			'AE' => 'Lɛmila alabo',
 			'AF' => 'Afiganisitá',
 			'AG' => 'Antiga mpé Barbuda',
 			'AI' => 'Angiyɛ',
 			'AL' => 'Alibani',
 			'AM' => 'Amɛni',
 			'AO' => 'Angóla',
 			'AQ' => 'Antarctique',
 			'AR' => 'Arizantinɛ',
 			'AS' => 'Samoa ya Ameriki',
 			'AT' => 'Otilisi',
 			'AU' => 'Ositáli',
 			'AW' => 'Aruba',
 			'AX' => 'Bisanga Ɛland',
 			'AZ' => 'Azɛlɛbaizá',
 			'BA' => 'Bosini mpé Hezegovine',
 			'BB' => 'Barɛbadɛ',
 			'BD' => 'Bengalidɛsi',
 			'BE' => 'Beleziki',
 			'BF' => 'Bukina Faso',
 			'BG' => 'Biligari',
 			'BH' => 'Bahrɛnɛ',
 			'BI' => 'Burundi',
 			'BJ' => 'Benɛ',
 			'BM' => 'Bermuda',
 			'BN' => 'Brineyi',
 			'BO' => 'Bolivi',
 			'BR' => 'Brezílɛ',
 			'BS' => 'Bahamasɛ',
 			'BT' => 'Butáni',
 			'BV' => 'Esenga Buvé',
 			'BW' => 'Botswana',
 			'BY' => 'Byelorisi',
 			'BZ' => 'Belizɛ',
 			'CA' => 'Kanada',
 			'CC' => 'Bisanga Kokos',
 			'CD' => 'Repibiki demokratiki ya Kongó',
 			'CD@alt=variant' => 'Kongó-Kinsásá',
 			'CF' => 'Repibiki ya Afríka ya Káti',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Kongó-Brazzaville',
 			'CH' => 'Swisɛ',
 			'CI' => 'Kotídivualɛ',
 			'CK' => 'Bisanga bya Kookɛ',
 			'CL' => 'Síli',
 			'CM' => 'Kamɛrune',
 			'CN' => 'Sinɛ',
 			'CO' => 'Kolombi',
 			'CR' => 'Kositarika',
 			'CU' => 'Kiba',
 			'CV' => 'Bisanga bya Kapevɛrɛ',
 			'CX' => 'Esenga ya Mbótama',
 			'CY' => 'Sípɛlɛ',
 			'CZ' => 'Repibiki Tsekɛ',
 			'DE' => 'Alemani',
 			'DJ' => 'Dzibuti',
 			'DK' => 'Danɛmarike',
 			'DM' => 'Domínike',
 			'DO' => 'Repibiki ya Domínikɛ',
 			'DZ' => 'Alizɛri',
 			'EA' => 'Zewta mpé Melílla',
 			'EC' => 'Ekwatɛ́lɛ',
 			'EE' => 'Esitoni',
 			'EG' => 'Ezípite',
 			'EH' => 'Sahara ya Limbɛ',
 			'ER' => 'Elitelɛ',
 			'ES' => 'Esipanye',
 			'ET' => 'Etsíopi',
 			'EU' => 'Lisangá ya Erópa',
 			'FI' => 'Filandɛ',
 			'FJ' => 'Fidzi',
 			'FK' => 'Bisanga bya Maluni',
 			'FK@alt=variant' => 'Bisanga bya Falkland',
 			'FM' => 'Mikronezi',
 			'FO' => 'Bisanga ya Fɛróa',
 			'FR' => 'Falánsɛ',
 			'GA' => 'Gabɔ',
 			'GB' => 'Angɛlɛtɛ́lɛ',
 			'GD' => 'Gelenadɛ',
 			'GE' => 'Zorzi',
 			'GF' => 'Giyanɛ ya Falánsɛ',
 			'GG' => 'Guernesey',
 			'GH' => 'Gana',
 			'GI' => 'Zibatalɛ',
 			'GL' => 'Gowelande',
 			'GM' => 'Gambi',
 			'GN' => 'Ginɛ',
 			'GP' => 'Gwadɛlupɛ',
 			'GQ' => 'Ginɛ́kwatɛ́lɛ',
 			'GR' => 'Geleki',
 			'GS' => 'Îles de Géorgie du Sud et Sandwich du Sud',
 			'GT' => 'Gwatémala',
 			'GU' => 'Gwamɛ',
 			'GW' => 'Ginɛbisau',
 			'GY' => 'Giyane',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ile Heard et Iles McDonald',
 			'HN' => 'Ondurasɛ',
 			'HR' => 'Krowasi',
 			'HT' => 'Ayiti',
 			'HU' => 'Ongili',
 			'IC' => 'Bisanga bya Kanári',
 			'ID' => 'Indonezi',
 			'IE' => 'Irelandɛ',
 			'IL' => 'Isirayelɛ',
 			'IM' => 'Esanga ya Man',
 			'IN' => 'Índɛ',
 			'IO' => 'Mabelé ya Angɛlɛtɛ́lɛ na mbú ya Indiya',
 			'IQ' => 'Iraki',
 			'IR' => 'Irâ',
 			'IS' => 'Isilandɛ',
 			'IT' => 'Itali',
 			'JM' => 'Zamaiki',
 			'JO' => 'Zɔdani',
 			'JP' => 'Zapɔ',
 			'KE' => 'Kenya',
 			'KG' => 'Kigizisitá',
 			'KH' => 'Kambodza',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorɛ',
 			'KN' => 'Sántu krístofe mpé Nevɛ̀s',
 			'KP' => 'Korɛ ya nɔ́rdi',
 			'KR' => 'Korɛ ya súdi',
 			'KW' => 'Koweti',
 			'KY' => 'Bisanga bya Kayíma',
 			'KZ' => 'Kazakisitá',
 			'LA' => 'Lawosi',
 			'LB' => 'Libá',
 			'LC' => 'Sántu lisi',
 			'LI' => 'Lishɛteni',
 			'LK' => 'Sirilanka',
 			'LR' => 'Libériya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwani',
 			'LU' => 'Likisambulu',
 			'LV' => 'Letoni',
 			'LY' => 'Libí',
 			'MA' => 'Marokɛ',
 			'MC' => 'Monako',
 			'MD' => 'Molidavi',
 			'ME' => 'Monténégro',
 			'MG' => 'Madagasikari',
 			'MH' => 'Bisanga bya Marishalɛ',
 			'MK' => 'Masedwanɛ',
 			'MK@alt=variant' => 'Masedoni',
 			'ML' => 'Malí',
 			'MM' => 'Birmanie',
 			'MN' => 'Mongolí',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Bisanga bya Marianɛ ya nɔ́rdi',
 			'MQ' => 'Martiniki',
 			'MR' => 'Moritani',
 			'MS' => 'Mɔsera',
 			'MT' => 'Malitɛ',
 			'MU' => 'Morisɛ',
 			'MV' => 'Madívɛ',
 			'MW' => 'Malawi',
 			'MX' => 'Meksike',
 			'MY' => 'Malezi',
 			'MZ' => 'Mozambíki',
 			'NA' => 'Namibi',
 			'NC' => 'Kaledoni ya sika',
 			'NE' => 'Nizɛrɛ',
 			'NF' => 'Esanga Norfokɛ',
 			'NG' => 'Nizerya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Olandɛ',
 			'NO' => 'Norivezɛ',
 			'NP' => 'Nepálɛ',
 			'NR' => 'Nauru',
 			'NU' => 'Nyué',
 			'NZ' => 'Zelandɛ ya sika',
 			'OM' => 'Ománɛ',
 			'PA' => 'Panama',
 			'PE' => 'Péru',
 			'PF' => 'Polinezi ya Falánsɛ',
 			'PG' => 'Papwazi Ginɛ ya sika',
 			'PH' => 'Filipinɛ',
 			'PK' => 'Pakisitá',
 			'PL' => 'Poloni',
 			'PM' => 'Sántu pététo mpé Mikelɔ',
 			'PN' => 'Pikairni',
 			'PR' => 'Pɔtoriko',
 			'PS' => 'Palɛsine',
 			'PT' => 'Putúlugɛsi',
 			'PW' => 'Palau',
 			'PY' => 'Palagwei',
 			'QA' => 'Katari',
 			'RE' => 'Lenyo',
 			'RO' => 'Romani',
 			'RS' => 'Serbie',
 			'RU' => 'Risí',
 			'RW' => 'Rwanda',
 			'SA' => 'Alabi Sawuditɛ',
 			'SB' => 'Bisanga Solomɔ',
 			'SC' => 'Sɛshɛlɛ',
 			'SD' => 'Sudá',
 			'SE' => 'Swédɛ',
 			'SG' => 'Singapurɛ',
 			'SH' => 'Sántu eleni',
 			'SI' => 'Siloveni',
 			'SJ' => 'Svalbard mpé Jan Mayen',
 			'SK' => 'Silovaki',
 			'SL' => 'Siera Leonɛ',
 			'SM' => 'Sántu Marinɛ',
 			'SN' => 'Senegalɛ',
 			'SO' => 'Somali',
 			'SR' => 'Surinamɛ',
 			'SS' => 'Sudani ya Sidi',
 			'ST' => 'Sao Tomé mpé Presipɛ',
 			'SV' => 'Savadɔrɛ',
 			'SY' => 'Sirí',
 			'SZ' => 'Swazilandi',
 			'TC' => 'Bisanga bya Turki mpé Kaiko',
 			'TD' => 'Tsádi',
 			'TF' => 'Terres australes et antarctiques françaises',
 			'TG' => 'Togo',
 			'TH' => 'Tailandɛ',
 			'TJ' => 'Tazikisitá',
 			'TK' => 'Tokelau',
 			'TL' => 'Timorɛ ya Moniɛlɛ',
 			'TL@alt=variant' => 'Timor ya monyɛlɛ',
 			'TM' => 'Tikɛménisitá',
 			'TN' => 'Tinizi',
 			'TO' => 'Tonga',
 			'TR' => 'Tiliki',
 			'TT' => 'Tinidadɛ mpé Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwanin',
 			'TZ' => 'Tanzani',
 			'UA' => 'Ikrɛni',
 			'UG' => 'Uganda',
 			'US' => 'Ameriki',
 			'UY' => 'Irigwei',
 			'UZ' => 'Uzibɛkisitá',
 			'VA' => 'Vatiká',
 			'VC' => 'Sántu vesá mpé Gelenadinɛ',
 			'VE' => 'Venézuela',
 			'VG' => 'Bisanga bya Vierzi ya Angɛlɛtɛ́lɛ',
 			'VI' => 'Bisanga bya Vierzi ya Ameriki',
 			'VN' => 'Viyetinamɛ',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walisɛ mpé Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemɛnɛ',
 			'YT' => 'Mayotɛ',
 			'ZA' => 'Afríka ya Súdi',
 			'ZM' => 'Zambi',
 			'ZW' => 'Zimbabwe',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Manáka',
 			'currency' => 'Mbɔ́ngɔ',
 			'numbers' => 'Mamɛlɔ',

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
 				'gregorian' => q{Manáka ma Gregɔr},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'lokótá {0}',
 			'region' => 'ndámbo na mokili {0}',

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
			auxiliary => qr{(?^u:[j q x])},
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', '{Gb}', 'H', 'I', 'K', 'L', 'M', '{Mb}', '{Mp}', 'N', '{Nd}', '{Ng}', '{Nk}', '{Ns}', '{Nt}', '{Ny}', '{Nz}', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{(?^u:[a á â ǎ b c d e é ê ě ɛ {ɛ́} {ɛ̂} {ɛ̌} f g {gb} h i í î ǐ k l m {mb} {mp} n {nd} {ng} {nk} {ns} {nt} {ny} {nz} o ó ô ǒ ɔ {ɔ́} {ɔ̂} {ɔ̌} p r s t u ú v w y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', '{Gb}', 'H', 'I', 'K', 'L', 'M', '{Mb}', '{Mp}', 'N', '{Nd}', '{Ng}', '{Nk}', '{Ns}', '{Nt}', '{Ny}', '{Nz}', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Íyo|Í|I|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Tɛ̂|T|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} mpé {1}),
				2 => q({0} mpé {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
			'infinity' => q(∞),
			'minusSign' => q(-),
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
				'currency' => q(Dirihamɛ ya Lémila alabo),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza ya Angóla),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso y’Argentina),
				'one' => q(Peso y’Argentina),
				'other' => q(Peso y’Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolarɛ ya Ositali),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinarɛ ya Bahrɛnɛ),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Falánga ya Burundi),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano),
				'one' => q(Boliviano),
				'other' => q(Boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real ya Brazil),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ya Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolarɛ ya Kanadá),
			},
		},
		'CDF' => {
			symbol => 'FC',
			display_name => {
				'currency' => q(Falánga ya Kongó),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Falánga ya Swisɛ),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso ya Shili),
				'one' => q(Peso ya Shili),
				'other' => q(Peso ya Shili),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuanɛ Renminbi ya Sinɛ),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso ya Kolombi),
				'one' => q(Peso ya Kolombi),
				'other' => q(Peso ya Kolombi),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon ya Kosta Rika),
				'one' => q(Colon ya Kosta Rika),
				'other' => q(Colon ya Kosta Rika),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso ya Kuba),
				'one' => q(Peso ya Kuba),
				'other' => q(Peso ya Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esikudo ya Kapevɛrɛ),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Motolé Sheki),
				'one' => q(Motolé Sheki),
				'other' => q(Motolé Sheki),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Falánga ya Dzibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Motolé ya Danemark),
				'one' => q(Motolé ya Danemark),
				'other' => q(Motolé ya Danemark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominikani),
				'one' => q(Peso Dominikani),
				'other' => q(Peso Dominikani),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinarɛ ya Alizeri),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Paunɛ ya Ezípitɛ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa ya Elitlɛ),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birɛ ya Etsiópi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Ɛlɔ́),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Paunɛ ya Angɛlɛtɛ́lɛ),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Gana),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi),
				'one' => q(Cedi),
				'other' => q(Cedi),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ya Gambi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Falánga ya Gine),
				'one' => q(Falánga ya Gine),
				'other' => q(Falánga ya Gine),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Falánga ya Ginɛ),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gurde),
				'one' => q(Gurde),
				'other' => q(Gurde),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi ya Índɛ),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Motolé ya Islandi),
				'one' => q(Motolé ya Islandi),
				'other' => q(Motolé ya Islandi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ya Zapɔ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilingɛ ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Falánga ya Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolarɛ ya Liberya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesóto),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas ya Litwani),
				'one' => q(Litas ya Litwani),
				'other' => q(Litas ya Litwani),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats ya Letoni),
				'one' => q(Lats ya Letoni),
				'other' => q(Lats ya Letoni),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinarɛ ya Libí),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirihame ya Marokɛ),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Falánga ya Madagasikarɛ),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya ya Moritani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupi ya Morisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwasha ya Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso ya Mexiko),
				'one' => q(Peso ya Mexiko),
				'other' => q(Peso ya Mexiko),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali ya Mozambiki),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolarɛ ya Namibi),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Nizerya),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Motolé ya Norvej),
				'one' => q(Motolé ya Norvej),
				'other' => q(Motolé ya Norvej),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa),
				'one' => q(Balboa),
				'other' => q(Balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Sika),
				'one' => q(Sol Sika),
				'other' => q(Sol Sika),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani),
				'one' => q(Guarani),
				'other' => q(Guarani),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Falánga ya Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyalɛ ya Alabi Sawuditɛ),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupi ya Sɛshɛlɛ),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinarɛ ya Sudá),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Paunɛ ya Sudá),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Motolé ya Swédi),
				'one' => q(Motolé ya Swédi),
				'other' => q(Motolé ya Swédi),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Paunɛ ya Sántu elena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leonɛ),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilingɛ ya Somali),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tomé mpé Presipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinarɛ ya Tinizi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilingɛ ya Tanzani),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingɛ ya Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolarɛ ya Ameriki),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Falánga CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Falánga CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randɛ ya Afríka Súdi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwasha ya Zambi \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwasha ya Zambi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dolarɛ ya Zimbabwɛ),
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
							'yan',
							'fbl',
							'msi',
							'apl',
							'mai',
							'yun',
							'yul',
							'agt',
							'stb',
							'ɔtb',
							'nvb',
							'dsb'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'sánzá ya yambo',
							'sánzá ya míbalé',
							'sánzá ya mísáto',
							'sánzá ya mínei',
							'sánzá ya mítáno',
							'sánzá ya motóbá',
							'sánzá ya nsambo',
							'sánzá ya mwambe',
							'sánzá ya libwa',
							'sánzá ya zómi',
							'sánzá ya zómi na mɔ̌kɔ́',
							'sánzá ya zómi na míbalé'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'y',
							'f',
							'm',
							'a',
							'm',
							'y',
							'y',
							'a',
							's',
							'ɔ',
							'n',
							'd'
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
						mon => 'ybo',
						tue => 'mbl',
						wed => 'mst',
						thu => 'min',
						fri => 'mtn',
						sat => 'mps',
						sun => 'eye'
					},
					wide => {
						mon => 'mokɔlɔ mwa yambo',
						tue => 'mokɔlɔ mwa míbalé',
						wed => 'mokɔlɔ mwa mísáto',
						thu => 'mokɔlɔ ya mínéi',
						fri => 'mokɔlɔ ya mítáno',
						sat => 'mpɔ́sɔ',
						sun => 'eyenga'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'y',
						tue => 'm',
						wed => 'm',
						thu => 'm',
						fri => 'm',
						sat => 'p',
						sun => 'e'
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
					abbreviated => {0 => 'SM1',
						1 => 'SM2',
						2 => 'SM3',
						3 => 'SM4'
					},
					wide => {0 => 'sánzá mísáto ya yambo',
						1 => 'sánzá mísáto ya míbalé',
						2 => 'sánzá mísáto ya mísáto',
						3 => 'sánzá mísáto ya mínei'
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
					'am' => q{ntɔ́ngɔ́},
					'pm' => q{mpókwa},
				},
				'wide' => {
					'am' => q{ntɔ́ngɔ́},
					'pm' => q{mpókwa},
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
				'0' => 'libóso ya',
				'1' => 'nsima ya Y'
			},
			wide => {
				'0' => 'Yambo ya Yézu Krís',
				'1' => 'Nsima ya Yézu Krís'
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Ngonga ya {0}),
		fallbackFormat => q({1} ({0})),
		'Africa_Central' => {
			long => {
				'standard' => q(Ntángo ya Lubumbashi),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(Ntángo ya Afríka ya Ɛ́sita),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(Ntángo ya Afríka ya Sidi),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(Ntángo ya Londoni),
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q(Ntángo ya Seyshel),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
