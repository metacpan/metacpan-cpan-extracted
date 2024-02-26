=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sg - Package for language Sango

=cut

package Locale::CLDR::Locales::Sg;
# This file auto generated from Data\common\main\sg.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
				'ak' => 'Akâan',
 				'am' => 'Amarîki',
 				'ar' => 'Arâbo',
 				'be' => 'Bielörûsi',
 				'bg' => 'Bulugäri',
 				'bn' => 'Bengäli',
 				'cs' => 'Tyêki',
 				'de' => 'Zâmani',
 				'el' => 'Gerêki',
 				'en' => 'Anglëe',
 				'es' => 'Espanyöl',
 				'fa' => 'Farsî',
 				'fr' => 'Farânzi',
 				'ha' => 'Haüsä',
 				'hi' => 'Hîndi',
 				'hu' => 'Hongruäa',
 				'id' => 'Enndonezïi',
 				'ig' => 'Ïgbö',
 				'it' => 'Ênnde',
 				'ja' => 'Zaponëe',
 				'jv' => 'Zavanëe',
 				'km' => 'Kmêre',
 				'ko' => 'Koreyëen',
 				'ms' => 'Malëe',
 				'my' => 'Miamära, Birimäni',
 				'ne' => 'Nepalëe',
 				'nl' => 'Holandëe',
 				'pa' => 'Penzäbï',
 				'pl' => 'Polonëe',
 				'pt' => 'Portugëe, Pûra',
 				'ro' => 'Rumëen',
 				'ru' => 'Rûsi',
 				'rw' => 'Ruandäa',
 				'sg' => 'Sängö',
 				'so' => 'Somalïi',
 				'sv' => 'Sueduäa',
 				'ta' => 'Tämûli',
 				'th' => 'Thâi',
 				'tr' => 'Tûrûku',
 				'uk' => 'Ukrêni',
 				'ur' => 'Ûrdu',
 				'vi' => 'Vietnäm',
 				'yo' => 'Yoruba',
 				'zh' => 'Shinuäa',
 				'zu' => 'Zûlu',

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
			'AD' => 'Andôro',
 			'AE' => 'Arâbo Emirâti Ôko',
 			'AF' => 'Faganïta, Afganïstäan',
 			'AG' => 'Antîgua na Barbûda',
 			'AI' => 'Angûîla',
 			'AL' => 'Albanïi',
 			'AM' => 'Armenïi',
 			'AO' => 'Angoläa',
 			'AR' => 'Arzantîna',
 			'AS' => 'Samöa tî Amerîka',
 			'AT' => 'Otrîsi',
 			'AU' => 'Ostralïi, Sotralïi',
 			'AW' => 'Arûba',
 			'AZ' => 'Zerebaidyäan, Azerbaidyäan,',
 			'BA' => 'Bosnïi na Herzegovînni',
 			'BB' => 'Barabâda',
 			'BD' => 'Bengladêshi',
 			'BE' => 'Bêleze, Belezîki',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulugarïi',
 			'BH' => 'Bahrâina',
 			'BI' => 'Burundïi',
 			'BJ' => 'Benëen',
 			'BM' => 'Beremûda',
 			'BN' => 'Brunêi',
 			'BO' => 'Bolivïi',
 			'BR' => 'Brezîli',
 			'BS' => 'Bahâmasa',
 			'BT' => 'Butäan',
 			'BW' => 'Botswana',
 			'BY' => 'Belarüsi',
 			'BZ' => 'Belîzi',
 			'CA' => 'Kanadäa',
 			'CD' => 'Ködörösêse tî Ngunuhalëzo tî kongö',
 			'CF' => 'Ködörösêse tî Bêafrîka',
 			'CG' => 'Kongö',
 			'CH' => 'Sûîsi',
 			'CI' => 'Kôdivüära',
 			'CK' => 'âzûâ Kûku',
 			'CL' => 'Shilïi',
 			'CM' => 'Kamerûne',
 			'CN' => 'Shîna',
 			'CO' => 'Kolombïi',
 			'CR' => 'Kôsta Rîka',
 			'CU' => 'Kubäa',
 			'CV' => 'Azûâ tî Kâpo-Vêre',
 			'CY' => 'Sîpri',
 			'CZ' => 'Ködörösêse tî Tyêki',
 			'DE' => 'Zâmani',
 			'DJ' => 'Dibutùii',
 			'DK' => 'Danemêrke',
 			'DM' => 'Dömïnîka',
 			'DO' => 'Ködörösêse tî Dominîka',
 			'DZ' => 'Alzerïi',
 			'EC' => 'Ekuatëre',
 			'EE' => 'Estonïi',
 			'EG' => 'Kâmitâ',
 			'ER' => 'Eritrëe',
 			'ES' => 'Espânye',
 			'ET' => 'Etiopïi',
 			'FI' => 'Fëlânde',
 			'FJ' => 'Fidyïi',
 			'FK' => 'Âzûâ tî Mälüîni',
 			'FM' => 'Mikronezïi',
 			'FR' => 'Farânzi',
 			'GA' => 'Gaböon',
 			'GB' => 'Ködörögbïä--Ôko',
 			'GD' => 'Grenâda',
 			'GE' => 'Zorzïi',
 			'GF' => 'Güyâni tî farânzi',
 			'GH' => 'Ganäa',
 			'GI' => 'Zibraltära, Zibaratära',
 			'GL' => 'Gorolânde',
 			'GM' => 'Gambïi',
 			'GN' => 'Ginëe',
 			'GP' => 'Guadelûpu',
 			'GQ' => 'Ginëe tî Ekuatëre',
 			'GR' => 'Gerêsi',
 			'GT' => 'Guatêmälä',
 			'GU' => 'Guâm',
 			'GW' => 'Gninëe-Bisau',
 			'GY' => 'Gayâna',
 			'HN' => 'Honduräsi',
 			'HR' => 'Kroasïi',
 			'HT' => 'Haitïi',
 			'HU' => 'Hongirùii',
 			'ID' => 'Ênndonezïi',
 			'IE' => 'Irlânde',
 			'IL' => 'Israëli',
 			'IN' => 'Ênnde',
 			'IO' => 'Sêse tî Anglëe na Ngûyämä tî Ênnde',
 			'IQ' => 'Irâki',
 			'IR' => 'Iräan',
 			'IS' => 'Islânde',
 			'IT' => 'Italùii',
 			'JM' => 'Zamaîka',
 			'JO' => 'Zordanïi',
 			'JP' => 'Zapöon',
 			'KE' => 'Kenyäa',
 			'KG' => 'Kirigizitùaan',
 			'KH' => 'Kämbôzi',
 			'KI' => 'Kiribati',
 			'KM' => 'Kömôro',
 			'KN' => 'Sên-Krïstôfo-na-Nevîsi',
 			'KP' => 'Korëe tî Banga',
 			'KR' => 'Korëe tî Mbongo',
 			'KW' => 'Köwêti',
 			'KY' => 'Âzûâ Ngundë, Kaimäni',
 			'KZ' => 'Kazakisitäan',
 			'LA' => 'Lùaôsi',
 			'LB' => 'Libùaan',
 			'LC' => 'Sênt-Lisïi',
 			'LI' => 'Liechtenstein,',
 			'LK' => 'Sirî-Lanka',
 			'LR' => 'Liberïa',
 			'LS' => 'Lesôtho',
 			'LT' => 'Lituanïi',
 			'LU' => 'Lugzambûru',
 			'LV' => 'Letonùii',
 			'LY' => 'Libïi',
 			'MA' => 'Marôko',
 			'MC' => 'Monaköo',
 			'MD' => 'Moldavùii',
 			'MG' => 'Madagaskära',
 			'MH' => 'Âzûâ Märshâl',
 			'ML' => 'Malïi',
 			'MM' => 'Myämâra',
 			'MN' => 'Mongolïi',
 			'MP' => 'Âzûâ Märïâni tî Banga',
 			'MQ' => 'Märtïnîki',
 			'MR' => 'Moritanïi',
 			'MS' => 'Monserâte',
 			'MT' => 'Mâlta',
 			'MU' => 'Mörîsi',
 			'MV' => 'Maldîva',
 			'MW' => 'Malawïi',
 			'MX' => 'Mekisîki',
 			'MY' => 'Malezïi',
 			'MZ' => 'Mözämbîka',
 			'NA' => 'Namibùii',
 			'NC' => 'Finî Kaledonïi',
 			'NE' => 'Nizëre',
 			'NF' => 'Zûâ Nôrfôlko',
 			'NG' => 'Nizerïa',
 			'NI' => 'Nikaragua',
 			'NL' => 'Holände',
 			'NO' => 'Nörvêzi',
 			'NP' => 'Nëpâli',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Finî Zelânde',
 			'OM' => 'Omâni',
 			'PA' => 'Panama',
 			'PE' => 'Perüu',
 			'PF' => 'Polinezïi tî farânzi',
 			'PG' => 'Papû Finî Ginëe, Papuazïi',
 			'PH' => 'Filipîni',
 			'PK' => 'Pakistäan',
 			'PL' => 'Pölôni',
 			'PM' => 'Sên-Pyêre na Mikelöon',
 			'PN' => 'Pitikêrni',
 			'PR' => 'Porto Rîko',
 			'PS' => 'Sêse tî Palestîni',
 			'PT' => 'Pörtugäle, Ködörö Pûra',
 			'PW' => 'Palau',
 			'PY' => 'Paraguëe',
 			'QA' => 'Katära',
 			'RE' => 'Reinïon',
 			'RO' => 'Rumanïi',
 			'RU' => 'Rusïi',
 			'RW' => 'Ruandäa',
 			'SA' => 'Saûdi Arabïi',
 			'SB' => 'Zûâ Salomöon',
 			'SC' => 'Sëyshêle',
 			'SD' => 'Sudäan',
 			'SE' => 'Suêde',
 			'SG' => 'Sïngäpûru',
 			'SH' => 'Sênt-Helêna',
 			'SI' => 'Solovenïi',
 			'SK' => 'Solovakïi',
 			'SL' => 'Sierä-Leône',
 			'SM' => 'Sên-Marëen',
 			'SN' => 'Senegäle',
 			'SO' => 'Somalïi',
 			'SR' => 'Surinäm',
 			'SS' => 'Sudäan-Mbongo',
 			'ST' => 'Sâô Tömê na Prinsîpe',
 			'SV' => 'Salvadöro',
 			'SY' => 'Sirïi',
 			'SZ' => 'Swäzïlânde',
 			'TC' => 'Âzûâ Turku na Kaîki',
 			'TD' => 'Tyâde',
 			'TG' => 'Togö',
 			'TH' => 'Tailânde',
 			'TJ' => 'Taazikiistäan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timôro tî Tö',
 			'TM' => 'Turkumenistäan',
 			'TN' => 'Tunizïi',
 			'TO' => 'Tonga',
 			'TR' => 'Turukïi',
 			'TT' => 'Trinitùee na Tobagö',
 			'TV' => 'Tüvalü',
 			'TW' => 'Tâiwâni',
 			'TZ' => 'Tanzanïi',
 			'UA' => 'Ukrêni',
 			'UG' => 'Ugandäa',
 			'US' => 'ÂLeaa-Ôko tî Amerika',
 			'UY' => 'Uruguëe',
 			'UZ' => 'Uzbekistäan',
 			'VA' => 'Letëe tî Vatikäan',
 			'VC' => 'Sên-Vensäan na âGrenadîni',
 			'VE' => 'Venezueläa',
 			'VG' => 'Âzôâ Viîrîggo tî Anglëe',
 			'VI' => 'Âzûâ Virîgo tî Amerîka',
 			'VN' => 'Vietnäm',
 			'VU' => 'Vanuatü',
 			'WF' => 'Walîsi na Futuna',
 			'WS' => 'Samoäa',
 			'YE' => 'Yëmêni',
 			'YT' => 'Mäyôte',
 			'ZA' => 'Mbongo-Afrîka',
 			'ZM' => 'Zambïi',
 			'ZW' => 'Zimbäbwe',

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
			auxiliary => qr{[c q x]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[aâä b d eêë f g h iîï j k l m n oôö p r s t uùûü v w y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Iin|I|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Én-en|E|no|n)$' }
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

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'negative' => '¤-#,##0.00',
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
				'currency' => q(dirâm tî âEmirâti tî Arâbo Ôko),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwânza tî Angoläa),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dolära tî Ostralïi),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dolùara tî Bahrâina),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(farânga tî Burundïi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pûla tî Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dolära tî kanadäa),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(farânga tî Kongöo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(farânga tî Sûîsi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan renminbi tî Shîni),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(eskûêdo tî Kâpo-Vêre),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(farânga tî Dibutïi),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinäri tî Alzerïi),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(pôndo tî Kâmitâ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakafa tî Eritrëe),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(bir tî Etiopïi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(zoröo),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(pôndo tî Anglëe),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(sêdi tî Ganäa),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi tî gambïi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(sili tî Ginëe),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupïi tî Ênnde),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yêni tî Zapön),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(shilîngi tî Kenyäa),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(farânga tî Kömôro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dolära tî Liberïa),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti tî Lesôtho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinäar tî Libïi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirâm tî Marôko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariâri tî Madagasikära),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ugîya tî Moritanïi \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ugîya tî Moritanïi),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupïi tî Mörîsi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwâtia tî Malawïi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metikala tî Mozambîka),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dolära tî Namibïi),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nâîra tî Nizerïa),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(farânga tî Ruandäa),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riâli tî Saûdi Arabïi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupïi tî Sëyshêle),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(pôndo tî Sudäan),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(pôndo tî Zûâ Sênt-Helêna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leône tî Sierâ-Leône),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leône tî Sierâ-Leône \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(shilîngi tî Somalïi),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dôbra tî Sâô Tomë na Prinsîpe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dôbra tî Sâô Tomë na Prinsîpe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangùeni tî Swazïlânde),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinära tî Tunizïi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(shilîngi tî Tanzanïi),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(shilîngi tî Ugandäa),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dol$ara ttî äLetäa-Ôko tî Amerîka),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(farânga CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(farânga CFA \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rânde tî Mbongo-Afrîka),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwâtia tî Zambïi \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwâtia tî Zambïi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dolära tî Zimbäbwe),
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
							'Nye',
							'Ful',
							'Mbä',
							'Ngu',
							'Bêl',
							'Fön',
							'Len',
							'Kük',
							'Mvu',
							'Ngb',
							'Nab',
							'Kak'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Nyenye',
							'Fulundïgi',
							'Mbängü',
							'Ngubùe',
							'Bêläwü',
							'Föndo',
							'Lengua',
							'Kükürü',
							'Mvuka',
							'Ngberere',
							'Nabändüru',
							'Kakauka'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'N',
							'F',
							'M',
							'N',
							'B',
							'F',
							'L',
							'K',
							'M',
							'N',
							'N',
							'K'
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
						mon => 'Bk2',
						tue => 'Bk3',
						wed => 'Bk4',
						thu => 'Bk5',
						fri => 'Lâp',
						sat => 'Lây',
						sun => 'Bk1'
					},
					wide => {
						mon => 'Bïkua-ûse',
						tue => 'Bïkua-ptâ',
						wed => 'Bïkua-usïö',
						thu => 'Bïkua-okü',
						fri => 'Lâpôsö',
						sat => 'Lâyenga',
						sun => 'Bikua-ôko'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'S',
						thu => 'K',
						fri => 'P',
						sat => 'Y',
						sun => 'K'
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
					abbreviated => {0 => 'F4–1',
						1 => 'F4–2',
						2 => 'F4–3',
						3 => 'F4–4'
					},
					wide => {0 => 'Fângbisïö ôko',
						1 => 'Fângbisïö ûse',
						2 => 'Fângbisïö otâ',
						3 => 'Fângbisïö usïö'
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
					'am' => q{ND},
					'pm' => q{LK},
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
				'0' => 'KnK',
				'1' => 'NpK'
			},
			wide => {
				'0' => 'Kôzo na Krîstu',
				'1' => 'Na pekô tî Krîstu'
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
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM, y},
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
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
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
