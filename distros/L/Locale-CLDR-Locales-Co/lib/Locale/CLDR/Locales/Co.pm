=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Co - Package for language Corsican

=cut

package Locale::CLDR::Locales::Co;
# This file auto generated from Data\common\main\co.xml
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
				'ar' => 'arabu',
 				'ar_001' => 'arabu mudernu',
 				'co' => 'corsu',
 				'cs' => 'ceccu',
 				'da' => 'danese',
 				'de' => 'tedescu',
 				'de_AT' => 'tedescu austriacu',
 				'de_CH' => 'tedescu sguizzeru',
 				'el' => 'grecu',
 				'en' => 'inglese',
 				'en_AU' => 'inglese australianu',
 				'en_CA' => 'inglese canadianu',
 				'en_US' => 'inglese americanu',
 				'en_US@alt=short' => 'inglese (S.U.)',
 				'es' => 'spagnolu',
 				'fi' => 'finlandese',
 				'fr' => 'francese',
 				'fr_CA' => 'francese canadianu',
 				'fr_CH' => 'francese sguizzeru',
 				'hu' => 'ungarese',
 				'id' => 'indunesianu',
 				'it' => 'talianu',
 				'ja' => 'giappunese',
 				'ko' => 'cureanu',
 				'lv' => 'lettone',
 				'mt' => 'maltese',
 				'nl' => 'neerlandese',
 				'nl_BE' => 'fiammingu',
 				'pl' => 'pulunese',
 				'pt' => 'purtughese',
 				'pt_BR' => 'purtughese brasilianu',
 				'pt_PT' => 'purtughese europeanu',
 				'ru' => 'russiu',
 				'sk' => 'sluvaccu',
 				'sl' => 'sluvenu',
 				'sv' => 'svedese',
 				'th' => 'tailandese',
 				'tr' => 'turcu',
 				'und' => 'lingua scunnisciuta',
 				'zh' => 'chinese',
 				'zh@alt=menu' => 'chinese mandarinu',
 				'zh_Hans' => 'chinese simplificatu',
 				'zh_Hans@alt=long' => 'mandarinu simplificatu',
 				'zh_Hant' => 'chinese tradiziunale',
 				'zh_Hant@alt=long' => 'mandarinu tradiziunale',

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
			'Arab' => 'arabu',
 			'Jpan' => 'giappunese',
 			'Kore' => 'cureanu',
 			'Latn' => 'latinu',
 			'Zxxx' => 'micca scrittu',
 			'Zzzz' => 'scrittura scunnisciuta',

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
			'001' => 'Mondu',
 			'002' => 'Africa',
 			'009' => 'Oceania',
 			'019' => 'Americhe',
 			'142' => 'Asia',
 			'150' => 'Europa',
 			'419' => 'America latina',
 			'AQ' => 'Antarticu',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'BE' => 'Belgica',
 			'CA' => 'Canada',
 			'CH' => 'Svizzera',
 			'CN' => 'China',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CZ' => 'Republica cecca',
 			'DE' => 'Alemagna',
 			'DK' => 'Danimarca',
 			'DO' => 'Republica Duminicana',
 			'ES' => 'Spagna',
 			'EU' => 'Unione europea',
 			'FI' => 'Finlandia',
 			'FR' => 'Francia',
 			'GB' => 'Reame Unitu',
 			'GB@alt=short' => 'R.U.',
 			'GR' => 'Grecia',
 			'GT' => 'Guatemala',
 			'HU' => 'Ungheria',
 			'IE' => 'Irlanda',
 			'IL' => 'Israele',
 			'IN' => 'India',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Italia',
 			'JP' => 'Giappone',
 			'LB' => 'Libanu',
 			'LC' => 'Santa Lucia',
 			'MF' => 'San Martinu',
 			'MN' => 'Mungulia',
 			'MQ' => 'Martinica',
 			'MX' => 'Messicu',
 			'MY' => 'Malesia',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederlanda',
 			'NO' => 'Nurvegia',
 			'NZ' => 'Nova Zelanda',
 			'PA' => 'Panama',
 			'PE' => 'Perù',
 			'PH' => 'Filippine',
 			'PS' => 'Palestina',
 			'PT' => 'Portugallu',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'SK' => 'Sluvacchia',
 			'SY' => 'Siria',
 			'TR' => 'Turchia',
 			'UN' => 'Nazioni Unite',
 			'US' => 'Stati Uniti',
 			'US@alt=short' => 'S.U.',
 			'ZZ' => 'regione scunnisciuta',

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
 				'gregorian' => q{calendariu gregurianu},
 				'iso8601' => q{calendariu ISO 8601},
 			},
 			'collation' => {
 				'standard' => q{ordine di classificazione standardizatu},
 			},
 			'numbers' => {
 				'latn' => q{cifri occidentale},
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
			'metric' => q{metricu},
 			'UK' => q{imperiale},
 			'US' => q{americanu},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'lingua : {0}',
 			'script' => 'scrittura : {0}',
 			'region' => 'regione : {0}',

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
			auxiliary => qr{[â æ ç éêë î k ñ ô œ úû w x yÿ]},
			index => ['A', 'B', 'C', '{CHJ}', 'D', 'E', 'F', 'G', '{GHJ}', 'H', 'I', 'J', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', '{SC}', '{SG}', 'T', 'U', 'V', 'Z'],
			main => qr{[aà b c {chj} d eè f g {ghj} h iìï j l m n oò p q r s {sc} {sg} t uùü v z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', '{CHJ}', 'D', 'E', 'F', 'G', '{GHJ}', 'H', 'I', 'J', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', '{SC}', '{SG}', 'T', 'U', 'V', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'word-final' => '{0}…',
		};
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
	default		=> sub { qr'^(?i:iè|i|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:innò|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} è {1}),
				2 => q({0} è {1}),
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
					'default' => '#,##0 %',
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
					'accounting' => {
						'negative' => '(#,##0.00) ¤',
						'positive' => '#,##0.00 ¤',
					},
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
		'CNY' => {
			display_name => {
				'currency' => q(yuan chinese),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(euro),
			},
		},
		'GBP' => {
			symbol => '£GB',
			display_name => {
				'currency' => q(libra sterlina),
				'other' => q(libre sterline),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(rupia indiana),
				'other' => q(rupie indiane),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen giappunese),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublu russiu),
				'other' => q(rubli russii),
			},
		},
		'USD' => {
			symbol => '$US',
		},
		'XXX' => {
			display_name => {
				'currency' => q(muneta scunnisciuta),
				'other' => q(munete scunnisciute),
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
							'ghj.',
							'fer.',
							'mar.',
							'apr.',
							'mag.',
							'ghju.',
							'lug.',
							'aos.',
							'sit.',
							'ott.',
							'nuv.',
							'dic.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'di ghjennaghju',
							'di ferraghju',
							'di marzu',
							'd’aprile',
							'di maghju',
							'di ghjugnu',
							'di lugliu',
							'd’aostu',
							'di sittembre',
							'd’ottobre',
							'di nuvembre',
							'di dicembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'G',
							'F',
							'M',
							'A',
							'M',
							'G',
							'L',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ghjennaghju',
							'ferraghju',
							'marzu',
							'aprile',
							'maghju',
							'ghjugnu',
							'lugliu',
							'aostu',
							'sittembre',
							'ottobre',
							'nuvembre',
							'dicembre'
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
						mon => 'lun.',
						tue => 'mar.',
						wed => 'mer.',
						thu => 'ghj.',
						fri => 'ven.',
						sat => 'sab.',
						sun => 'dum.'
					},
					short => {
						mon => 'lu',
						tue => 'ma',
						wed => 'me',
						thu => 'gh',
						fri => 've',
						sat => 'sa',
						sun => 'du'
					},
					wide => {
						mon => 'luni',
						tue => 'marti',
						wed => 'mercuri',
						thu => 'ghjovi',
						fri => 'venneri',
						sat => 'sabbatu',
						sun => 'dumenica'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'G',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1u trimestru',
						1 => '2u trimestru',
						2 => '3u trimestru',
						3 => '4u trimestru'
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
				'0' => 'nz à C.',
				'1' => 'dp à C.'
			},
			wide => {
				'0' => 'nanzu à Cristu',
				'1' => 'dopu à Cristu'
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
			'full' => q{EEEE d MMMM 'di' 'u' y G},
			'long' => q{d MMMM 'di' 'u' y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM 'di' 'u' y},
			'long' => q{d MMMM 'di' 'u' y},
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
			'full' => q{{1} 'à' {0}},
			'long' => q{{1} 'à' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1} 'à' {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			E => q{E},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y G},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{'settimana' W MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{LLLL 'di' 'u' y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'di' 'u' y},
			yw => q{'settimana' w 'di' 'u' Y},
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
		'gregorian' => {
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
			MEd => {
				M => q{E dd/MM – dd/MM},
				d => q{E dd/MM – dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
			yMMM => {
				M => q{MMM–MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM y – d MMM y},
				d => q{d – d MMM y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(ora : {0}),
		regionFormat => q({0} (ora d’estate)),
		regionFormat => q({0} (ora usuale)),
		'Etc/UTC' => {
			long => {
				'standard' => q#Tempu universale cuurdinatu#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ora mediana di Greenwich#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
