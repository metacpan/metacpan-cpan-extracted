=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Rif - Package for language Riffian

=cut

package Locale::CLDR::Locales::Rif;
# This file auto generated from Data\common\main\rif.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
 				'en' => 'taglinzit',
 				'en_GB@alt=short' => 'taglinzit (UK)',
 				'es' => 'taseppanyut',
 				'fr' => 'tafransist',
 				'hi_Latn' => 'tahindawiyt',
 				'id' => 'tayindusiyt',
 				'it' => 'tatayalt',
 				'ja' => 'tajappuniyt',
 				'ko' => 'takuriyt',
 				'nl' => 'tahulandiyt',
 				'nl_BE' => 'taflamant',
 				'pl' => 'tapulandiyt',
 				'pt' => 'tapurtuɣaliyt',
 				'pt_BR' => 'tapurtuɣaliyt (brazil)',
 				'pt_PT' => 'tapurtuɣaliyt (uruppa)',
 				'rif' => 'Tarifit',
 				'ru' => 'tarusiyt',
 				'th' => 'taṭayit',
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
 				'latn' => q{nnumrawat irumiyyen},
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
						'1' => q({0} di {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} di {1}),
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
		decimalFormat => {
			'long' => {
				'1000' => {
					'other' => '0 alaf',
				},
				'10000' => {
					'other' => '00 alaf',
				},
				'100000' => {
					'other' => '000 alaf',
				},
				'1000000' => {
					'other' => '0 melyun',
				},
				'10000000' => {
					'other' => '00 melyun',
				},
				'100000000' => {
					'other' => '000 melyun',
				},
				'1000000000' => {
					'other' => '0 melyar',
				},
				'10000000000' => {
					'other' => '00 melyar',
				},
				'100000000000' => {
					'other' => '000 melyar',
				},
				'1000000000000' => {
					'other' => '0 trilyun',
				},
				'10000000000000' => {
					'other' => '00 trilyun',
				},
				'100000000000000' => {
					'other' => '000 trilyun',
				},
			},
		},
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
		'Africa/Abidjan' => {
			exemplarCity => q#abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#adisababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#ddzayer#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#bamaku#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#bangi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#bisaw#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#blanṭayr#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#brazabil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#lqahira#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#ddarbida#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#sebta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#kunakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#djibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#diwala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#leɛyun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#fritawn#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#gaburun#,
		},
		'Africa/Harare' => {
			exemplarCity => q#harari#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#djuhanasburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#xarṭum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#kincasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#lagus#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#liberbil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#lumi#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#lwanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#lubumbaci#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#malabu#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#maputu#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#maziru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#mbaban#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#mugadicu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#munrubya#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#nayrubi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#njamina#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#nyamiy#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#nwakcuṭ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#wagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#purtunubu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#sawtumi#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ṭarablus#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#tunes#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#binhuwk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#akud n tefriqt n lwesṭ#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#akud n tefriqt n ccerq#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#akud n tefriqt n wadday#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#akud n uzil n tefriqt n lɣerb#,
				'generic' => q#akud n tefriqt n lɣerb#,
				'standard' => q#akud anaway n tefriqt n lɣerb#,
			},
		},
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
		'America/Anchorage' => {
			exemplarCity => q#ancuraj#,
		},
		'America/Anguilla' => {
			exemplarCity => q#angwiya#,
		},
		'America/Antigua' => {
			exemplarCity => q#antigwa#,
		},
		'America/Araguaina' => {
			exemplarCity => q#aragwayna#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#lariyuxa#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#riyugayyigus#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#salṭa#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#sanxwan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#sanluwis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#tutcuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#ucwaya#,
		},
		'America/Aruba' => {
			exemplarCity => q#aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#asuntyun#,
		},
		'America/Bahia' => {
			exemplarCity => q#bahiya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#bayya di bandiras#,
		},
		'America/Barbados' => {
			exemplarCity => q#barbadus#,
		},
		'America/Belem' => {
			exemplarCity => q#bilim#,
		},
		'America/Belize' => {
			exemplarCity => q#biliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#blank-sablun#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#buwabista#,
		},
		'America/Bogota' => {
			exemplarCity => q#buguṭa#,
		},
		'America/Boise' => {
			exemplarCity => q#boysi#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#bwinusayris#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#kambridj bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#campugrandi#,
		},
		'America/Cancun' => {
			exemplarCity => q#kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#kayen#,
		},
		'America/Cayman' => {
			exemplarCity => q#sayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#cikagu#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ciwawa#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#tidad xwaris#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#atikukan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#qurṭuba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#kustarika#,
		},
		'America/Creston' => {
			exemplarCity => q#kristun#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#kiyaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#kuracaw#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#danmarkshaven#,
		},
		'America/Dawson' => {
			exemplarCity => q#dawsun#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#dawsun krik#,
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
		'America/Edmonton' => {
			exemplarCity => q#idmunṭun#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#irunippi#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ssalbadur#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#furt nilsun#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#furṭaliza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#glasbay#,
		},
		'America/Godthab' => {
			exemplarCity => q#nuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#guzbay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#grandṭurk#,
		},
		'America/Grenada' => {
			exemplarCity => q#grinada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#gwadlup#,
		},
		'America/Guatemala' => {
			exemplarCity => q#gwatimala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#gwayakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#hirmusiyyu#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#nux, indyana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#maringu, indyana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#pitersburg, indyana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#tilsiti, indyana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#vivi, indyana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#vinsanz, indyana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#winamak, indyana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#indyanapulis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ikaluwit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#jamayka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#junaw#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#muntitcilu, kinṭaki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#kralendik#,
		},
		'America/La_Paz' => {
			exemplarCity => q#lappaz#,
		},
		'America/Lima' => {
			exemplarCity => q#lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#lusanjlus#,
		},
		'America/Louisville' => {
			exemplarCity => q#lwisvil#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#bariyyu n luwerprans#,
		},
		'America/Maceio' => {
			exemplarCity => q#masiyu#,
		},
		'America/Managua' => {
			exemplarCity => q#mangwa#,
		},
		'America/Manaus' => {
			exemplarCity => q#manaws#,
		},
		'America/Marigot' => {
			exemplarCity => q#mariguṭ#,
		},
		'America/Martinique' => {
			exemplarCity => q#martinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#matamurus#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#minduza#,
		},
		'America/Menominee' => {
			exemplarCity => q#minumini#,
		},
		'America/Merida' => {
			exemplarCity => q#mirida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#mitlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#miksiku siti#,
		},
		'America/Miquelon' => {
			exemplarCity => q#mikilon#,
		},
		'America/Moncton' => {
			exemplarCity => q#muktun#,
		},
		'America/Monterrey' => {
			exemplarCity => q#muntiri#,
		},
		'America/Montevideo' => {
			exemplarCity => q#muntibidyu#,
		},
		'America/Montserrat' => {
			exemplarCity => q#muntsirat#,
		},
		'America/Nassau' => {
			exemplarCity => q#nassaw#,
		},
		'America/New_York' => {
			exemplarCity => q#nyuyurk#,
		},
		'America/Nome' => {
			exemplarCity => q#num#,
		},
		'America/Noronha' => {
			exemplarCity => q#nurunha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#bulah, nurtdakuṭa#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#santer, nurtdakuṭa#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#nyusalem, nurtdakuṭa#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ujinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#panama#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#paramaribu#,
		},
		'America/Phoenix' => {
			exemplarCity => q#finiks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#ppurtuprins#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#ppurtufspin#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#purtubilhu#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ppurturiku#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#puntarinas#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#rankinilit#,
		},
		'America/Recife' => {
			exemplarCity => q#risifi#,
		},
		'America/Regina' => {
			exemplarCity => q#rigina#,
		},
		'America/Resolute' => {
			exemplarCity => q#rizulṭ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#riyubranku#,
		},
		'America/Santarem' => {
			exemplarCity => q#santarim#,
		},
		'America/Santiago' => {
			exemplarCity => q#santyagu#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#santudumingu#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#sawpawlu#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#iṭukurturmit#,
		},
		'America/Sitka' => {
			exemplarCity => q#sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#sanbartilimi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#sanjuns#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#sankits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#sanlucya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#sanṭumas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#sanvinsint#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#swiftkurrent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#tigicigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#tula#,
		},
		'America/Tijuana' => {
			exemplarCity => q#tiywana#,
		},
		'America/Toronto' => {
			exemplarCity => q#ṭurunṭu#,
		},
		'America/Tortola' => {
			exemplarCity => q#ṭurṭula#,
		},
		'America/Vancouver' => {
			exemplarCity => q#fankufer#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#waythurs#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#winippig#,
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
		'Arabian' => {
			long => {
				'daylight' => q#akud n uzil n waɛrab#,
				'generic' => q#akud n waɛrab#,
				'standard' => q#akud anaway n waɛrab#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#lunyabyan#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#akud n uzil n arjentina#,
				'generic' => q#akud n arjentina#,
				'standard' => q#akud anaway n arjentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#akud n uzil n lɣerb n arjentina#,
				'generic' => q#akud n lɣerb n arjentina#,
				'standard' => q#akud anaway n lɣerb n arjentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#akud n uzil n arminya#,
				'generic' => q#akud n arminya#,
				'standard' => q#akud anaway n arminya#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#ɛadan#,
		},
		'Asia/Amman' => {
			exemplarCity => q#ɛamman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#anadic#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#baɣdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#baḥrin#,
		},
		'Asia/Baku' => {
			exemplarCity => q#batci#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#barnul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#bayrut#,
		},
		'Asia/Chita' => {
			exemplarCity => q#cita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#dimacq#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#dubay#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#famagusṭa#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#ɣezza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#lxalil#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#irkutsek#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#lquds#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#kamcatka#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#xandiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#krasnuyarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#kuwit#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#magadan#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#masqaṭ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#nikuzya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#nubukuznitesk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#nubusibiresk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#omsek#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#qaṭar#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#riyad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#saxalin#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#sridnikulimsek#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#tbilisi#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#tumsek#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#ustnira#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#bladibustuk#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#yatutsek#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#yiriban#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#akud n uzil n atlantik#,
				'generic' => q#akud n atlantik#,
				'standard' => q#akud anaway n atlantik#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#azures#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#birmuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#qabubirdi#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#faraw#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#madiyra#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#sawtgyurgya#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#santhilina#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#sṭanli#,
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#akud n uzil n azrabidjan#,
				'generic' => q#akud n azrabidjan#,
				'standard' => q#akud anaway n azrabidjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#akud n uzil n azures#,
				'generic' => q#akud n azures#,
				'standard' => q#akud anaway n azuresn azures#,
			},
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
		'Cape_Verde' => {
			long => {
				'daylight' => q#akud n uzil n qabubirdi#,
				'generic' => q#akud n qabubirdi#,
				'standard' => q#akud anaway n qabubirdi#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#akud n uzil n cili#,
				'generic' => q#akud n cili#,
				'standard' => q#akud anaway n cili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#akud n uzil n tcina#,
				'generic' => q#akud n tcina#,
				'standard' => q#akud anaway n tcina#,
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
		'Easter' => {
			long => {
				'daylight' => q#akud n uzil n isterayland#,
				'generic' => q#akud n isterayland#,
				'standard' => q#akud anaway n isterayland#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#amesterdem#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#andura#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#astraxan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#atina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#bilgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#birlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#bratislaba#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#bruksil#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#buxarist#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#budabist#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#buzingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#cisinaw#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#kuppenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#dablin#,
			long => {
				'daylight' => q#akud anaway ayirlandi#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#jabalṭariq#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#girensiy#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#hilsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#tagzirt n man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#sṭanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#jirsiy#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#kyib#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#kirub#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#licbuna#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#lyubliyana#,
		},
		'Europe/London' => {
			exemplarCity => q#lundun#,
			long => {
				'daylight' => q#akud n uzil n uglinzi#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#lluksemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#madri#,
		},
		'Europe/Malta' => {
			exemplarCity => q#malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#maryaham#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#munaku#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#musku#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#uslu#,
		},
		'Europe/Paris' => {
			exemplarCity => q#pari#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#pudgurisa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#pprag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#ruma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#sanmarinu#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#sarayubu#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#saratub#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#simfarupul#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#skupya#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#sufya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#sṭukhulm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#tiran#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ulyanubesk#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#vaduts#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#lbatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#byinna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#filinyus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#bulgugrad#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#zagreb#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#zyurix#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#akud n uzil n wuruppa n lwesṭ#,
				'generic' => q#akud n wuruppa n lwesṭ#,
				'standard' => q#akud anaway n wuruppa n lwesṭ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#akud n uzil n wuruppa n ccerq#,
				'generic' => q#akud n wuruppa n ccerq#,
				'standard' => q#akud anaway n wuruppa n ccerq#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#akud n wuruppa tacerqect qaɛ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#akud n uzil n wuruppa n lɣerb#,
				'generic' => q#akud n wuruppa n lɣerb#,
				'standard' => q#akud anaway n wuruppa n lɣerb#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#akud n uzil n falkland#,
				'generic' => q#akud n falkland#,
				'standard' => q#akud anaway n falkland#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#akud n ɣana tafransist#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#akud n tiwaddayin tifransisin#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#akud n galappagus#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#akud n uzil n jyurjya#,
				'generic' => q#akud n jyurjya#,
				'standard' => q#akud anaway n jyurjya#,
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
		'Gulf' => {
			long => {
				'standard' => q#akud n lxalij#,
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
		'Hong_Kong' => {
			long => {
				'daylight' => q#akud n uzil n hungkung#,
				'generic' => q#akud n hungkung#,
				'standard' => q#akud anaway n hungkung#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#akud n uzil n hubd#,
				'generic' => q#akud n hubd#,
				'standard' => q#akud anaway n hubd#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#antananaribu#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#ttcagus#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#kumuru#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#kergilan#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#mahi#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#muriṭanya#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#mayuṭ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#riyunyun#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#akud n lebḥer ahindi#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#akud n uzil n yisrayil#,
				'generic' => q#akud n yisrayil#,
				'standard' => q#akud anaway n yisrayil#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#akud n uzil n mawritus#,
				'generic' => q#akud n mawritus#,
				'standard' => q#akud anaway n mawritus#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#akud n uzil n pasifik amiksikan#,
				'generic' => q#akud n pasifik amiksikan#,
				'standard' => q#akud anaway n pasifik amiksikan#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#akud n uzil n nyuw fawemd land#,
				'generic' => q#akud n nyuw fawemd land#,
				'standard' => q#akud anaway n nyuw fawemd land#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#akud n uzil n firnardu dinurunha#,
				'generic' => q#akud n firnardu dinurunha#,
				'standard' => q#akud anaway n firnardu dinurunha#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#ister#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#galapagus#,
		},
		'Paraguay' => {
			long => {
				'daylight' => q#akud n uzil n pparagway#,
				'generic' => q#akud n pparagway#,
				'standard' => q#akud anaway n pparagway#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#akud n uzil n ppiru#,
				'generic' => q#akud n ppiru#,
				'standard' => q#akud anaway n ppiru#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#akud n uzil n sant-pyiɣ d mikilun#,
				'generic' => q#akud n sant-pyiɣ d mikilun#,
				'standard' => q#akud anaway n sant-pyiɣ d mikilun#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#akud n riyunyun#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#akud n saycal#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#akud n jyurjya n wadday#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#akud n surinam#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#akud n uzil n urugway#,
				'generic' => q#akud n urugway#,
				'standard' => q#akud anaway n urugway#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#akud n vinzwila#,
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
