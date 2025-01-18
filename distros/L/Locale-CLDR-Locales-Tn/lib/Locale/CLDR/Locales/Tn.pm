=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tn - Package for language Tswana

=cut

package Locale::CLDR::Locales::Tn;
# This file auto generated from Data\common\main\tn.xml
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
				'af' => 'Seburu',
 				'am' => 'Amhariki',
 				'ar' => 'Arabic',
 				'az' => 'Azerbaijani',
 				'be' => 'Belarusian',
 				'bg' => 'Bulgarian',
 				'bn' => 'Bengali',
 				'bs' => 'SeBosnia',
 				'ca' => 'Catalan',
 				'cs' => 'Se Czeck',
 				'cy' => 'Welsh',
 				'da' => 'Danish',
 				'de' => 'German',
 				'el' => 'SeGerika',
 				'en' => 'Sekgoa',
 				'eo' => 'Esperanto',
 				'es' => 'Spanish',
 				'et' => 'Estonian',
 				'eu' => 'Basque',
 				'fa' => 'Mo/SePerishia',
 				'fi' => 'Se-Finland',
 				'fil' => 'Tagalog',
 				'fo' => 'Faroese',
 				'fr' => 'Se Fora',
 				'fy' => 'Frisian',
 				'ga' => 'Irish',
 				'gd' => 'Scots Gaelic',
 				'gl' => 'Galician',
 				'gu' => 'Gujarati',
 				'he' => 'Se heberu',
 				'hi' => 'Hindi',
 				'hr' => 'Croatian',
 				'hu' => 'Hungarian',
 				'ia' => 'Interlingua',
 				'id' => 'Indonesian',
 				'is' => 'Icelandic',
 				'it' => 'Se Italiano',
 				'ja' => 'Se Japan',
 				'jv' => 'Javanese',
 				'ka' => 'Mo/SeJojia',
 				'kn' => 'Kannada',
 				'ko' => 'Se Korea',
 				'la' => 'Latin',
 				'lt' => 'Lithuanian',
 				'lv' => 'Latvian',
 				'mk' => 'Macedonian',
 				'ml' => 'Malayalam',
 				'mr' => 'Marathi',
 				'ms' => 'Malay',
 				'mt' => 'Maltese',
 				'ne' => 'Nepali',
 				'nl' => 'Se Dutch',
 				'no' => 'Puo ya kwa Norway',
 				'oc' => 'Occitan',
 				'pa' => 'Punjabi',
 				'pl' => 'Se Poland',
 				'pt' => 'Se Potoketsi',
 				'ro' => 'Se Roma',
 				'ru' => 'Russian',
 				'sk' => 'Slovak',
 				'sl' => 'Slovenian',
 				'sq' => 'Albanian',
 				'sr' => 'Serbian',
 				'su' => 'Mo/SeSundane',
 				'sv' => 'Swedish',
 				'sw' => 'Swahili',
 				'ta' => 'Tamil',
 				'te' => 'Telugu',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tlh' => 'Klingon',
 				'tn' => 'Setswana',
 				'tr' => 'Turkish',
 				'uk' => 'Ukrainian',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vi' => 'Vietnamese',
 				'xh' => 'IsiXhosa',
 				'zu' => 'IsiZulu',

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
			'Latn' => 'Selatine',

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
			'BW' => 'Botswana',
 			'ZA' => 'Aforika Borwa',

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
			auxiliary => qr{[c q v x z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b d e ê f g h i j k l m n o ô p r s t u w y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'group' => q(’),
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
							'Fer',
							'Tlh',
							'Mop',
							'Mor',
							'Mot',
							'See',
							'Phu',
							'Pha',
							'Lwe',
							'Dip',
							'Ngw',
							'Sed'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ferikgong',
							'Tlhakole',
							'Mopitlo',
							'Moranang',
							'Motsheganang',
							'Seetebosigo',
							'Phukwi',
							'Phatwe',
							'Lwetse',
							'Diphalane',
							'Ngwanatsele',
							'Sedimonthole'
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
						mon => 'Mos',
						tue => 'Labb',
						wed => 'Labr',
						thu => 'Labn',
						fri => 'Labt',
						sat => 'Mat',
						sun => 'Tsh'
					},
					wide => {
						mon => 'Mosupologo',
						tue => 'Labobedi',
						wed => 'Laboraro',
						thu => 'Labone',
						fri => 'Labotlhano',
						sat => 'Matlhatso',
						sun => 'Tshipi'
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
					wide => {0 => 'Sephatlho sa ntlha sa ngwaga',
						1 => 'Sephatlho sa bobedi',
						2 => 'Sephatlho sa boraro',
						3 => 'Sephatlho sa bone'
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
		'gregorian' => {
			abbreviated => {
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Pele ga tsalo ya Morena Jeso',
				'1' => 'Morago ga Leso la Morena Jeso'
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
			'full' => q{{1} 'ka' {0}},
			'long' => q{{1} 'ka' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			MMMMW => q{'beke' 'ya' W 'ya' MMM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yw => q{'beke' w 'ya' Y},
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
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'GMT' => {
			long => {
				'standard' => q#Palogare ya nako ya ngwaga le ngwaga ya Greenwich#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
