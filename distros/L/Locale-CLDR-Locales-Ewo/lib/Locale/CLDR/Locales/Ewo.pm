=head1

Locale::CLDR::Locales::Ewo - Package for language Ewondo

=cut

package Locale::CLDR::Locales::Ewo;
# This file auto generated from Data\common\main\ewo.xml
#	on Fri 13 Apr  7:09:13 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
				'ak' => 'Ǹkɔ́bɔ akán',
 				'am' => 'Ǹkɔ́bɔ amária',
 				'ar' => 'Ǹkɔ́bɔ arábia',
 				'be' => 'Ǹkɔ́bɔ belarúsian',
 				'bg' => 'Ǹkɔ́bɔ buləgárian',
 				'bn' => 'Ǹkɔ́bɔ bɛngalí',
 				'cs' => 'Ǹkɔ́bɔ tsɛ́g',
 				'de' => 'Ǹkɔ́bɔ ndzáman',
 				'el' => 'Ǹkɔ́bɔ gəlɛ́g',
 				'en' => 'Ǹkɔ́bɔ éngəlís',
 				'es' => 'ǹkɔ́bɔ kpənyá',
 				'ewo' => 'ewondo',
 				'fa' => 'ǹkɔ́bɔ fɛ́rəsian',
 				'fr' => 'Ǹkɔ́bɔ fulɛnsí',
 				'ha' => 'Ǹkɔ́bɔ aúsá',
 				'hi' => 'Ǹkɔ́bɔ hindí',
 				'hu' => 'Ǹkɔ́bɔ ungárían',
 				'id' => 'Ǹkɔ́bɔ ɛndonésian',
 				'ig' => 'Ǹkɔ́bɔ ibó',
 				'it' => 'Ǹkɔ́bɔ etáliɛn',
 				'ja' => 'Ǹkɔ́bɔ hapɔ́n',
 				'jv' => 'Ǹkɔ́bɔ havanís',
 				'km' => 'Ǹkɔ́bɔ kəmɛ́r',
 				'ko' => 'Ǹkɔ́bɔ koréan',
 				'ms' => 'Ǹkɔ́bɔ malɛ́sian',
 				'my' => 'Ǹkɔ́bɔ birəmán',
 				'ne' => 'ǹkɔ́bɔ nefálian',
 				'nl' => 'Ǹkɔ́bɔ nɛrəlándía',
 				'pa' => 'ǹkɔ́bɔ funəhábia',
 				'pl' => 'ǹkɔ́bɔ fólis',
 				'pt' => 'ǹkɔ́bɔ fɔtugɛ́s',
 				'ro' => 'ńkɔ́bɔ románía',
 				'ru' => 'ǹkɔ́bɔ rúsian',
 				'rw' => 'ǹkɔ́bɔ ruwandá',
 				'so' => 'ǹkɔ́bɔ somália',
 				'sv' => 'ǹkɔ́bɔ suwɛ́d',
 				'ta' => 'ǹkɔ́bɔ tamíl',
 				'th' => 'ǹkɔ́bɔ táilan',
 				'tr' => 'ǹkɔ́bɔ túrəki',
 				'uk' => 'ǹkɔ́bɔ ukelénia',
 				'ur' => 'ǹkɔ́bɔ urudú',
 				'vi' => 'ǹkɔ́bɔ hiɛdənám',
 				'yo' => 'ǹkɔ́bɔ yorúba',
 				'zh' => 'Ǹkɔ́bɔ tsainís',
 				'zu' => 'ǹkɔ́bɔ zulú',

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
			'AD' => 'Andór',
 			'AE' => 'Bemirá yá Arábə uní',
 			'AF' => 'Afəganisətán',
 			'AG' => 'Antígwa ai Barəbúda',
 			'AI' => 'Angíyə',
 			'AL' => 'Aləbánia',
 			'AM' => 'Arəménia',
 			'AO' => 'Angolá',
 			'AR' => 'Arəhenətína',
 			'AS' => 'Bəsamóa yá Amə́rəka',
 			'AT' => 'Osətəlía',
 			'AU' => 'Osətəlalí',
 			'AW' => 'Arúba',
 			'AZ' => 'Azɛrəbaidzáŋ',
 			'BA' => 'Bosəní ai ɛrəzegovín',
 			'BB' => 'Barəbád',
 			'BD' => 'Bangaladɛ́s',
 			'BE' => 'Bɛləhíg',
 			'BF' => 'Buləkiná Fasó',
 			'BG' => 'Buləgarí',
 			'BH' => 'Bahərɛ́n',
 			'BI' => 'Burundí',
 			'BJ' => 'Bəníŋ',
 			'BM' => 'Bɛrəmúd',
 			'BN' => 'Buluné',
 			'BO' => 'Bolívia',
 			'BR' => 'Bəlazíl',
 			'BS' => 'Bahámas',
 			'BT' => 'Butáŋ',
 			'BW' => 'Botswaná',
 			'BY' => 'Bəlarús',
 			'BZ' => 'Bəlís',
 			'CA' => 'kanadá',
 			'CD' => 'ǹnam Kongó Demokəlatíg',
 			'CF' => 'ǹnam Zǎŋ Afiriká',
 			'CG' => 'Kongó',
 			'CH' => 'Suís',
 			'CI' => 'Kód Divɔ́r',
 			'CK' => 'Minlán Mí kúg',
 			'CL' => 'Tsilí',
 			'CM' => 'Kamərún',
 			'CN' => 'Tsáina',
 			'CO' => 'Kolɔmbí',
 			'CR' => 'Kosta Ríka',
 			'CU' => 'Kubá',
 			'CV' => 'Minlán Mí Káb Vɛr',
 			'CY' => 'Sipəlús',
 			'CZ' => 'Ǹnam Tsɛ́g',
 			'DE' => 'Ndzáman',
 			'DJ' => 'Dzibutí',
 			'DK' => 'Danəmárəg',
 			'DM' => 'Dómənika',
 			'DO' => 'République dominicaine',
 			'DZ' => 'Aləyéria',
 			'EC' => 'Ekwatór',
 			'EE' => 'Esetoní',
 			'EG' => 'Ehíbətɛn',
 			'ER' => 'Elitəlé',
 			'ES' => 'Kpənyá',
 			'ET' => 'Etiopí',
 			'FI' => 'Finəlán',
 			'FJ' => 'Fidzí',
 			'FK' => 'Minlán Mi Fóləkəlan',
 			'FM' => 'Mikoronésia',
 			'FR' => 'Fulɛnsí',
 			'GA' => 'Gabóŋ',
 			'GB' => 'Ǹnam Engəlis',
 			'GD' => 'Gələnádə',
 			'GE' => 'Horə́yia',
 			'GF' => 'Guyán yá Fulɛnsí',
 			'GH' => 'Ganá',
 			'GI' => 'Yiləbalatár',
 			'GL' => 'Goelán',
 			'GM' => 'Gambí',
 			'GN' => 'Giné',
 			'GP' => 'Guadəlúb',
 			'GQ' => 'Giné Ekwató',
 			'GR' => 'Gəlɛ́s',
 			'GT' => 'Guatemalá',
 			'GU' => 'Guám',
 			'GW' => 'Giné Bisaó',
 			'GY' => 'Guyán',
 			'HN' => 'Ondurás',
 			'HR' => 'Kəlowásia',
 			'HT' => 'Aití',
 			'HU' => 'Ongirí',
 			'ID' => 'ɛndonésia',
 			'IE' => 'Irəlándə',
 			'IL' => 'Isəraɛ́l',
 			'IN' => 'ɛ́ndə',
 			'IO' => 'ǹnam ɛngəlís yá Máŋ mə́ ɛ́ndə',
 			'IQ' => 'Irág',
 			'IR' => 'Irán',
 			'IS' => 'Isəlándə',
 			'IT' => 'Itáliɛn',
 			'JM' => 'Hamaíka',
 			'JO' => 'Horədaní',
 			'JP' => 'Hapɔ́n',
 			'KE' => 'Keniá',
 			'KG' => 'Kirigisətán',
 			'KH' => 'kambodía',
 			'KI' => 'Kiribatí',
 			'KM' => 'Komɔ́r',
 			'KN' => 'Ǹfúfúb-Kilisətóv-ai-Nevis',
 			'KP' => 'Koré yá Nór',
 			'KR' => 'Koré yá Súd',
 			'KW' => 'Kowɛ́d',
 			'KY' => 'Minlán Mí Kalimáŋ',
 			'KZ' => 'Kazakətáŋ',
 			'LA' => 'Laós',
 			'LB' => 'Libáŋ',
 			'LC' => 'Ǹfúfúb-Lúsia',
 			'LI' => 'Lísə́sə́táin',
 			'LK' => 'Səri Laŋká',
 			'LR' => 'Libéria',
 			'LS' => 'Ləsotó',
 			'LT' => 'Lituaní',
 			'LU' => 'Lukəzambúd',
 			'LV' => 'Lətoní',
 			'LY' => 'Libí',
 			'MA' => 'Marɔ́g',
 			'MC' => 'Mɔnakó',
 			'MD' => 'Molədaví',
 			'MG' => 'Madagasəkárə',
 			'MH' => 'Minlán Mí Maresál',
 			'MK' => 'Masedónia',
 			'ML' => 'Malí',
 			'MM' => 'Mianəmár',
 			'MN' => 'Mɔngɔ́lia',
 			'MP' => 'Minlán Mi Marián yá Nór',
 			'MQ' => 'Marətiníg',
 			'MR' => 'Moritaní',
 			'MS' => 'Mɔ́ntserád',
 			'MT' => 'Málətə',
 			'MU' => 'Morís',
 			'MV' => 'Malədívə',
 			'MW' => 'Malawí',
 			'MX' => 'Mɛkəsíg',
 			'MY' => 'Malɛ́zia',
 			'MZ' => 'Mozambíg',
 			'NA' => 'Namibí',
 			'NC' => 'Ǹkpámɛn Kaledónia',
 			'NE' => 'Nihɛ́r',
 			'NF' => 'Minlán Nɔrəfɔ́ləkə',
 			'NG' => 'Nihéria',
 			'NI' => 'Nikarágua',
 			'NL' => 'Pɛíbá',
 			'NO' => 'Nɔrəvɛ́s',
 			'NP' => 'Nepál',
 			'NR' => 'Naurú',
 			'NU' => 'Niué',
 			'NZ' => 'Ǹkpámɛn Zeláŋ',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesí yá Fulɛnsí',
 			'PG' => 'Papwazi yá Ǹkpámɛ́n Giné',
 			'PH' => 'Filipín',
 			'PK' => 'Pakisətán',
 			'PL' => 'fólis',
 			'PM' => 'Ǹfúfúb-Píɛr-ai-Mikəlɔ́ŋ',
 			'PN' => 'Pítə́kɛ́rɛnə',
 			'PR' => 'Pwɛrəto Ríko',
 			'PS' => 'Ǹnam Palɛsətín',
 			'PT' => 'fɔrətugɛ́s',
 			'PW' => 'Palau',
 			'PY' => 'Paragué',
 			'QA' => 'Katár',
 			'RE' => 'Reuniɔ́ŋ',
 			'RO' => 'Rumaní',
 			'RU' => 'Rúsian',
 			'RW' => 'Ruwandá',
 			'SA' => 'Arabí Saudí',
 			'SB' => 'Minlán Mí Solomɔ́n',
 			'SC' => 'Sɛsɛ́l',
 			'SD' => 'Sudáŋ',
 			'SE' => 'Suwɛ́d',
 			'SG' => 'Singapúr',
 			'SH' => 'Ǹfúfúb-Ɛlɛ́na',
 			'SI' => 'Səlovénia',
 			'SK' => 'Səlovakí',
 			'SL' => 'Sierá-leónə',
 			'SM' => 'Ǹfúfúb Maríno',
 			'SN' => 'Senegál',
 			'SO' => 'Somália',
 			'SR' => 'Surinám',
 			'ST' => 'Saó Tomé ai Pəlinəsípe',
 			'SV' => 'Saləvadór',
 			'SY' => 'Sirí',
 			'SZ' => 'Swazilándə',
 			'TC' => 'Minlán Mí túrə́g-ai-Kaíg',
 			'TD' => 'Tsád',
 			'TG' => 'Togó',
 			'TH' => 'Tailán',
 			'TJ' => 'Tadzikisətáŋ',
 			'TK' => 'Tokeló',
 			'TL' => 'Timôr',
 			'TM' => 'Turəkəmənisətáŋ',
 			'TN' => 'Tunisí',
 			'TO' => 'Tɔngá',
 			'TR' => 'Turəkí',
 			'TT' => 'Təlinité-ai-Tobágo',
 			'TV' => 'Tuvalú',
 			'TW' => 'Taiwán',
 			'TZ' => 'Taŋəzaní',
 			'UA' => 'Ukərɛ́n',
 			'UG' => 'Ugandá',
 			'US' => 'Ǹnam Amɛrəkə',
 			'UY' => 'Urugué',
 			'UZ' => 'Uzubekisətán',
 			'VA' => 'Ǹnam Vatikán',
 			'VC' => 'Ǹfúfúb-Vɛngəsáŋ-ai-Bə Gələnadín',
 			'VE' => 'Venezuéla',
 			'VG' => 'ńnam Minlán ɛ́ngəlís',
 			'VI' => 'Minlán Mi Amɛrəkə',
 			'VN' => 'Viɛdənám',
 			'VU' => 'Vanuátu',
 			'WF' => 'Walís-ai-Futúna',
 			'WS' => 'Samoá',
 			'YE' => 'Yemɛ́n',
 			'YT' => 'Mayɔ́d',
 			'ZA' => 'Afiríka yá Súd',
 			'ZM' => 'Zambí',
 			'ZW' => 'Zimbabwé',

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
			auxiliary => qr{[c j q x]},
			index => ['A', 'B', 'D', 'E', 'Ə', 'Ɛ', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a á à â ǎ b d {dz} e é è ê ě ə {ə́} {ə̀} {ə̂} {ə̌} ɛ {ɛ́} {ɛ̀} {ɛ̂} {ɛ̌} f g h i í ì î ǐ k {kp} l m n ń ǹ {ng} {nk} ŋ o ó ò ô ǒ ɔ {ɔ́} {ɔ̀} {ɔ̂} {ɔ̌} p r s t {ts} u ú ù û ǔ v w y z]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'Ə', 'Ɛ', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Owé|O|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Tɛgɛ|T|no|n)$' }
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
				'currency' => q(Dirám yá Emirá Aráb Uní),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwánəza yá Angolá),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolár yá Osətəralí),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinár yá Bahərɛ́n),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Fəláŋ yá Burundí),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Púlá yá Botswána),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolár yá Kanáda),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Fəláŋ yá Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Fəláŋ yá Suís),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuán Renəminəbí yá Tsainís),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esəkúdo yá Kápə́vɛ́rə),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Fəláŋ yá dzibutí),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinár yá Alehérí),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Lívə́lə yá Ehíbətía),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Náfəka yá Eritelé),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bír yá Etsiópia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(əró),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Lívə́lə Sətərəlíŋ),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Tzedí yá Ganá),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasí yá Gámbía),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Síli yá Giné),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupí yá ɛ́ndía),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yɛ́n yá Hapɔ́n),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Silíŋ yá Keniá),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Fəláŋ yá Komória),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolár yá Libéria),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lotí yá Lesotó),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinár yá Libí),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirám yá Maróg),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariari yá Maləgás),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugiya yá Moritaní),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupí yá Morís),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwatsa yá Malawí),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikal yá Mozambíg),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolár yá Namibí),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Náíra yá Nihéria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Fəláŋ yá Ruwandá),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riál yá Arabí Saudí),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupí yá Sɛsɛ́l),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Lívələ yá Sudán),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Lívələ yá Sudán \(1956–2007\)),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Lívələ yá Ǹfúfúb Elɛ́n),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leóne yá Sierá-leónə),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Silíŋ yá Somalí),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dóbə́ra yá Saó Tomé ai Pəlinəsípe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni yá Swazí),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinár yá Tunisí),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Silíŋ yá Tanazaní),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Silíŋ yá Ugandá \(1966–1987\)),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolár yá amɛ́rəkə),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Fəláŋ CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Fəláŋ CFA \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ránədə yá Afiríka),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwatsa yá Zambí \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwatsa yá Zambí),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dolár yá Zimbabwé),
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
							'ngo',
							'ngb',
							'ngl',
							'ngn',
							'ngt',
							'ngs',
							'ngz',
							'ngm',
							'nge',
							'nga',
							'ngad',
							'ngab'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ngɔn osú',
							'ngɔn bɛ̌',
							'ngɔn lála',
							'ngɔn nyina',
							'ngɔn tána',
							'ngɔn saməna',
							'ngɔn zamgbála',
							'ngɔn mwom',
							'ngɔn ebulú',
							'ngɔn awóm',
							'ngɔn awóm ai dziá',
							'ngɔn awóm ai bɛ̌'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'o',
							'b',
							'l',
							'n',
							't',
							's',
							'z',
							'm',
							'e',
							'a',
							'd',
							'b'
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
						fri => 'fúl',
						sat => 'sér',
						sun => 'sɔ́n'
					},
					wide => {
						mon => 'mɔ́ndi',
						tue => 'sɔ́ndɔ məlú mə́bɛ̌',
						wed => 'sɔ́ndɔ məlú mə́lɛ́',
						thu => 'sɔ́ndɔ məlú mə́nyi',
						fri => 'fúladé',
						sat => 'séradé',
						sun => 'sɔ́ndɔ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'm',
						tue => 's',
						wed => 's',
						thu => 's',
						fri => 'f',
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
					abbreviated => {0 => 'nno',
						1 => 'nnb',
						2 => 'nnl',
						3 => 'nnny'
					},
					wide => {0 => 'nsámbá ngɔn asú',
						1 => 'nsámbá ngɔn bɛ̌',
						2 => 'nsámbá ngɔn lála',
						3 => 'nsámbá ngɔn nyina'
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
				'wide' => {
					'pm' => q{ngəgógəle},
					'am' => q{kíkíríg},
				},
				'abbreviated' => {
					'am' => q{kíkíríg},
					'pm' => q{ngəgógəle},
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
				'0' => 'oyk',
				'1' => 'ayk'
			},
			wide => {
				'0' => 'osúsúa Yésus kiri',
				'1' => 'ámvus Yésus Kirís'
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
			Ed => q{d E},
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
			Ed => q{d E},
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
