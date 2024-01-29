=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Xh - Package for language Xhosa

=cut

package Locale::CLDR::Locales::Xh;
# This file auto generated from Data\common\main\xh.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
				'af' => 'isiBhulu',
 				'am' => 'Isi-Amharic',
 				'ar' => 'Isi-Arabic',
 				'as' => 'isiAssamese',
 				'az' => 'Isi-Azerbaijani',
 				'be' => 'Isi-Belarusian',
 				'bg' => 'Isi-Bulgaria',
 				'bn' => 'Isi-Bengali',
 				'br' => 'Breton',
 				'bs' => 'Isi-Bosnia',
 				'ca' => 'Isi-Calatan',
 				'cs' => 'Isi-Czech',
 				'cy' => 'Isi-Welsh',
 				'da' => 'Isi-Danish',
 				'de' => 'Isi-German',
 				'el' => 'Isi-Greek',
 				'en' => 'isiNgesi',
 				'eo' => 'Isi-Esperanto',
 				'es' => 'Isi-Spanish',
 				'et' => 'Isi-Estonian',
 				'eu' => 'Isi-Basque',
 				'fa' => 'Isi-Persia',
 				'fi' => 'Isi-Finnish',
 				'fil' => 'Isi-Taglog',
 				'fo' => 'Isi-Faroese',
 				'fr' => 'Isi-French',
 				'fy' => 'Isi-Frisian',
 				'ga' => 'Isi-Irish',
 				'gd' => 'Scots Gaelic',
 				'gl' => 'Isi-Galician',
 				'gn' => 'Guarani',
 				'gu' => 'Isi-Gujarati',
 				'he' => 'Isi-Hebrew',
 				'hi' => 'Isi-Hindi',
 				'hr' => 'Isi-Croatia',
 				'hu' => 'Isi-Hungarian',
 				'hy' => 'isiArmenian',
 				'ia' => 'Interlingua',
 				'id' => 'Isi-Indonesian',
 				'ie' => 'isiInterlingue',
 				'is' => 'Isi-Icelandic',
 				'it' => 'Isi-Italian',
 				'ja' => 'Isi-Japanese',
 				'jv' => 'Isi-Javanese',
 				'ka' => 'Isi-Georgia',
 				'km' => 'isiCambodia',
 				'kn' => 'Isi-Kannada',
 				'ko' => 'Isi-Korean',
 				'ku' => 'Kurdish',
 				'ky' => 'Kyrgyz',
 				'la' => 'Isi-Latin',
 				'ln' => 'Iilwimi',
 				'lo' => 'IsiLoathian',
 				'lt' => 'Isi-Lithuanian',
 				'lv' => 'Isi-Latvian',
 				'mk' => 'Isi-Macedonian',
 				'ml' => 'Isi-Malayalam',
 				'mn' => 'IsiMongolian',
 				'mr' => 'Isi-Marathi',
 				'ms' => 'Isi-Malay',
 				'mt' => 'Isi-Maltese',
 				'ne' => 'Isi-Nepali',
 				'nl' => 'Isi-Dutch',
 				'nn' => 'Isi-Norwegia (Nynorsk)',
 				'no' => 'Isi-Norwegian',
 				'oc' => 'Iso-Occitan',
 				'or' => 'Oriya',
 				'pa' => 'Isi-Punjabi',
 				'pl' => 'Isi-Polish',
 				'ps' => 'Pashto',
 				'pt' => 'Isi-Portuguese',
 				'pt_BR' => 'portokugusseee',
 				'pt_PT' => 'Isi-Portuguese (Portugal)',
 				'ro' => 'Isi-Romanian',
 				'ru' => 'Isi-Russian',
 				'sa' => 'iSanskrit',
 				'sd' => 'isiSindhi',
 				'sh' => 'Serbo-Croatian',
 				'si' => 'Isi-Sinhalese',
 				'sk' => 'Isi-Slovak',
 				'sl' => 'Isi-Slovenian',
 				'so' => 'IsiSomaliya',
 				'sq' => 'Isi-Albania',
 				'sr' => 'Isi-Serbia',
 				'st' => 'Sesotho',
 				'su' => 'Isi-Sudanese',
 				'sv' => 'Isi-Swedish',
 				'sw' => 'Isi-Swahili',
 				'ta' => 'Isi-Tamil',
 				'te' => 'Isi-Telegu',
 				'th' => 'Isi-Thai',
 				'ti' => 'Isi-Tigrinya',
 				'tk' => 'Turkmen',
 				'tlh' => 'Klingon',
 				'tr' => 'Isi-Turkish',
 				'tw' => 'Twi',
 				'ug' => 'Isi Uighur',
 				'uk' => 'Isi-Ukranian',
 				'ur' => 'Urdu',
 				'uz' => 'Isi-Uzbek',
 				'vi' => 'Isi-Vietnamese',
 				'xh' => 'isiXhosa',
 				'yi' => 'Yiddish',
 				'zu' => 'isiZulu',

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
			'MK' => 'uMntla Macedonia',
 			'ZA' => 'eMzantsi Afrika',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
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
	default		=> sub { qr'^(?i:ewe|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hayi|h|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q( ),
			'minusSign' => q(-),
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
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
		'ZAR' => {
			symbol => 'R',
			display_name => {
				'currency' => q(iRandi yaseMzanzi Afrika),
				'one' => q(iRandi YaseMzanzi Afrika),
				'other' => q(iRandi yaseMzanzi Afrika),
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
							'Jan',
							'Feb',
							'Mat',
							'Epr',
							'Mey',
							'Jun',
							'Jul',
							'Aga',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janyuwari',
							'Februwari',
							'Matshi',
							'Epreli',
							'Meyi',
							'Juni',
							'Julayi',
							'Agasti',
							'Septemba',
							'Okthoba',
							'Novemba',
							'Disemba'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan',
							'Feb',
							'Mat',
							'Epr',
							'Mey',
							'Jun',
							'Jul',
							'Aga',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janyuwari',
							'Februwari',
							'Matshi',
							'Epreli',
							'Meyi',
							'Juni',
							'Julayi',
							'Agasti',
							'Septemba',
							'Okthoba',
							'Novemba',
							'Disemba'
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
						mon => 'Mvu',
						tue => 'Bin',
						wed => 'Tha',
						thu => 'Sin',
						fri => 'Hla',
						sat => 'Mgq',
						sun => 'Caw'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Mvulo',
						tue => 'Lwesibini',
						wed => 'Lwesithathu',
						thu => 'Lwesine',
						fri => 'Lwesihlanu',
						sat => 'Mgqibelo',
						sun => 'Cawe'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mvu',
						tue => 'Bin',
						wed => 'Tha',
						thu => 'Sin',
						fri => 'Hla',
						sat => 'Mgq',
						sun => 'Caw'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Mvulo',
						tue => 'Lwesibini',
						wed => 'Lwesithathu',
						thu => 'Lwesine',
						fri => 'Lwesihlanu',
						sat => 'Mgqibelo',
						sun => 'Cawe'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1 unyangantathu',
						1 => '2 unyangantathu',
						2 => '3 unyangantathu',
						3 => '4 unyangantathu'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1 unyangantathu',
						1 => '2 unyangantathu',
						2 => '3 unyangantathu',
						3 => '4 unyangantathu'
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
					'am' => q{AM},
					'pm' => q{PM},
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
		'gregorian' => {
			abbreviated => {
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'BC',
				'1' => 'umnyaka wokuzalwa kukaYesu'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{'week' W 'of' MMMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{'week' w 'of' Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
