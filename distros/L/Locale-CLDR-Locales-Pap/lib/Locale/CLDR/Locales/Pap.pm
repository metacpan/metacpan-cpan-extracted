=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Pap - Package for language Papiamento

=cut

package Locale::CLDR::Locales::Pap;
# This file auto generated from Data\common\main\pap.xml
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
				'ar' => 'arabir',
 				'ar_001' => 'arabir (mundu)',
 				'de' => 'alemán',
 				'en' => 'ingles',
 				'es' => 'spañó',
 				'es_419' => 'spañó di latino amérika',
 				'fr' => 'franses',
 				'he' => 'hebreo',
 				'hi' => 'hindi',
 				'hmn' => 'hmong',
 				'ht' => 'kreol di Haiti',
 				'hz' => 'herero',
 				'id' => 'indones',
 				'it' => 'italiano',
 				'ja' => 'hapones',
 				'ko' => 'koreano',
 				'la' => 'latin',
 				'nl' => 'hulandes',
 				'pap' => 'Papiamentu',
 				'pl' => 'polaco',
 				'pt' => 'portugues',
 				'ru' => 'ruso',
 				'th' => 'tailandes',
 				'tr' => 'turko',
 				'und' => 'idioma deskonosí',
 				'zh' => 'chines',

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
			'Arab' => 'Arabir',
 			'Brai' => 'braille',
 			'Jpan' => 'hapones',
 			'Kore' => 'koreano',
 			'Latn' => 'Latin',
 			'Zxxx' => 'No Tin Ortografia',
 			'Zzzz' => 'Ortografia Deskonosí',

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
			'001' => 'mundu',
 			'002' => 'Áfrika',
 			'003' => 'Nort Amérika',
 			'005' => 'Zùit Amérika',
 			'011' => 'Wèst Afrika',
 			'013' => 'Amérika Sentral',
 			'014' => 'Ost Afrika',
 			'015' => 'Nort Afrika',
 			'017' => 'Afrika Sentral',
 			'018' => 'Zùit Afrika',
 			'019' => 'Amérika',
 			'021' => 'Parti Nort di Amérika',
 			'029' => 'Karibe',
 			'030' => 'Ost Asia',
 			'034' => 'Zùit Asia',
 			'035' => 'Zùitost Asia',
 			'039' => 'Zùit Europa',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Region di Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Sentral',
 			'145' => 'Wèst Asia',
 			'150' => 'Europa',
 			'151' => 'Ost Europa',
 			'154' => 'Nort Europa',
 			'155' => 'Wèst Europa',
 			'419' => 'Latino Amérika',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua & Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AO' => 'Angola',
 			'AR' => 'Argentina',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'BA' => 'Bosnia i Herzegowina',
 			'BB' => 'Barbados',
 			'BE' => 'Bèlgika',
 			'BG' => 'Bulgaria',
 			'BL' => 'Saint Bathélemy',
 			'BM' => 'Bermuda',
 			'BO' => 'Bolivia',
 			'BQ' => 'Antia Hulandes',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BV' => 'Isla Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CD' => 'Congo - Kinshasa',
 			'CF' => 'Repúblika Sentroafrikano',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Repúblika)',
 			'CH' => 'Suisa',
 			'CI' => 'Côte d’Ivoire',
 			'CL' => 'Chile',
 			'CM' => 'Camerun',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Kabo Verde',
 			'CW' => 'Kòrsou',
 			'CZ' => 'Cheko',
 			'CZ@alt=variant' => 'Repúblika di Cheko',
 			'DE' => 'Alemania',
 			'DK' => 'Dinamarka',
 			'DM' => 'Dominica',
 			'DO' => 'Repúblika Dominikano',
 			'DZ' => 'Algeria',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipto',
 			'EH' => 'Western Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spaña',
 			'ET' => 'Etiopia',
 			'EU' => 'Union Europeo',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiji',
 			'FK' => 'Islanan Falkland',
 			'FK@alt=variant' => 'Islanan Falkland (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FR' => 'Fransia',
 			'GB' => 'Gran Bretaña',
 			'GD' => 'Grenada',
 			'GF' => 'Guyana Franses',
 			'GH' => 'Ghana',
 			'GL' => 'Grunlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea Ekuatorial',
 			'GR' => 'Gresia',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungria',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IN' => 'India',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JM' => 'Jamaica',
 			'JP' => 'Hapon',
 			'KE' => 'Kenya',
 			'KH' => 'Cambodia',
 			'KM' => 'Comóros',
 			'KN' => 'St. Kitts i Nevis',
 			'KP' => 'Nort Korea',
 			'KR' => 'Surkorea',
 			'KY' => 'Islanan Caiman',
 			'LC' => 'Sint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LU' => 'Luxemburg',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'ML' => 'Mali',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao',
 			'MQ' => 'Martinique',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'México',
 			'MZ' => 'Mozambique',
 			'NE' => 'Niger',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Hulanda',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia Franses',
 			'PH' => 'Filipinas',
 			'PL' => 'Polonia',
 			'PM' => 'St. Pierre & Miquelon',
 			'PR' => 'Puerto Rico',
 			'PT' => 'Portugal',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'RO' => 'Romania',
 			'RS' => 'Servia',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Suesia',
 			'SG' => 'Singapore',
 			'SH' => 'Sint Helena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'TC' => 'Turks i Caicos',
 			'TD' => 'Chad',
 			'TH' => 'Tailandia',
 			'TR' => 'Turkia',
 			'TT' => 'Trinidad i Tobago',
 			'TW' => 'Taiwan',
 			'UA' => 'Ukrania',
 			'UG' => 'Uganda',
 			'UN' => 'Nashonnan Uní',
 			'US' => 'Merka',
 			'UY' => 'Uruguay',
 			'VC' => 'Sint Vicent i Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Virgin Islands (Britániko)',
 			'VI' => 'Virgin Islands (Merikano)',
 			'VN' => 'Vietnam',
 			'ZA' => 'Suráfrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Region Deskonosí',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{meter},
 			'UK' => q{britániko},
 			'US' => q{merikano},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Idioma: {0}',
 			'script' => 'Manera di skirbi: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[á é í ó ú]},
			main => qr{[a b c d eè f g h i j k l m nñ oò p q r s t uùü v w x y z]},
			punctuation => qr{[\- ‑ , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ / \& # % ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nort),
						'south' => q({0} suit),
						'west' => q({0} wèst),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nort),
						'south' => q({0} suit),
						'west' => q({0} wèst),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pa {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pa {1}),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nort),
						'south' => q({0} suit),
						'west' => q({0} wèst),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nort),
						'south' => q({0} suit),
						'west' => q({0} wèst),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direkshon),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direkshon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nort),
						'south' => q({0} suit),
						'west' => q({0} wèst),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ost),
						'north' => q({0} nort),
						'south' => q({0} suit),
						'west' => q({0} wèst),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, i {1}),
				2 => q({0} i {1}),
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
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 mion',
					'other' => '0 mion',
				},
				'10000000' => {
					'one' => '00 mion',
					'other' => '00 mion',
				},
				'100000000' => {
					'one' => '000 mion',
					'other' => '000 mion',
				},
				'1000000000' => {
					'one' => '0 bion',
					'other' => '0 bion',
				},
				'10000000000' => {
					'one' => '00 bion',
					'other' => '00 bion',
				},
				'100000000000' => {
					'one' => '000 bion',
					'other' => '000 bion',
				},
				'1000000000000' => {
					'one' => '0 trion',
					'other' => '0 trion',
				},
				'10000000000000' => {
					'one' => '00 trion',
					'other' => '00 trion',
				},
				'100000000000000' => {
					'one' => '000 trion',
					'other' => '000 trion',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0mil',
					'other' => '0mil',
				},
				'10000' => {
					'one' => '00mil',
					'other' => '00mil',
				},
				'100000' => {
					'one' => '000mil',
					'other' => '000mil',
				},
				'1000000' => {
					'one' => '0mion',
					'other' => '0mion',
				},
				'10000000' => {
					'one' => '00mion',
					'other' => '00mion',
				},
				'100000000' => {
					'one' => '000mion',
					'other' => '000mion',
				},
				'1000000000' => {
					'one' => '0bion',
					'other' => '0bion',
				},
				'10000000000' => {
					'one' => '00bion',
					'other' => '00bion',
				},
				'100000000000' => {
					'one' => '000bion',
					'other' => '000bion',
				},
				'1000000000000' => {
					'one' => '0trion',
					'other' => '0trion',
				},
				'10000000000000' => {
					'one' => '00trion',
					'other' => '00trion',
				},
				'100000000000000' => {
					'one' => '000trion',
					'other' => '000trion',
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
		'ANG' => {
			display_name => {
				'currency' => q(Florin),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin di Aruba),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dòler di Bermuda),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dòler di Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dòler kanades),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dòler merikano),
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
							'Yan',
							'Feb',
							'Mar',
							'Apr',
							'Mei',
							'Yün',
							'Yül',
							'Oug',
							'Sèp',
							'Òkt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yanüari',
							'Febrüari',
							'Mart',
							'Aprel',
							'Mei',
							'Yüni',
							'Yüli',
							'Ougùstùs',
							'Sèptèmber',
							'Òktober',
							'Novèmber',
							'Desèmber'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'yan',
							'feb',
							'mar',
							'apr',
							'mei',
							'yün',
							'yül',
							'oug',
							'sèp',
							'òkt',
							'nov',
							'des'
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
					wide => {
						mon => 'djaluna',
						tue => 'djamars',
						wed => 'djarason',
						thu => 'djaweps',
						fri => 'djabièrnè',
						sat => 'djasabra',
						sun => 'djadumingu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'dl',
						tue => 'dm',
						wed => 'dr',
						thu => 'dw',
						fri => 'db',
						sat => 'ds',
						sun => 'dd'
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
					abbreviated => {0 => '1 kuartal',
						1 => '2 kuartal',
						2 => '3 kuartal',
						3 => '4 kuartal'
					},
					wide => {0 => 'di promé kuartal',
						1 => 'di dos kuartal',
						2 => 'di tres kuartal',
						3 => 'di kuanter kuartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1 kuartal',
						1 => '2 kuartal',
						2 => '3 kuartal',
						3 => '4 kuartal'
					},
					wide => {0 => 'di promé kuartal',
						1 => 'di dos kuartal',
						2 => 'di tres kuartal',
						3 => 'di kuanter kuartal'
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
				'0' => 'P.K',
				'1' => 'D.K'
			},
			wide => {
				'0' => 'Promé ku Kristu',
				'1' => 'Despues di Kristu'
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
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd-MM-y},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd-MM-y GGGGG},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM-y GGGGG},
			yyyyMEd => q{E, dd-MM-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd-MM-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E, d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd-MM-y GGGGG},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMW => q{'siman' W 'di' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'siman' w 'di' Y},
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
				y => q{y–y G},
			},
			GyM => {
				G => q{MM-y-GGGGG – MM-y-GGGGG},
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM-y GGGGG – MM-y GGGGG},
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d y MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			yM => {
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y},
				d => q{E, dd-MM-y – E, dd-MM-y},
				y => q{E, dd-MM-y – E, dd-MM-y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(ora di {0}),
		'Africa_Central' => {
			long => {
				'standard' => q#Ora di Áfrika Sentral#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora di Ost Áfrika#,
			},
		},
		'America/Curacao' => {
			exemplarCity => q#Kòrsou#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Repúblka Dominicana#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sint Vincent#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Herúsalèm#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azóres#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kabo Verde#,
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora di Azóres Temporada di Zomer#,
				'generic' => q#Ora di Azóres#,
				'standard' => q#Ora Normal di Azóres#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Deskonosí#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aténas#,
		},
		'Europe/London' => {
			exemplarCity => q#Lònden#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora di Europa Sentral Temporada di Zomer#,
				'generic' => q#Ora di Europa Sentral#,
				'standard' => q#Ora Normal di Europa Sentral#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora di Ost Europa Temporada di Zomer#,
				'generic' => q#Ora di Ost Europa#,
				'standard' => q#Ora Normal di Ost Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora di Wèst Europa Temporada di Zomer#,
				'generic' => q#Ora di Wèst Europa#,
				'standard' => q#Ora Normal di Wèst Europa#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
