=head1

Locale::CLDR::Locales::Bas - Package for language Basaa

=cut

package Locale::CLDR::Locales::Bas;
# This file auto generated from Data\common\main\bas.xml
#	on Fri 29 Apr  6:52:01 pm GMT

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
				'ak' => 'Hɔp u akan',
 				'am' => 'Hɔp u amhārìk',
 				'ar' => 'Hɔp u arâb',
 				'bas' => 'Ɓàsàa',
 				'be' => 'Hɔp u bièlòrûs',
 				'bg' => 'Hɔp u bûlgâr',
 				'bn' => 'Hɔp u bɛŋgàli',
 				'cs' => 'Hɔp u cɛ̂k',
 				'de' => 'Hɔp u jamân',
 				'el' => 'Hɔp u gri ᷇kyà',
 				'en' => 'Hɔp u ŋgisì',
 				'es' => 'Hɔp u panyā',
 				'fa' => 'Hɔp u pɛrsìà',
 				'fr' => 'Hɔp u pulàsi',
 				'ha' => 'Hɔp u ɓausa',
 				'hi' => 'Hɔp u hindì',
 				'hu' => 'Hɔp u hɔŋgrìi',
 				'id' => 'Hɔp u indònesìà',
 				'ig' => 'Hɔp u iɓò',
 				'it' => 'Hɔp u italìà',
 				'ja' => 'Hɔp u yapàn',
 				'jv' => 'Hɔp u yavà',
 				'km' => 'Hɔp u kmɛ̂r',
 				'ko' => 'Hɔp u kɔrēà',
 				'ms' => 'Hɔp u makɛ᷆',
 				'my' => 'Hɔp u birmàn',
 				'ne' => 'Hɔp u nepa᷆l',
 				'nl' => 'Hɔp u nlɛ̀ndi',
 				'pa' => 'Hɔp u pɛnjàbi',
 				'pl' => 'Hɔp u pɔlɔ̄nà',
 				'pt' => 'Hɔp u pɔtɔ̄kì',
 				'ro' => 'Hɔp u rùmanìà',
 				'ru' => 'Hɔp u ruslànd',
 				'rw' => 'Hɔp u ruāndà',
 				'so' => 'Hɔp u somàlî',
 				'sv' => 'Hɔp u suɛ᷆d',
 				'ta' => 'Hɔp u tamu᷆l',
 				'th' => 'Hɔp u tây',
 				'tr' => 'Hɔp u tûrk',
 				'uk' => 'Hɔp u ukrǎnìà',
 				'ur' => 'Hɔp u urdù',
 				'vi' => 'Hɔp u vyɛ̄dnàm',
 				'yo' => 'Hɔp u yorūbà',
 				'zh' => 'Hɔp u kinà',
 				'zu' => 'Hɔp u zulù',

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
			'AD' => 'Àŋdɔ̂r',
 			'AE' => 'Àdnà i Bilɔ̀ŋ bi Arābìà',
 			'AF' => 'Àfgànìstâŋ',
 			'AG' => 'Àŋtigà ɓɔ Bàrbudà',
 			'AI' => 'Àŋgiyà',
 			'AL' => 'Àlbanìà',
 			'AM' => 'Àrmenìà',
 			'AO' => 'Àŋgolà',
 			'AR' => 'Àrgàŋtinà',
 			'AT' => 'Òstrǐk',
 			'AU' => 'Òstralìà',
 			'AW' => 'Àrubà',
 			'AZ' => 'Àzɛ̀rbajàŋ',
 			'BA' => 'Bòhnià Ɛrzègòvinà',
 			'BB' => 'Bàrbadò',
 			'BD' => 'Bàŋglàdɛ̂s',
 			'BE' => 'Bɛlgyùm',
 			'BF' => 'Bùrkìnà Fasò',
 			'BG' => 'Bùlgarìà',
 			'BH' => 'Bàraìn',
 			'BI' => 'Bùrundì',
 			'BJ' => 'Bènɛ̂ŋ',
 			'BM' => 'Bɛ̀rmudà',
 			'BN' => 'Brunei',
 			'BO' => 'Bòlivìà',
 			'BR' => 'Bràsîl',
 			'BS' => 'Bàhamàs',
 			'BT' => 'Bùtân',
 			'BW' => 'Bòdsùanà',
 			'BY' => 'Bèlarùs',
 			'BZ' => 'Bèlîs',
 			'CA' => 'Kànadà',
 			'CD' => 'Kòŋgo ìkɛŋi',
 			'CF' => 'Ŋ̀ɛm Afrīkà',
 			'CG' => 'Kòŋgo',
 			'CH' => 'Sùwîs',
 			'CI' => 'Màŋ mi Njɔ̂k',
 			'CK' => 'Bìòn bi Kook',
 			'CL' => 'Kìlî',
 			'CM' => 'Kàmɛ̀rûn',
 			'CN' => 'Kinà',
 			'CO' => 'Kɔ̀lɔmbìà',
 			'CR' => 'Kòstà Rikà',
 			'CU' => 'Kubà',
 			'CV' => 'Kabwɛ᷆r',
 			'CY' => 'Kiprò',
 			'DE' => 'Jamân',
 			'DJ' => 'Jìbutì',
 			'DK' => 'Dànmârk',
 			'DM' => 'Dòmnîk',
 			'DO' => 'Dòmnikà',
 			'DZ' => 'Àlgerìà',
 			'EC' => 'Èkwàtorìà',
 			'EE' => 'Èstonìà',
 			'EG' => 'Ègîptò',
 			'ER' => 'Èrìtrěà',
 			'ES' => 'Pànya',
 			'ET' => 'Ètìopìà',
 			'FI' => 'Fìnlând',
 			'FJ' => 'Fiji',
 			'FK' => 'Bìòn bi Falkland',
 			'FM' => 'Mìkrònesìà',
 			'FR' => 'Pùlàsi / Fɛ̀lɛ̀nsi /',
 			'GA' => 'Gàbɔ̂ŋ',
 			'GB' => 'Àdnà i Lɔ̂ŋ',
 			'GD' => 'Grènadà',
 			'GE' => 'Gèɔrgìà',
 			'GF' => 'Gùyanà Pùlàsi',
 			'GH' => 'Ganà',
 			'GI' => 'Gìlbràtâr',
 			'GL' => 'Grǐnlànd',
 			'GM' => 'Gàmbià',
 			'GN' => 'Gìnê',
 			'GP' => 'Gwàdèlûp',
 			'GQ' => 'Gìne Èkwàtorìà',
 			'GR' => 'Grǐkyà',
 			'GT' => 'Gwàtèmalà',
 			'GU' => 'Gùâm',
 			'GW' => 'Gìne Bìsàô',
 			'GY' => 'Gùyanà',
 			'HN' => 'Ɔ̀ŋduràs',
 			'HR' => 'Kròasìà',
 			'HT' => 'Àitì',
 			'HU' => 'Ɔ̀ŋgriì',
 			'ID' => 'Indònèsià',
 			'IE' => 'Ìrlând',
 			'IL' => 'Isràɛ̂l',
 			'IN' => 'Indìà',
 			'IO' => 'Bìtèk bi Ŋgisì i Tūyɛ Īndìà',
 			'IQ' => 'Ìrâk',
 			'IR' => 'Ìrâŋ',
 			'IS' => 'Ìslandìà',
 			'IT' => 'Ìtalìà',
 			'JM' => 'Jàmàikà',
 			'JO' => 'Yɔ̀rdanià',
 			'KE' => 'Kenìà',
 			'KG' => 'Kìrgìzìstàŋ',
 			'KH' => 'Kàmbodìà',
 			'KI' => 'Kìrìbatì',
 			'KM' => 'Kɔ̀mɔ̂r',
 			'KN' => 'Nûmpubi Kîts nì Nevìs',
 			'KP' => 'Kɔ̀re ì Ŋ̀ɔmbɔk',
 			'KR' => 'Kɔ̀re ì Ŋ̀wɛ̀lmbɔk',
 			'KW' => 'Kòwêt',
 			'KY' => 'Bìòn bi Kaymàn',
 			'KZ' => 'Kàzàkstâŋ',
 			'LA' => 'Làôs',
 			'LB' => 'Lèbanòn',
 			'LC' => 'Nûmpubi Lusì',
 			'LI' => 'Ligstɛntàn',
 			'LK' => 'Srìlaŋkà',
 			'LR' => 'Lìberìà',
 			'LS' => 'Lesòtò',
 			'LT' => 'Lìtùanìà',
 			'LU' => 'Lùgsàmbûr',
 			'LV' => 'Làdvià',
 			'LY' => 'Libìà',
 			'MA' => 'Màrokò',
 			'MC' => 'Mònakò',
 			'MD' => 'Moldavìà',
 			'MG' => 'Màdàgàskâr',
 			'MH' => 'Bìòn bi Marcàl',
 			'MK' => 'Màsèdonìà',
 			'ML' => 'Màli',
 			'MM' => 'Myànmâr',
 			'MN' => 'Mòŋgolìà',
 			'MP' => 'Bìòn bi Marìanà ŋ̀ɔmbɔk',
 			'MQ' => 'Màrtìnîk',
 			'MR' => 'Mòrìtanìà',
 			'MS' => 'Mɔ̀ŋseràt',
 			'MT' => 'Maltà',
 			'MU' => 'Mòrîs',
 			'MV' => 'Màldîf',
 			'MW' => 'Màlàwi',
 			'MX' => 'Mɛ̀gsîk',
 			'MY' => 'Màlɛ̀sìà',
 			'MZ' => 'Mòsàmbîk',
 			'NA' => 'Nàmibìà',
 			'NC' => 'Kàlèdonìà Yɔ̀ndɔ',
 			'NE' => 'Nìjɛ̂r',
 			'NF' => 'Òn i Nɔrfɔ̂k',
 			'NG' => 'Nìgerìà',
 			'NI' => 'Nìkàragwà',
 			'NL' => 'Ǹlɛndi',
 			'NO' => 'Nɔ̀rvegìà',
 			'NP' => 'Nèpâl',
 			'NR' => 'Nerù',
 			'NU' => 'Nìuɛ̀',
 			'NZ' => 'Sìlând Yɔ̀ndɔ',
 			'OM' => 'Òmân',
 			'PA' => 'Pànàma',
 			'PE' => 'Pèrû',
 			'PF' => 'Pòlìnesìà Pùlàsi',
 			'PG' => 'Gìne ì Pàpu',
 			'PH' => 'Fìlìpîn',
 			'PK' => 'Pàkìstân',
 			'PL' => 'Pòlànd',
 			'PM' => 'Nûmpubi Petrò nì Mikèlôn',
 			'PN' => 'Pìdkaìrn',
 			'PR' => 'Pɔ̀rtò Rikò',
 			'PS' => 'Pàlɛ̀htinà Hyɔ̀ŋg nì Gazà',
 			'PT' => 'Pɔ̀tɔkì',
 			'PW' => 'Pàlaù',
 			'PY' => 'Pàràgwê',
 			'QA' => 'Kàtâr',
 			'RE' => 'Rèunyɔ̂ŋ',
 			'RO' => 'Rùmanìà',
 			'RU' => 'Ruslànd',
 			'RW' => 'Rùandà',
 			'SA' => 'Sàudi Àrabìà',
 			'SB' => 'Bìòn bi Salōmò',
 			'SC' => 'Sèsɛ̂l',
 			'SD' => 'Sùdâŋ',
 			'SE' => 'Swedɛ̀n',
 			'SG' => 'Sìŋgàpûr',
 			'SH' => 'Nûmpubi Ɛlēnà',
 			'SI' => 'Slòvanìà',
 			'SK' => 'Slòvakìà',
 			'SL' => 'Sièra Lèɔ̂n',
 			'SM' => 'Nûmpubi Māatìn',
 			'SN' => 'Sènègâl',
 			'SO' => 'Sòmalìà',
 			'SR' => 'Sùrinâm',
 			'ST' => 'Sào Tòme ɓɔ Prɛ̀ŋcipè',
 			'SV' => 'Sàlvàdɔ̂r',
 			'SY' => 'Sirìà',
 			'SZ' => 'Swàzìlând',
 			'TC' => 'Bìòn bi Tûrks nì Kalkòs',
 			'TD' => 'Câd',
 			'TG' => 'Tògo',
 			'TH' => 'Taylànd',
 			'TJ' => 'Tàjìkìstaŋ',
 			'TK' => 'Tòkèlaò',
 			'TL' => 'Tìmɔ̂r lìkòl',
 			'TM' => 'Tùrgmènìstân',
 			'TN' => 'Tùnisìà',
 			'TO' => 'Tɔŋgà',
 			'TR' => 'Tùrkây',
 			'TT' => 'Trìnidàd ɓɔ Tòbagò',
 			'TV' => 'Tùvàlù',
 			'TW' => 'Tàywân',
 			'TZ' => 'Tànzànià',
 			'UA' => 'Ùkrɛ̌n',
 			'UG' => 'Ùgandà',
 			'US' => 'Àdnà i Bilɔ̀ŋ bi Amerkà',
 			'UY' => 'Ùrùgwêy',
 			'UZ' => 'Ùzbèkìstân',
 			'VA' => 'Vàtìkâŋ',
 			'VC' => 'Nûmpubi Vɛ̂ŋsâŋ nì grènàdîn',
 			'VE' => 'Vènèzùelà',
 			'VG' => 'Bìòn bi kɔnji bi Ŋgisì',
 			'VI' => 'Bìòn bi kɔnji bi U.S.',
 			'VN' => 'Vìɛ̀dnâm',
 			'VU' => 'Vànùatù',
 			'WF' => 'Wàlîs nì Fùtunà',
 			'WS' => 'Sàmoà',
 			'YE' => 'Yèmɛ̂n',
 			'YT' => 'Màyɔ̂t',
 			'ZA' => 'Àfrǐkà Sɔ̀',
 			'ZM' => 'Zàmbià',
 			'ZW' => 'Zìmbàbwê',

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
			auxiliary => qr{(?^u:[q x])},
			index => ['A', 'B', 'Ɓ', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{(?^u:[a á à â ǎ ā {a᷆}{a᷇} b ɓ c d e é è ê ě ē {e᷆}{e᷇} ɛ {ɛ́} {ɛ̀} {ɛ̂} {ɛ̌} {ɛ̄} {ɛ᷆}{ɛ᷇} f g h i í ì î ǐ ī {i᷆}{i᷇} j k l m n ń ǹ ŋ o ó ò ô ǒ ō {o᷆}{o᷇} ɔ {ɔ́} {ɔ̀} {ɔ̂} {ɔ̌} {ɔ̄} {ɔ᷆}{ɔ᷇} p r s t u ú ù û ǔ ū {u᷆}{u᷇} v w y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ɓ', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> qq{„},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ŋ̀ŋ̂|Ŋ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:tɔ̀|T|no|n)$' }
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
					'' => '#,##0 %',
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
				'currency' => q(Dirhàm èmìrâ),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwànza àŋgolà),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dɔ̀lâr òstralìà),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinâr Bàraìn),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Frǎŋ bùrundì),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pùla Bòtswanà),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dɔ̀lâr kànadà),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Frǎŋ kòŋgo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Frǎŋ sùwîs),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yùan kinà),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Èskudò kabwe᷆r),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Frǎŋ jìbutì),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dìnâr àlgerìà),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Paùnd ègîptò),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nafkà èrìtrěà),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bîr ètìopìà),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Èrô),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Stɛrlìŋ ŋgìsì),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sèdi gānà),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasì gambìà),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Frǎŋ gìnê),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rùpi īndìà),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yɛ̂n yàpân),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Silîŋ kenìà),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Frǎŋ kòmorà),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dɔ̀lâr lìberìà),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lotì lèsòtò),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dìnâr libìà),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dìrham màrôk),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Frǎŋ màlàgasì),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ùgwiya mòrìtanìa),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupìɛ̀ mòrîs),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwaca màlawì),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mètìkal mòsàmbîk),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dɔ̀lâr nàmibìà),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nayrà nìgerìà),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Frǎŋ Rùandà),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rìal sàudì),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rùpiɛ̀ sèsɛ̂l),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dìnâr sùdân),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Paùnd sùdân),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Paùnd hèlenà),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Lèonɛ̀),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Silîŋ sòmàli),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobrà sàotòme),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lìlàŋgeni swàzì),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dìnâr tùnîs),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Silîŋ tànzànià),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Silîŋ ùgàndà),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dɔla àmerkà),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Frǎŋ CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Frǎŋ CFA \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rân àfrǐkàsɔ̀),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwàca sàmbià \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwàca sàmbià),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dɔ̀lâr sìmbàbwê),
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
							'kɔn',
							'mac',
							'mat',
							'mto',
							'mpu',
							'hil',
							'nje',
							'hik',
							'dip',
							'bio',
							'may',
							'liɓ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Kɔndɔŋ',
							'Màcɛ̂l',
							'Màtùmb',
							'Màtop',
							'M̀puyɛ',
							'Hìlòndɛ̀',
							'Njèbà',
							'Hìkaŋ',
							'Dìpɔ̀s',
							'Bìòôm',
							'Màyɛsèp',
							'Lìbuy li ńyèe'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'k',
							'm',
							'm',
							'm',
							'm',
							'h',
							'n',
							'h',
							'd',
							'b',
							'm',
							'l'
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
						mon => 'nja',
						tue => 'uum',
						wed => 'ŋge',
						thu => 'mbɔ',
						fri => 'kɔɔ',
						sat => 'jon',
						sun => 'nɔy'
					},
					wide => {
						mon => 'ŋgwà njaŋgumba',
						tue => 'ŋgwà ûm',
						wed => 'ŋgwà ŋgê',
						thu => 'ŋgwà mbɔk',
						fri => 'ŋgwà kɔɔ',
						sat => 'ŋgwà jôn',
						sun => 'ŋgwà nɔ̂y'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'n',
						tue => 'u',
						wed => 'ŋ',
						thu => 'm',
						fri => 'k',
						sat => 'j',
						sun => 'n'
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
					abbreviated => {0 => 'K1s3',
						1 => 'K2s3',
						2 => 'K3s3',
						3 => 'K4s3'
					},
					wide => {0 => 'Kèk bisu i soŋ iaâ',
						1 => 'Kèk i ńyonos biɓaà i soŋ iaâ',
						2 => 'Kèk i ńyonos biaâ i soŋ iaâ',
						3 => 'Kèk i ńyonos binâ i soŋ iaâ'
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
					'pm' => q{I ɓugajɔp},
					'am' => q{I bikɛ̂glà},
				},
				'abbreviated' => {
					'am' => q{I bikɛ̂glà},
					'pm' => q{I ɓugajɔp},
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
				'0' => 'b.Y.K',
				'1' => 'm.Y.K'
			},
			wide => {
				'0' => 'bisū bi Yesù Krǐstò',
				'1' => 'i mbūs Yesù Krǐstò'
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
