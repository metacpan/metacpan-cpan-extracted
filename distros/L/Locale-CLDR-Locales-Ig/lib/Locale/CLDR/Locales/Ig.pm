=head1

Locale::CLDR::Locales::Ig - Package for language Igbo

=cut

package Locale::CLDR::Locales::Ig;
# This file auto generated from Data\common\main\ig.xml
#	on Fri 29 Apr  7:09:36 pm GMT

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
				'ak' => 'Akan',
 				'am' => 'Amariikị',
 				'ar' => 'Arabiikị',
 				'be' => 'Belaruusu',
 				'bg' => 'Bọlụgarịa',
 				'bn' => 'Bengali',
 				'cs' => 'Cheekị',
 				'de' => 'Jamaan',
 				'el' => 'Giriikị',
 				'en' => 'Oyibo',
 				'es' => 'Panya',
 				'fa' => 'Peshan',
 				'fr' => 'Fụrench',
 				'ha' => 'Awụsa',
 				'hi' => 'Hindi',
 				'hu' => 'Magịya',
 				'id' => 'Indonisia',
 				'ig' => 'Igbo',
 				'it' => 'Italo',
 				'ja' => 'Japanese',
 				'jv' => 'Java',
 				'km' => 'Keme, Etiti',
 				'ko' => 'Koria',
 				'ms' => 'Maleyi',
 				'my' => 'Mịanma',
 				'ne' => 'Nepali',
 				'nl' => 'Dọọch',
 				'pa' => 'Punjabi',
 				'pl' => 'Poliishi',
 				'pt' => 'Potoki',
 				'ro' => 'Rumenia',
 				'ru' => 'Rọshan',
 				'rw' => 'Rụwanda',
 				'so' => 'Somali',
 				'sv' => 'Sụwidiishi',
 				'ta' => 'Tamụlụ',
 				'th' => 'Taị',
 				'tr' => 'Tọkiishi',
 				'uk' => 'Ukureenị',
 				'ur' => 'Urudu',
 				'vi' => 'Viyetịnaamụ',
 				'yo' => 'Yoruba',
 				'zh' => 'Mandarịịnị',
 				'zu' => 'Zulu',

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
			'BJ' => 'Binin',
 			'BM' => 'Bemuda',
 			'CN' => 'Chaina',
 			'HT' => 'Hati',
 			'KM' => 'Comorosu',
 			'LY' => 'Libyia',
 			'MV' => 'Maldivesa',
 			'NG' => 'Nigeria',

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
			main => qr{(?^u:[a b {ch} d e ẹ f g {gb} {gh} {gw} h i ị j k {kp} {kw} l m n ṅ {nw} {ny} o ọ p r s {sh} t u ụ v w y z])},
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
	default		=> sub { qr'^(?i:Eye|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Mba|M|no|n)$' }
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
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
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Caboverdiano),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Naịra),
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
							'Jen',
							'Feb',
							'Maa',
							'Epr',
							'Mee',
							'Juu',
							'Jul',
							'Ọgọ',
							'Sep',
							'Ọkt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenụwarị',
							'Febrụwarị',
							'Maachị',
							'Eprel',
							'Mee',
							'Juun',
							'Julaị',
							'Ọgọọst',
							'Septemba',
							'Ọktoba',
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
						mon => 'Mọn',
						tue => 'Tiu',
						wed => 'Wen',
						thu => 'Tọọ',
						fri => 'Fraị',
						sat => 'Sat',
						sun => 'Ụka'
					},
					wide => {
						mon => 'Mọnde',
						tue => 'Tiuzdee',
						wed => 'Wenezdee',
						thu => 'Tọọzdee',
						fri => 'Fraịdee',
						sat => 'Satọdee',
						sun => 'Mbọsị Ụka'
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
					abbreviated => {0 => 'Ọ1',
						1 => 'Ọ2',
						2 => 'Ọ3',
						3 => 'Ọ4'
					},
					wide => {0 => 'Ọkara 1',
						1 => 'Ọkara 2',
						2 => 'Ọkara 3',
						3 => 'Ọkara 4'
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
					'pm' => q{P.M.},
					'am' => q{A.M.},
				},
				'abbreviated' => {
					'pm' => q{P.M.},
					'am' => q{A.M.},
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
				'0' => 'T.K.',
				'1' => 'A.K.'
			},
			wide => {
				'0' => 'Tupu Kristi',
				'1' => 'Afọ Kristi'
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
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
