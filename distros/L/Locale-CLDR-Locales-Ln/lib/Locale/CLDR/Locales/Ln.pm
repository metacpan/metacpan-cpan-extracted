=encoding utf8

=head1

Locale::CLDR::Locales::Ln - Package for language Lingala

=cut

package Locale::CLDR::Locales::Ln;
# This file auto generated from Data\common\main\ln.xml
#	on Sun  3 Feb  2:02:50 pm GMT

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
 			'AC' => 'Esanga ya Mbuta o Likoló',
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
 			'BL' => 'Sántu Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brineyi',
 			'BO' => 'Bolivi',
 			'BR' => 'Brezílɛ',
 			'BS' => 'Bahamasɛ',
 			'BT' => 'Butáni',
 			'BV' => 'Esanga Buvé',
 			'BW' => 'Botswana',
 			'BY' => 'Byelorisi',
 			'BZ' => 'Belizɛ',
 			'CA' => 'Kanada',
 			'CC' => 'Bisanga Kokos',
 			'CD' => 'Republíki ya Kongó Demokratíki',
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
 			'CP' => 'Esanga Clipperton',
 			'CR' => 'Kositarika',
 			'CU' => 'Kiba',
 			'CV' => 'Bisanga bya Kapevɛrɛ',
 			'CX' => 'Esanga ya Mbótama',
 			'CY' => 'Sípɛlɛ',
 			'CZ' => 'Shekia',
 			'CZ@alt=variant' => 'Repibiki Tsekɛ',
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
 			'FK@alt=variant' => 'Bisanga bya Falklandí (Bisanga bya Maluni)',
 			'FM' => 'Mikronezi',
 			'FO' => 'Bisanga bya Faloé',
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
 			'HK' => 'Hong Kong (Shina)',
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
 			'JE' => 'Jelezy',
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
 			'MF' => 'Sántu Martin',
 			'MG' => 'Madagasikari',
 			'MH' => 'Bisanga bya Marishalɛ',
 			'MK' => 'Masedwanɛ',
 			'MK@alt=variant' => 'Masedoni (RYYYK)',
 			'ML' => 'Malí',
 			'MM' => 'Birmanie',
 			'MN' => 'Mongolí',
 			'MO' => 'Makau (Shina)',
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
 			'TL@alt=variant' => 'Timor ya Monyɛlɛ',
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
 			'UM' => 'Bisanga Mokɛ́na Mosíká bya Lisangá lya Ameríka',
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
			auxiliary => qr{[j q x]},
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', '{Gb}', 'H', 'I', 'K', 'L', 'M', '{Mb}', '{Mp}', 'N', '{Nd}', '{Ng}', '{Nk}', '{Ns}', '{Nt}', '{Ny}', '{Nz}', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a á â ǎ b c d e é ê ě ɛ {ɛ́} {ɛ̂} {ɛ̌} f g {gb} h i í î ǐ k l m {mb} {mp} n {nd} {ng} {nk} {ns} {nt} {ny} {nz} o ó ô ǒ ɔ {ɔ́} {ɔ̂} {ɔ̌} p r s t u ú v w y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
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
					'century' => {
						'name' => q(sekúlo),
						'one' => q({0} sekúlo),
						'other' => q({0} sekúlo),
					},
					'day' => {
						'name' => q(mikɔlɔ),
						'one' => q({0} mokɔlɔ),
						'other' => q({0} mikɔlɔ),
						'per' => q({0}/d),
					},
					'hour' => {
						'name' => q(ngonga),
						'one' => q({0} ngonga),
						'other' => q({0} ngonga),
						'per' => q({0}/h),
					},
					'microsecond' => {
						'name' => q(mikrosekundí),
						'one' => q({0} mikrosekundí),
						'other' => q({0} mikrosekundí),
					},
					'millisecond' => {
						'name' => q(millisekundí),
						'one' => q({0} millisekundí),
						'other' => q({0} millisekundí),
					},
					'minute' => {
						'name' => q(minúti),
						'one' => q({0} monúti),
						'other' => q({0} minúti),
						'per' => q({0}/monúti),
					},
					'month' => {
						'name' => q(sánzá),
						'one' => q({0} sánzá),
						'other' => q({0} sánzá),
						'per' => q({0}/sán),
					},
					'nanosecond' => {
						'name' => q(nanosekundí),
						'one' => q({0} nanosekundí),
						'other' => q({0} nanosekundí),
					},
					'second' => {
						'name' => q(sekundí),
						'one' => q({0} sekundí),
						'other' => q({0} sekundí),
					},
					'week' => {
						'name' => q(mpɔ́sɔ),
						'one' => q({0} mpɔ́sɔ),
						'other' => q({0} mpɔ́sɔ),
						'per' => q({0}/mps),
					},
					'year' => {
						'name' => q(mibú),
						'one' => q({0} mobú),
						'other' => q({0} mibú),
					},
				},
				'narrow' => {
					'day' => {
						'name' => q(mokɔlɔ),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					'hour' => {
						'name' => q(ngonga),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(sánzá),
						'one' => q({0} sán),
						'other' => q({0} sán),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'week' => {
						'name' => q(mps),
						'one' => q({0} mps),
						'other' => q({0} mps),
					},
				},
				'short' => {
					'century' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
					},
					'day' => {
						'name' => q(mikɔlɔ),
						'one' => q({0} mokɔlɔ),
						'other' => q({0} mikɔlɔ),
						'per' => q({0}/d),
					},
					'hour' => {
						'name' => q(ngonga),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(sánzá),
						'one' => q({0} sán),
						'other' => q({0} sán),
						'per' => q({0}/sán),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'week' => {
						'name' => q(mpɔ́sɔ),
						'one' => q({0} mps),
						'other' => q({0} mps),
						'per' => q({0}/mps),
					},
					'year' => {
						'name' => q(mibú),
					},
				},
			} }
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
					'default' => '#,##0.###',
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
		'ALL' => {
			display_name => {
				'currency' => q(Lek),
				'one' => q(Lek),
				'other' => q(Lek),
			},
		},
		'AOA' => {
			symbol => 'Kz',
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
			symbol => 'A$',
			display_name => {
				'currency' => q(Dolarɛ ya Ositali),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Guldeni y’ Aruba),
				'one' => q(Guldeni y’ Aruba),
				'other' => q(Guldeni y’ Aruba),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Mark ya kobóngwama),
				'one' => q(Mark ya kobóngwama),
				'other' => q(Mark ya kobóngwama),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolále ya Barbados),
				'one' => q(Dolále ya Barbados),
				'other' => q(Dolále ya Barbados),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev ya Bulgaria),
				'one' => q(Lev ya Bulgaria),
				'other' => q(Leva ya Bulgaria),
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
		'BSD' => {
			display_name => {
				'currency' => q(Dolále ya Bahamas),
				'one' => q(Dolále ya Bahamas),
				'other' => q(Dolále ya Bahamas),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ya Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rubelé ya Bielorusí),
				'one' => q(Rubelé ya Bielorusí),
				'other' => q(Rubelé ya Bielorusí),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rubelé ya Bielorusí \(2000–2016\)),
				'one' => q(Rubelé ya Bielorusí \(2000–2016\)),
				'other' => q(Rubelé ya Bielorusí \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dolále ya Belíze),
				'one' => q(Dolále ya Belíze),
				'other' => q(Dolále ya Belíze),
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
			symbol => 'Fr.',
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
			symbol => 'CZK',
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
			symbol => 'DKK',
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
			symbol => '€',
			display_name => {
				'currency' => q(Ɛlɔ́),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dolále ya Fiji),
				'one' => q(Dolále ya Fiji),
				'other' => q(Dolále ya Fiji),
			},
		},
		'GBP' => {
			symbol => '£',
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
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Bojito ya Gibraltar),
				'one' => q(Bojito ya Gibraltar),
				'other' => q(Bojito ya Gibraltar),
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
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal),
				'one' => q(Quetzal),
				'other' => q(Quetzal),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira),
				'one' => q(Lempira),
				'other' => q(Lempira),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna ya Kroasia),
				'one' => q(Kuna ya Kroasia),
				'other' => q(Kuna ya Kroasia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gurde),
				'one' => q(Gurde),
				'other' => q(Gurde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Folinte),
				'one' => q(Folinte),
				'other' => q(Folinte),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi ya Índɛ),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Motolé ya Islandi),
				'one' => q(Motolé ya Islandi),
				'other' => q(Motolé ya Islandi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolále ya Jamaïke),
				'one' => q(Dolále ya Jamaïke),
				'other' => q(Dolále ya Jamaïke),
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
		'KYD' => {
			display_name => {
				'currency' => q(Dolále ya Bisanga bya Kayman),
				'one' => q(Dolále ya Bisanga bya Kayman),
				'other' => q(Dolále ya Bisanga bya Kayman),
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
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denalé),
				'one' => q(Denalé),
				'other' => q(Denalé),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya ya Moritani \(1973–2017\)),
			},
		},
		'MRU' => {
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
		'MZN' => {
			display_name => {
				'currency' => q(Métikal),
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
			symbol => 'NOK',
			display_name => {
				'currency' => q(Motolé ya Norvej),
				'one' => q(Motolé ya Norvej),
				'other' => q(Motolé ya Norvej),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dolále ya Zeland ya Sika),
				'one' => q(Dolále ya Zeland ya Sika),
				'other' => q(Dolále ya Zeland ya Sika),
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
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina),
				'one' => q(Kina),
				'other' => q(Kina),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Sloty),
				'one' => q(Sloty),
				'other' => q(Sloty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani),
				'one' => q(Guarani),
				'other' => q(Guarani),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Sika),
				'one' => q(Leu Sika),
				'other' => q(Leu Sika),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinalé ya Serbia),
				'one' => q(Dinalé ya Serbia),
				'other' => q(Dinalé ya Serbia),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rubelé ya Rusí),
				'one' => q(Rubelé ya Rusí),
				'other' => q(Rubelé ya Rusí),
			},
		},
		'RWF' => {
			symbol => 'RF',
			display_name => {
				'currency' => q(Falánga ya Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyalɛ ya Alabi Sawuditɛ),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dolále ya Bisanga Solomoni),
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
			symbol => 'SEK',
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
		'SSP' => {
			display_name => {
				'currency' => q(Bojito ya Sudaní ya Súdi),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tomé mpé Presipe \(1977–2017\)),
			},
		},
		'STN' => {
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
		'TOP' => {
			symbol => 'T$',
			display_name => {
				'currency' => q(Pa’Anga),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolále ya Trinidad mpé Tobago),
				'one' => q(Dolále ya Trinidad mpé Tobago),
				'other' => q(Dolále ya Trinidad mpé Tobago),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilingɛ ya Tanzani),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Griwná),
				'one' => q(Griwná),
				'other' => q(Griwná),
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
		'VUV' => {
			display_name => {
				'currency' => q(Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Falánga CFA BEAC),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolále ya Kalibí Monyɛlɛ),
				'one' => q(Dolále ya Kalibí Monyɛlɛ),
				'other' => q(Dolále ya Kalibí Monyɛlɛ),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Falánga CFA BCEAO),
			},
		},
		'XPF' => {
			symbol => 'F CFP',
			display_name => {
				'currency' => q(Falánga CFP),
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Ngonga ya {0}),
		fallbackFormat => q({1} ({0})),
		'Africa_Central' => {
			long => {
				'standard' => q#Ntángo ya Lubumbashi#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ntángo ya Afríka ya Ɛ́sita#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ntángo ya Afríka ya Sidi#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ntángo ya Londoni#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ntángo ya Seyshel#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
