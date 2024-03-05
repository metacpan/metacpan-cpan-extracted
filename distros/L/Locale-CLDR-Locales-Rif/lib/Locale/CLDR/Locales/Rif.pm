=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Rif - Package for language Riffian

=cut

package Locale::CLDR::Locales::Rif;
# This file auto generated from Data\common\main\rif.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
				'ar' => 'taɛrabt',
 				'ar_001' => 'taɛrabt tamaynut',
 				'bn' => 'tabanɣaliyt',
 				'de' => 'talimant',
 				'de_AT' => 'talimant (AT)',
 				'de_CH' => 'talimant (CH)',
 				'en' => 'taglinzit',
 				'en_AU' => 'taglinzit (AU)',
 				'en_CA' => 'taglinzit (CA)',
 				'en_GB' => 'taglinzit (GB)',
 				'en_US' => 'taglinzit (US)',
 				'es' => 'taseppanyut',
 				'es_419' => 'taseppanyut talatinit',
 				'es_ES' => 'taseppanyut (ES)',
 				'es_MX' => 'taseppanyut (MX)',
 				'fr' => 'tafransist',
 				'fr_CA' => 'tafransist (CA)',
 				'fr_CH' => 'tafransist (CH)',
 				'hi_Latn' => 'tahindawiyt',
 				'id' => 'tayindusiyt',
 				'it' => 'tatayalt',
 				'ja' => 'tajappuniyt',
 				'ko' => 'takuriyt',
 				'nl' => 'tahulandiyt',
 				'nl_BE' => 'taflamant',
 				'pl' => 'tapulandiyt',
 				'pt' => 'tapuruɣaliyt',
 				'pt_BR' => 'tapuruɣaliyt (BR)',
 				'pt_PT' => 'tapuruɣaliyt (PT)',
 				'rif' => 'Tarifit',
 				'ru' => 'tarusiyt',
 				'th' => 'taṭayiyt',
 				'tr' => 'taṭurkiyt',
 				'und' => 'tutlayt nneɣni',
 				'zh' => 'tatcinwiyt',
 				'zh@alt=menu' => 'tamandariyt',
 				'zh_Hans' => 'tatcinwiyt tsampla',
 				'zh_Hans@alt=long' => 'tatcinwiyt tamandariyt tsampla',
 				'zh_Hant' => 'tatcinwiyt taqdint',
 				'zh_Hant@alt=long' => 'tatcinwiyt tamandariyt taqdint',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Arab' => 'aɛrab',
 			'Cyrl' => 'asirilik',
 			'Hans' => 'yehwen',
 			'Hans@alt=stand-alone' => 'yehwen Han',
 			'Hant' => 'amensay',
 			'Hant@alt=stand-alone' => 'amensay Han',
 			'Jpan' => 'ajappuni',
 			'Kore' => 'akuri',
 			'Latn' => 'talatinit',
 			'Tfng' => 'tifinaɣ',
 			'Zxxx' => 'wer ttemwari',
 			'Zzzz' => 'asekkil nneɣni',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'amaḍal',
 			'002' => 'tafriqt',
 			'003' => 'amarikan n sennej',
 			'005' => 'amarikan n wadday',
 			'009' => 'usyanya',
 			'011' => 'lɣerb n tefriqt',
 			'013' => 'amarikan n lwest',
 			'014' => 'ccerq n tefriqt',
 			'015' => 'tqiccet n tfriqt',
 			'017' => 'lwest n tefriqt',
 			'018' => 'wadday n tefriqt',
 			'019' => 'timirikatin',
 			'021' => 'sennej n umarikan',
 			'029' => 'karibyan',
 			'030' => 'ccerq n asya',
 			'034' => 'wadday n asya',
 			'035' => 'wadday ccerq n asya',
 			'039' => 'wadday n wuruppa',
 			'053' => 'ustralazya',
 			'054' => 'milanizya',
 			'057' => 'jjiḥt n mikrunizya',
 			'061' => 'pulinizya',
 			'142' => 'asya',
 			'143' => 'lwest n asya',
 			'145' => 'lɣerb n asya',
 			'150' => 'uruppa',
 			'151' => 'ccerq n wuruppa',
 			'154' => 'sennej n wuruppa',
 			'155' => 'lɣerb n wuruppa',
 			'202' => 'tafriqt n wadday i sseḥra',
 			'419' => 'amarikan talatinit',
 			'AC' => 'tigzirin n asincyun',
 			'AD' => 'andura',
 			'AE' => 'limarat',
 			'AF' => 'afɣanistan',
 			'AG' => 'antigwa d barbuda',
 			'AI' => 'angwilla',
 			'AL' => 'albanya',
 			'AM' => 'arminya',
 			'AO' => 'angula',
 			'AQ' => 'antarktika',
 			'AR' => 'arxantina',
 			'AS' => 'sawma tamirikanit',
 			'AT' => 'nnemsa',
 			'AU' => 'ustralya',
 			'AW' => 'aruba',
 			'AX' => 'tagzirt n aland',
 			'AZ' => 'azrabijan',
 			'BA' => 'busna d hirsek',
 			'BB' => 'barbaḍus',
 			'BD' => 'bangladic',
 			'BE' => 'biljik',
 			'BF' => 'burkinafasu',
 			'BG' => 'belɣarya',
 			'BH' => 'lbeḥrin',
 			'BI' => 'burundi',
 			'BJ' => 'benin',
 			'BL' => 'sanbartilimi',
 			'BM' => 'birmuda',
 			'BN' => 'brunay',
 			'BO' => 'bulivya',
 			'BQ' => 'hulanda takaribiyt',
 			'BR' => 'brazil',
 			'BS' => 'bahamas',
 			'BT' => 'buṭan',
 			'BV' => 'tigzirin n buvi',
 			'BW' => 'buteswana',
 			'BY' => 'bilarus',
 			'BZ' => 'biliz',
 			'CA' => 'kanada',
 			'CC' => 'tigzirin n kukus',
 			'CD' => 'rripublik tadimuqratit n kungu',
 			'CF' => 'rripublik n terfriqt n lwesṭ',
 			'CG' => 'kungu',
 			'CH' => 'sswis',
 			'CI' => 'kudivwar',
 			'CK' => 'tigzirin n kuk',
 			'CL' => 'tcili',
 			'CM' => 'kamirun',
 			'CN' => 'tcina',
 			'CO' => 'kulumbya',
 			'CP' => 'tigzirin n klipirṭun',
 			'CR' => 'kustarika',
 			'CU' => 'kuba',
 			'CV' => 'qabu yazegza',
 			'CW' => 'kurasaw',
 			'CX' => 'tagzirt n kristmas',
 			'CY' => 'qubrus',
 			'CZ' => 'ttcik',
 			'CZ@alt=variant' => 'rripublik n ttcik',
 			'DE' => 'aliman',
 			'DG' => 'dyigugarsya',
 			'DJ' => 'djibuti',
 			'DK' => 'ddanmark',
 			'DM' => 'duminika',
 			'DO' => 'arripublik n dduminikan',
 			'DZ' => 'ddzayer',
 			'EA' => 'sebta d mlillt',
 			'EC' => 'ikwadur',
 			'EE' => 'istunya',
 			'EG' => 'maser',
 			'EH' => 'sseḥra n lɣerb',
 			'ER' => 'iritirya',
 			'ES' => 'seppanya',
 			'ET' => 'ityupya',
 			'EU' => 'tamunt tawruppawit',
 			'EZ' => 'jjiht n wuru',
 			'FI' => 'fillanda',
 			'FJ' => 'fiji',
 			'FK' => 'tigzirin n falkland',
 			'FM' => 'mikrunizya',
 			'FO' => 'tigzirin n faru',
 			'FR' => 'fransa',
 			'GA' => 'gabun',
 			'GB' => 'aglinzi',
 			'GB@alt=short' => 'UK',
 			'GD' => 'grinada',
 			'GE' => 'jurejya',
 			'GF' => 'ɣuyana tafransist',
 			'GG' => 'girnizi',
 			'GH' => 'ɣana',
 			'GI' => 'jibralṭar',
 			'GL' => 'grinlanda',
 			'GM' => 'gambya',
 			'GN' => 'ɣinya',
 			'GP' => 'gwadlup',
 			'GQ' => 'ɣinya tayikwaṭurit',
 			'GR' => 'legrig',
 			'GS' => 'tigzirin n jyurejya n wadday d sandwitc n wadday',
 			'GT' => 'gwatimala',
 			'GU' => 'gwam',
 			'GW' => 'ɣinyabisaw',
 			'GY' => 'ɣuyana',
 			'HK' => 'hungkung',
 			'HM' => 'tigzirin n hird d makdunald',
 			'HN' => 'hunduras',
 			'HR' => 'kerwatya',
 			'HT' => 'hayti',
 			'HU' => 'hungarya',
 			'IC' => 'kanarya',
 			'ID' => 'andunisya',
 			'IE' => 'irlanda',
 			'IL' => 'israyil',
 			'IM' => 'tagzirt n man',
 			'IN' => 'lhend',
 			'IO' => 'timmura n uglanzi di lebḥer ahindawi',
 			'IQ' => 'lɛiraq',
 			'IR' => 'iran',
 			'IS' => 'ayeslanda',
 			'IT' => 'atayal',
 			'JE' => 'jirsi',
 			'JM' => 'jamayka',
 			'JO' => 'lurdun',
 			'JP' => 'jjapun',
 			'KE' => 'kinya',
 			'KG' => 'kirgistan',
 			'KH' => 'kambudya',
 			'KI' => 'kribati',
 			'KM' => 'qumrus',
 			'KN' => 'sankits d nivis',
 			'KP' => 'kurya n sennej',
 			'KR' => 'kurya n wadday',
 			'KW' => 'lkuwayt',
 			'KY' => 'tigzirin n kayman',
 			'KZ' => 'kazaxistan',
 			'LA' => 'lawes',
 			'LB' => 'lubnan',
 			'LC' => 'sanlusya',
 			'LI' => 'lictenctayn',
 			'LK' => 'srilanka',
 			'LR' => 'libirya',
 			'LS' => 'lisutu',
 			'LT' => 'litwanya',
 			'LU' => 'lluksemburg',
 			'LV' => 'latevya',
 			'LY' => 'libya',
 			'MA' => 'Lmuɣrib',
 			'MC' => 'munaku',
 			'MD' => 'mulduva',
 			'ME' => 'muntinigru',
 			'MF' => 'sanmartin',
 			'MG' => 'madaɣacqar',
 			'MH' => 'tigzirin n marcal',
 			'MK' => 'maqdunya n sennej',
 			'ML' => 'mali',
 			'MM' => 'myanmar',
 			'MN' => 'mangulya',
 			'MO' => 'makkaw',
 			'MP' => 'tigzirin n maryana n sennej',
 			'MQ' => 'martinik',
 			'MR' => 'muritanya',
 			'MS' => 'munsirat',
 			'MT' => 'malṭa',
 			'MU' => 'muricyus',
 			'MV' => 'lmaldiv',
 			'MW' => 'malawi',
 			'MX' => 'miksiku',
 			'MY' => 'malizya',
 			'MZ' => 'muzembiq',
 			'NA' => 'nambya',
 			'NC' => 'kalidunya tamaynut',
 			'NE' => 'nnijir',
 			'NF' => 'tagzirt n nurfulk',
 			'NG' => 'nijirya',
 			'NI' => 'nikaragwa',
 			'NL' => 'hulanda',
 			'NO' => 'nnarwij',
 			'NP' => 'nippal',
 			'NR' => 'nawru',
 			'NU' => 'nyiwi',
 			'NZ' => 'nyuziland',
 			'OM' => 'ɛumman',
 			'PA' => 'panama',
 			'PE' => 'piru',
 			'PF' => 'pulinizya tafransist',
 			'PG' => 'papwa ɣinya tamaynut',
 			'PH' => 'filippin',
 			'PK' => 'pakistan',
 			'PL' => 'pulanda',
 			'PM' => 'sanpyir d miklun',
 			'PN' => 'tigzirin n pitkirn',
 			'PR' => 'purturiku',
 			'PS' => 'falasṭin',
 			'PS@alt=short' => 'filasṭin',
 			'PT' => 'ppurtugal',
 			'PW' => 'palaw',
 			'PY' => 'paragway',
 			'QA' => 'qaṭar',
 			'QO' => 'usyanya i yegʷjen',
 			'RE' => 'rinyun',
 			'RO' => 'rumanya',
 			'RS' => 'sirebya',
 			'RU' => 'rrusya',
 			'RW' => 'rwanda',
 			'SA' => 'ssaɛud',
 			'SB' => 'tigzirin n suliman',
 			'SC' => 'sicel',
 			'SD' => 'ssudan',
 			'SE' => 'sswid',
 			'SG' => 'sanɣafura',
 			'SH' => 'santḥilina',
 			'SI' => 'sluvinya',
 			'SJ' => 'svalbard d janmayen',
 			'SK' => 'sluvakya',
 			'SL' => 'siraliyyun',
 			'SM' => 'sanmarinu',
 			'SN' => 'ssinigal',
 			'SO' => 'sumalya',
 			'SR' => 'surinam',
 			'SS' => 'ssudan n wadday',
 			'ST' => 'sawṭumi d prinsip',
 			'SV' => 'ssalvadur',
 			'SX' => 'santmartin',
 			'SY' => 'surya',
 			'SZ' => 'iswatini',
 			'TA' => 'tristan dakuna',
 			'TC' => 'ṭṭurks d tegzirin n kaykus',
 			'TD' => 'tcad',
 			'TF' => 'timmura tifransisin nwadday',
 			'TG' => 'ṭṭugu',
 			'TH' => 'ṭṭayland',
 			'TJ' => 'tajikistan',
 			'TK' => 'ṭukilu',
 			'TL' => 'ṭimur licti',
 			'TL@alt=variant' => 'ṭimur n ccerq',
 			'TM' => 'ṭurkmanistan',
 			'TN' => 'tunes',
 			'TO' => 'ṭunga',
 			'TR' => 'ṭurekya',
 			'TR@alt=variant' => 'ṭṭurk',
 			'TT' => 'trinidad d ṭubagu',
 			'TV' => 'ṭuvalu',
 			'TW' => 'ṭṭaywan',
 			'TZ' => 'ṭanzanya',
 			'UA' => 'ukrayina',
 			'UG' => 'uɣanda',
 			'UM' => 'tigzirin timirikanin i yegʷjen',
 			'UN' => 'tamunt n tmura',
 			'US' => 'amarikan',
 			'US@alt=short' => 'US',
 			'UY' => 'urugway',
 			'UZ' => 'uzbakistan',
 			'VA' => 'lvatikan',
 			'VC' => 'sanvinsit d grinadin',
 			'VE' => 'vanzwilla',
 			'VG' => 'tigzirin tiɛezriyyin tiglanziyyin',
 			'VI' => 'tigzirin tiɛezriyyin timarikanin',
 			'VN' => 'vitnam',
 			'VU' => 'vanwatu',
 			'WF' => 'walis d futuna',
 			'WS' => 'samwa',
 			'XA' => 'awal amsaqar',
 			'XB' => 'bidi tamsaqart',
 			'XK' => 'kusuvu',
 			'YE' => 'lyaman',
 			'YT' => 'mayuṭ',
 			'ZA' => 'tafriqt n wadday',
 			'ZM' => 'zambya',
 			'ZW' => 'zimbabwi',
 			'ZZ' => 'jjiht wer yettemwassnen',

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
 				'gregorian' => q{taklindart tagrikant},
 				'islamic' => q{taklindart tameslemt},
 				'islamic-civil' => q{taklindart tameslemt (leḥsab)},
 				'islamic-tbla' => q{taklindart tameslemt (ayur)},
 				'iso8601' => q{kalandar n ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{asettef sṭandar},
 			},
 			'numbers' => {
 				'latn' => q{nnurwat irumiyyen},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{amitrik},
 			'UK' => q{aglinziy},
 			'US' => q{amirikaniy},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'tutlayt: {0}',
 			'script' => 'tira: {0}',
 			'region' => 'jjihet: {0}',

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
			auxiliary => qr{[áàâä ç éèêë îï ñ oóôö œ ß úùûü v ʷ ÿ]},
			index => ['A', 'B', 'C', 'DḌ', 'E', 'Ɛ', 'F', 'G', 'Ɣ', 'HḤ', 'I', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'SṢ', 'TṬ', 'U', 'W', 'X', 'Y', 'ZẒ'],
			main => qr{[a b c dḍ e ɛ f g ɣ hḥ i j k l m n p q r sṣ tṭ u w x y zẓ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” « » ( ) \[ \] \{ \} § @ * / \& # `]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'DḌ', 'E', 'Ɛ', 'F', 'G', 'Ɣ', 'HḤ', 'I', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'SṢ', 'TṬ', 'U', 'W', 'X', 'Y', 'ZẒ'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(amnad akardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(amnad akardinal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ccerq),
						'north' => q({0} ẓelmeḍ),
						'south' => q({0} wadday),
						'west' => q({0} lɣerb),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ccerq),
						'north' => q({0} ẓelmeḍ),
						'south' => q({0} wadday),
						'west' => q({0} lɣerb),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} xef {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} xef {1}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}C),
						'north' => q({0}Ẓ),
						'south' => q({0}W),
						'west' => q({0}L),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}C),
						'north' => q({0}Ẓ),
						'south' => q({0}W),
						'west' => q({0}L),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(amnad),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(amnad),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} C),
						'north' => q({0} Ẓ),
						'south' => q({0} W),
						'west' => q({0} L),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} C),
						'north' => q({0} Ẓ),
						'south' => q({0} W),
						'west' => q({0} L),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} d {1}),
				2 => q({0} d {1}),
		} }
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
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '0%',
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
		'BMD' => {
			display_name => {
				'currency' => q(Bermudan Dollar),
				'other' => q(ddular n birmudan),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dollar),
				'other' => q(ddular n biliz),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Canadian Dollar),
				'other' => q(ddular n kanada),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rican Colón),
				'other' => q(kulun n kustarika),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danish Krone),
				'other' => q(kruna n ddanmark),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian Dinar),
				'other' => q(ddinar n ddzayer),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(uru),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Pound),
				'other' => q(ppaʷndd),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalan Quetzal),
				'other' => q(kwitzal n gwatimala),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduran Lempira),
				'other' => q(lempiras n hondura),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan Dinar),
				'other' => q(ddinar n libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan Dirham),
				'other' => q(derhem),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexican Peso),
				'other' => q(pisus n miksiku),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegian Krone),
				'other' => q(kruna n nnarwij),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Swedish Krona),
				'other' => q(kruna n sswid),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
				'other' => q(ddinar n tunes),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(US Dollar),
				'other' => q(ddular),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ttmenyat),
				'other' => q(ttmneyat),
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
							'yen',
							'feb',
							'mar',
							'yeb',
							'may',
							'yun',
							'yul',
							'ɣuc',
							'cut',
							'kṭu',
							'nuw',
							'duj'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'yennayer',
							'febrayer',
							'mars',
							'yebril',
							'mayyu',
							'yunyu',
							'yulyuz',
							'ɣucct',
							'cutenber',
							'kṭuber',
							'nuwember',
							'dujember'
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
							'y',
							'm',
							'y',
							'y',
							'ɣ',
							'c',
							'k',
							'n',
							'd'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'tɛa.',
							'clɛ.',
							'lmu.',
							'clm.',
							'ja.',
							'jum.',
							'raj.',
							'ceɛ.',
							'are.',
							'cuw.',
							'jer.',
							'lɛi.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tɛacurt',
							'cciɛ lɛacur',
							'lmulud',
							'cciɛ lmulud',
							'jad',
							'jummad',
							'rajeb',
							'ceɛban',
							'aremḍan',
							'cuwwal',
							'jer leɛyud',
							'lɛid ameqran'
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
						mon => 'let',
						tue => 'ttl',
						wed => 'lar',
						thu => 'lex',
						fri => 'jje',
						sat => 'sse',
						sun => 'lḥe'
					},
					short => {
						mon => 'le',
						tue => 'tt',
						wed => 'la',
						thu => 'lx',
						fri => 'jj',
						sat => 'ss',
						sun => 'lḥ'
					},
					wide => {
						mon => 'letnayen',
						tue => 'ttlat',
						wed => 'larbeɛ',
						thu => 'lexmis',
						fri => 'jjemɛa',
						sat => 'ssebt',
						sun => 'lḥed'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'l',
						tue => 't',
						wed => 'l',
						thu => 'l',
						fri => 'j',
						sat => 's',
						sun => 'l'
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
					abbreviated => {0 => 'r1',
						1 => 'r2',
						2 => 'r3',
						3 => 'r4'
					},
					wide => {0 => 'rrbeɛ wis 1',
						1 => 'rrbeɛ wis 2',
						2 => 'rrbeɛ wis 3',
						3 => 'rrbeɛ wis 4'
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
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
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
				'0' => 'zzat i yeccu',
				'1' => 'awarni yeccu'
			},
		},
		'islamic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{dd/MM/y},
		},
		'islamic' => {
			'full' => q{EEEE dd MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd/MM/y GGGGG},
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
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E dd},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E dd MMM y G},
			GyMMMd => q{dd MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E dd/MM},
			MMMEd => q{E dd MMM},
			MMMd => q{dd MMM},
			Md => q{dd/MM},
			d => q{dd},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E dd MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{dd MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E dd},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E dd MMM y G},
			GyMMMd => q{dd MMM y G},
			GyMd => q{dd/MM/y G},
			MEd => q{E dd/MM},
			MMMEd => q{E dd MMM},
			MMMMW => q{'simana' 'wis' W 'zeg' MMMM},
			MMMMd => q{dd MMMM},
			MMMd => q{dd MMM},
			Md => q{dd/MM},
			d => q{dd},
			hm => q{h:mm a},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E dd MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{dd MMM y},
			yMd => q{dd/MM/y},
			yw => q{'simana' 'wis' w 'zeg' Y},
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
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E dd MMM y G – E dd MMM y G},
				M => q{E dd MMM – E dd MMM y G},
				d => q{E dd MMM – E dd MMM y G},
				y => q{E dd MMM y – E dd MMM y G},
			},
			GyMMMd => {
				G => q{dd MMM y G – dd MMM y G},
				M => q{dd MMM – dd MMM y G},
				d => q{dd – dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd MMM – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd – dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{dd – dd},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E dd MMM – E dd MMM y G},
				d => q{E dd MMM – E dd MMM y G},
				y => q{E dd MMM y – E dd MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y G},
				d => q{dd – dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y G – MM/y G},
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			GyMEd => {
				G => q{E dd/MM/y G – E dd/MM/y G},
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E dd MMM y G – E dd MMM y G},
				M => q{E dd MMM – E dd MMM y G},
				d => q{E dd MMM – E dd MMM y G},
				y => q{E dd MMM y – E dd MMM y G},
			},
			GyMMMd => {
				G => q{dd MMM y G – dd MMM y G},
				M => q{dd MMM – dd MMM y G},
				d => q{dd – dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y G – dd/MM/y G},
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd MMM – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd – dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{dd – dd},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E dd MMM – E dd MMM y},
				d => q{E dd MMM – E dd MMM y},
				y => q{E dd MMM y – E dd MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd – dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(akud n {0}),
		regionFormat => q(akud unebdu n {0}),
		regionFormat => q(akud anaway n {0}),
		'Alaska' => {
			long => {
				'daylight' => q#akud n uzil n alaska#,
				'generic' => q#akud n alaska#,
				'standard' => q#akud anaway n alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#akud n uzil n amazun#,
				'generic' => q#akud n amazun#,
				'standard' => q#akud anaway n amazun#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#adak#,
		},
		'America/Aruba' => {
			exemplarCity => q#aruba#,
		},
		'America/Barbados' => {
			exemplarCity => q#barbadus#,
		},
		'America/Cayman' => {
			exemplarCity => q#sayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#cikagu#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#atikukan#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#kustarika#,
		},
		'America/Denver' => {
			exemplarCity => q#dinver#,
		},
		'America/Detroit' => {
			exemplarCity => q#ditruyd#,
		},
		'America/Dominica' => {
			exemplarCity => q#duminika#,
		},
		'America/Godthab' => {
			exemplarCity => q#nuk#,
		},
		'America/Guatemala' => {
			exemplarCity => q#gwatimala#,
		},
		'America/Havana' => {
			exemplarCity => q#havana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#indyanapulis#,
		},
		'America/Panama' => {
			exemplarCity => q#panama#,
		},
		'America/Regina' => {
			exemplarCity => q#rigina#,
		},
		'America/Sitka' => {
			exemplarCity => q#sitka#,
		},
		'America/Yakutat' => {
			exemplarCity => q#yakutat#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#akud n uzil n lwesṭ#,
				'generic' => q#akud n lwesṭ#,
				'standard' => q#akud anaway n lwesṭ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#akud n uzil n lɣerb#,
				'generic' => q#akud n lɣerb#,
				'standard' => q#akud anaway n lɣerb#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#akud n uzil n idurar#,
				'generic' => q#akud n idurar#,
				'standard' => q#akud anaway n idurar#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#akud n uzil n pasifik#,
				'generic' => q#akud n pasifik#,
				'standard' => q#akud anaway n pasifik#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#akud n uzil n arjentina#,
				'generic' => q#akud n arjentina#,
				'standard' => q#akud anaway n arjentina#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#akud n uzil n atlantik#,
				'generic' => q#akud n atlantik#,
				'standard' => q#akud anaway n atlantik#,
			},
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#birmuda#,
		},
		'Bolivia' => {
			long => {
				'standard' => q#akud n bulivya#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#akud n uzil n brazilya#,
				'generic' => q#akud n brazilya#,
				'standard' => q#akud anaway n brazilya#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#akud n uzil n cili#,
				'generic' => q#akud n cili#,
				'standard' => q#akud anaway n cili#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#akud n uzil n kulumbya#,
				'generic' => q#akud n kulumbya#,
				'standard' => q#akud anaway n kulumbya#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#akud n uzil n kuba#,
				'generic' => q#akud n kuba#,
				'standard' => q#akud anaway n kuba#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#akud n ikwadur#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#akud agraɣlan amezday#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#akud n ɣana tafransist#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#GMT#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#akud n uzil n ccerq n grinland#,
				'generic' => q#akud n ccerq n grinland#,
				'standard' => q#akud anaway n ccerq n grinland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#akud n uzil n lwesṭ n grinland#,
				'generic' => q#akud n lwesṭ n grinland#,
				'standard' => q#akud anaway n lwesṭ n grinland#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#akud n guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#akud n uzil n haway-alucyan#,
				'generic' => q#akud n haway-alucyan#,
				'standard' => q#akud anaway n haway-alucyan#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#akud n uzil n sennej i lɣerb n miksiku#,
				'generic' => q#akud n sennej i lɣerb n miksiku#,
				'standard' => q#akud anaway n sennej i lɣerb n miksiku#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#akud n uzil n pasifik amiksikan#,
				'generic' => q#akud n pasifik amiksikan#,
				'standard' => q#akud anaway n pasifik amiksikan#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#akud n yukun#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
