=head1

Locale::CLDR::Locales::Bez - Package for language Bena

=cut

package Locale::CLDR::Locales::Bez;
# This file auto generated from Data\common\main\bez.xml
#	on Fri 29 Apr  6:52:28 pm GMT

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
				'ak' => 'Hiakan',
 				'am' => 'Hiamhari',
 				'ar' => 'Hiharabu',
 				'be' => 'Hibelarusi',
 				'bez' => 'Hibena',
 				'bg' => 'Hibulgaria',
 				'bn' => 'Hibangla',
 				'cs' => 'Hicheki',
 				'de' => 'Hijerumani',
 				'el' => 'Higiriki',
 				'en' => 'Hiingereza',
 				'es' => 'Hihispania',
 				'fa' => 'Hiajemi',
 				'fr' => 'Hifaransa',
 				'ha' => 'Hihausa',
 				'hi' => 'Hihindi',
 				'hu' => 'Hihungari',
 				'id' => 'Hiindonesia',
 				'ig' => 'Hiibo',
 				'it' => 'Hiitaliano',
 				'ja' => 'Hijapani',
 				'jv' => 'Hijava',
 				'km' => 'Hikambodia',
 				'ko' => 'Hikorea',
 				'ms' => 'Himalesia',
 				'my' => 'Hiburma',
 				'ne' => 'Hinepali',
 				'nl' => 'Hiholanzi',
 				'pa' => 'Hipunjabi',
 				'pl' => 'Hipolandi',
 				'pt' => 'Hileno',
 				'ro' => 'Hilomania',
 				'ru' => 'Hilusi',
 				'rw' => 'Hinyarwanda',
 				'so' => 'Hisomali',
 				'sv' => 'Hiswidi',
 				'ta' => 'Hitamil',
 				'th' => 'Hitailand',
 				'tr' => 'Hituluki',
 				'uk' => 'Hiukrania',
 				'ur' => 'Hiurdu',
 				'vi' => 'Hivietinamu',
 				'yo' => 'Hiyoruba',
 				'zh' => 'Hichina',
 				'zu' => 'Hizulu',

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
			'AD' => 'Huandola',
 			'AE' => 'Hufalme dza Hihalabu',
 			'AF' => 'Huafuganistani',
 			'AG' => 'Huantigua na Hubarubuda',
 			'AI' => 'Huanguila',
 			'AL' => 'Hualbania',
 			'AM' => 'Huamenia',
 			'AO' => 'Huangola',
 			'AR' => 'Huajendina',
 			'AS' => 'Husamoa ya Humalekani',
 			'AT' => 'Huastlia',
 			'AU' => 'Huaustlalia',
 			'AW' => 'Hualuba',
 			'AZ' => 'Huazabajani',
 			'BA' => 'Hubosinia na Huhezegovina',
 			'BB' => 'Hubabadosi',
 			'BD' => 'Hubangaladeshi',
 			'BE' => 'Huubelgiji',
 			'BF' => 'Hubukinafaso',
 			'BG' => 'Hubulgaria',
 			'BH' => 'Hubahaleni',
 			'BI' => 'Huburundi',
 			'BJ' => 'Hubenini',
 			'BM' => 'Hubelmuda',
 			'BN' => 'Hubrunei',
 			'BO' => 'Hubolivia',
 			'BR' => 'Hublazili',
 			'BS' => 'Hubahama',
 			'BT' => 'Hubutani',
 			'BW' => 'Hubotiswana',
 			'BY' => 'Hubelalusi',
 			'BZ' => 'Hubelize',
 			'CA' => 'Hukanada',
 			'CD' => 'Ijamhuri ya Hidemokrasi ya Hukongo',
 			'CF' => 'Ijamhuri ya Afrika ya Pagati',
 			'CG' => 'Hukongo',
 			'CH' => 'Huuswisi',
 			'CI' => 'Hukodivaa',
 			'CK' => 'Ifisima fya Kook',
 			'CL' => 'Huchile',
 			'CM' => 'Hukameruni',
 			'CN' => 'Huchina',
 			'CO' => 'Hukolombia',
 			'CR' => 'Hukostarika',
 			'CU' => 'Hukuba',
 			'CV' => 'Hukepuvede',
 			'CY' => 'Hukuprosi',
 			'CZ' => 'Ijamhuri ya Cheki',
 			'DE' => 'Huujerumani',
 			'DJ' => 'Hujibuti',
 			'DK' => 'Hudenmaki',
 			'DM' => 'Hudominika',
 			'DO' => 'Ijamhuri ya Hudominika',
 			'DZ' => 'Hualjelia',
 			'EC' => 'Huekwado',
 			'EE' => 'Huestonia',
 			'EG' => 'Humisri',
 			'ER' => 'Hueritrea',
 			'ES' => 'Huhispania',
 			'ET' => 'Huuhabeshi',
 			'FI' => 'Huufini',
 			'FJ' => 'Hufiji',
 			'FK' => 'Ifisima fya Falkland',
 			'FM' => 'Humikronesia',
 			'FR' => 'Huufaransa',
 			'GA' => 'Hugaboni',
 			'GB' => 'Huuingereza',
 			'GD' => 'Hugrenada',
 			'GE' => 'Hujojia',
 			'GF' => 'Hugwiyana ya Huufaransa',
 			'GH' => 'Hughana',
 			'GI' => 'Hujiblalta',
 			'GL' => 'Hujinlandi',
 			'GM' => 'Hugambia',
 			'GN' => 'Hujine',
 			'GP' => 'Hugwadelupe',
 			'GQ' => 'Huginekweta',
 			'GR' => 'Huugiliki',
 			'GT' => 'Hugwatemala',
 			'GU' => 'Hugwam',
 			'GW' => 'Huginebisau',
 			'GY' => 'Huguyana',
 			'HN' => 'Huhondulasi',
 			'HR' => 'Hukorasia',
 			'HT' => 'Huhaiti',
 			'HU' => 'Huhungalia',
 			'ID' => 'Huindonesia',
 			'IE' => 'Huayalandi',
 			'IL' => 'Huislaheli',
 			'IN' => 'Huindia',
 			'IO' => 'Ulubali lwa Hubahari ya Hindi lwa Huingereza',
 			'IQ' => 'Huilaki',
 			'IR' => 'Huuajemi',
 			'IS' => 'Huaislandi',
 			'IT' => 'Huitalia',
 			'JM' => 'Hujamaika',
 			'JO' => 'Huyolodani',
 			'JP' => 'Hujapani',
 			'KE' => 'Hukenya',
 			'KG' => 'Hukiligizistani',
 			'KH' => 'Hukambodia',
 			'KI' => 'Hukilibati',
 			'KM' => 'Hukomoro',
 			'KN' => 'Husantakitzi na Hunevis',
 			'KP' => 'Hukolea Kaskazini',
 			'KR' => 'Hukolea Kusini',
 			'KW' => 'Hukuwaiti',
 			'KY' => 'Ifisima fya Kayman',
 			'KZ' => 'Hukazakistani',
 			'LA' => 'Hulaosi',
 			'LB' => 'Hulebanoni',
 			'LC' => 'Husantalusia',
 			'LI' => 'Hulishenteni',
 			'LK' => 'Husirilanka',
 			'LR' => 'Hulibelia',
 			'LS' => 'Hulesoto',
 			'LT' => 'Hulitwania',
 			'LU' => 'Hulasembagi',
 			'LV' => 'Hulativia',
 			'LY' => 'Hulibiya',
 			'MA' => 'Humoloko',
 			'MC' => 'Humonako',
 			'MD' => 'Humoldova',
 			'MG' => 'Hubukini',
 			'MH' => 'Ifisima fya Marshal',
 			'MK' => 'Humasedonia',
 			'ML' => 'Humali',
 			'MM' => 'Humyama',
 			'MN' => 'Humongolia',
 			'MP' => 'Ifisima fya Mariana fya Hukaskazini',
 			'MQ' => 'Humartiniki',
 			'MR' => 'Humolitania',
 			'MS' => 'Humontserrati',
 			'MT' => 'Humalta',
 			'MU' => 'Humolisi',
 			'MV' => 'Humodivu',
 			'MW' => 'Humalawi',
 			'MX' => 'Humeksiko',
 			'MY' => 'Humalesia',
 			'MZ' => 'Humusumbiji',
 			'NA' => 'Hunamibia',
 			'NC' => 'Hunyukaledonia',
 			'NE' => 'Hunijeli',
 			'NF' => 'Ihisima sha Norfok',
 			'NG' => 'Hunijelia',
 			'NI' => 'Hunikaragwa',
 			'NL' => 'Huuholanzi',
 			'NO' => 'Hunolwe',
 			'NP' => 'Hunepali',
 			'NR' => 'Hunauru',
 			'NU' => 'Huniue',
 			'NZ' => 'Hunyuzilandi',
 			'OM' => 'Huomani',
 			'PA' => 'Hupanama',
 			'PE' => 'Hupelu',
 			'PF' => 'Hupolinesia ya Huufaransa',
 			'PG' => 'Hupapua',
 			'PH' => 'Hufilipino',
 			'PK' => 'Hupakistani',
 			'PL' => 'Hupolandi',
 			'PM' => 'Husantapieri na Humikeloni',
 			'PN' => 'Hupitkaini',
 			'PR' => 'Hupwetoriko',
 			'PS' => 'Ulubali lwa Magharibi nu Gaza wa Hupalestina',
 			'PT' => 'Huuleno',
 			'PW' => 'Hupalau',
 			'PY' => 'Hupalagwai',
 			'QA' => 'Hukatali',
 			'RE' => 'Huliyunioni',
 			'RO' => 'Hulomania',
 			'RU' => 'Huulusi',
 			'RW' => 'Hulwanda',
 			'SA' => 'Husaudi',
 			'SB' => 'Ifisima fya Solomon',
 			'SC' => 'Hushelisheli',
 			'SD' => 'Husudani',
 			'SE' => 'Huuswidi',
 			'SG' => 'Husingapoo',
 			'SH' => 'Husantahelena',
 			'SI' => 'Huslovenia',
 			'SK' => 'Huslovakia',
 			'SL' => 'Husiela Lioni',
 			'SM' => 'Husamalino',
 			'SN' => 'Husenegali',
 			'SO' => 'Husomalia',
 			'SR' => 'Husurinamu',
 			'ST' => 'Husaotome na Huprinsipe',
 			'SV' => 'Huelsavado',
 			'SY' => 'Husilia',
 			'SZ' => 'Huuswazi',
 			'TC' => 'Ifisima fya Turki na Kaiko',
 			'TD' => 'Huchadi',
 			'TG' => 'Hutogo',
 			'TH' => 'Hutailandi',
 			'TJ' => 'Hutajikistani',
 			'TK' => 'Hutokelau',
 			'TL' => 'Hutimori ya Mashariki',
 			'TM' => 'Huuturukimenistani',
 			'TN' => 'Hutunisia',
 			'TO' => 'Hutonga',
 			'TR' => 'Huuturuki',
 			'TT' => 'Hutrinad na Hutobago',
 			'TV' => 'Hutuvalu',
 			'TW' => 'Hutaiwani',
 			'TZ' => 'Hutanzania',
 			'UA' => 'Huukraini',
 			'UG' => 'Huuganda',
 			'US' => 'Humalekani',
 			'UY' => 'Huulugwai',
 			'UZ' => 'Huuzibekistani',
 			'VA' => 'Huvatikani',
 			'VC' => 'Husantavisenti na Hugrenadini',
 			'VE' => 'Huvenezuela',
 			'VG' => 'Ifisima fya Virgin fya Huingereza',
 			'VI' => 'Ifisima fya Virgin fya Humelekani',
 			'VN' => 'Huvietinamu',
 			'VU' => 'Huvanuatu',
 			'WF' => 'Huwalis na Hufutuna',
 			'WS' => 'Husamoa',
 			'YE' => 'Huyemeni',
 			'YT' => 'Humayotte',
 			'ZA' => 'Huafrika iya Hukusini',
 			'ZM' => 'Huzambia',
 			'ZW' => 'Huzimbabwe',

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
			auxiliary => qr{(?^u:[x])},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{(?^u:[a b c d e f g h i j k l m n o p q r s t u v w y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Eeh|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Sio ewo|S|no|n)$' }
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
				'currency' => q(Lupila lwa Hufalme dza Huhihalabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Lupila lwa Huangola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Lupila lwa Huaustlalia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Lupila lwa Hubahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Lupila lwa Huburundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Lupila lwa Hubotswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Lupila lwa Hukanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Lupila lwa Hukongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Lupila lwa Huuswisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Lupila lwa Huchina),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Lupila lwa Hukepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Lupila lwa Hujibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Lupila lwa Hualjelia),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Lupila lwa Humisri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Lupila lwa Hueritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Lupila lwa Huuhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Lupila lwa Yulo),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Lupila lwa Huuingereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Lupila lwa Hughana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Lupila lwa Hugambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Lupila lwa Hujine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Lupila lwa Huindia),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Lupila lwa Hijapani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilingi ya Hukenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Lupila lwa Hukomoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Lupila lwa Hulibelia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lupila lwa Hulesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Lupila lwa Hulibya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Lupila lwa Humoloko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Lupila lwa Hubukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Lupila lwa Humolitania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Lupila lwa Humolisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Lupila lwa Humalawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Lupila lwa Humsumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Lupila lwa Hunamibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Lupila lwa Hunijelia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Lupila lwa Hurwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Lupila lwa Husaudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Lupila lwa Hushelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Lupila lwa Husudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Lupila lwa Husantahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Lupila lwa Lioni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Lupila lwa Husomalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Lupila lwa Husaotome na Huprinisipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lupila lwa Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Lupila lwa Hutunisia),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(Shilingi ya Hutanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingi ya Huuganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Lupila lwa Humalekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Lupila lwa CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Lupila lwa CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Lupila lwa Huafriaka ya Hukusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Lupila lwa Huzambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Lupila lwa Huzambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Lupila lwa Huzimbabwe),
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
							'Hut',
							'Vil',
							'Dat',
							'Tai',
							'Han',
							'Sit',
							'Sab',
							'Nan',
							'Tis',
							'Kum',
							'Kmj',
							'Kmb'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'pa mwedzi gwa hutala',
							'pa mwedzi gwa wuvili',
							'pa mwedzi gwa wudatu',
							'pa mwedzi gwa wutai',
							'pa mwedzi gwa wuhanu',
							'pa mwedzi gwa sita',
							'pa mwedzi gwa saba',
							'pa mwedzi gwa nane',
							'pa mwedzi gwa tisa',
							'pa mwedzi gwa kumi',
							'pa mwedzi gwa kumi na moja',
							'pa mwedzi gwa kumi na mbili'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'H',
							'V',
							'D',
							'T',
							'H',
							'S',
							'S',
							'N',
							'T',
							'K',
							'K',
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
						mon => 'Vil',
						tue => 'Hiv',
						wed => 'Hid',
						thu => 'Hit',
						fri => 'Hih',
						sat => 'Lem',
						sun => 'Mul'
					},
					wide => {
						mon => 'pa shahuviluha',
						tue => 'pa hivili',
						wed => 'pa hidatu',
						thu => 'pa hitayi',
						fri => 'pa hihanu',
						sat => 'pa shahulembela',
						sun => 'pa mulungu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'J',
						tue => 'H',
						wed => 'H',
						thu => 'H',
						fri => 'W',
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
				'wide' => {
					'am' => q{pamilau},
					'pm' => q{pamunyi},
				},
				'abbreviated' => {
					'pm' => q{pamunyi},
					'am' => q{pamilau},
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
				'0' => 'KM',
				'1' => 'BM'
			},
			wide => {
				'0' => 'Kabla ya Mtwaa',
				'1' => 'Baada ya Mtwaa'
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
