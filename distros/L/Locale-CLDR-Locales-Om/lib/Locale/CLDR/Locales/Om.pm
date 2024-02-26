=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Om - Package for language Oromo

=cut

package Locale::CLDR::Locales::Om;
# This file auto generated from Data\common\main\om.xml
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
				'af' => 'Afrikoota',
 				'am' => 'Afaan Sidaamaa',
 				'ar' => 'Arabiffaa',
 				'az' => 'Afaan Azerbaijani',
 				'be' => 'Afaan Belarusia',
 				'bg' => 'Afaan Bulgariya',
 				'bn' => 'Afaan Baangladeshi',
 				'bs' => 'Afaan Bosniyaa',
 				'ca' => 'Afaan Katalaa',
 				'cs' => 'Afaan Czech',
 				'cy' => 'Welishiffaa',
 				'da' => 'Afaan Deenmaark',
 				'de' => 'Afaan Jarmanii',
 				'el' => 'Afaan Giriiki',
 				'en' => 'Ingliffa',
 				'eo' => 'Afaan Esperantoo',
 				'es' => 'Afaan Ispeen',
 				'et' => 'Afaan Istooniya',
 				'eu' => 'Afaan Baskuu',
 				'fa' => 'Afaan Persia',
 				'fi' => 'Afaan Fiilaandi',
 				'fil' => 'Afaan Filippinii',
 				'fo' => 'Afaan Faroese',
 				'fr' => 'Afaan Faransaayii',
 				'fy' => 'Afaan Firisiyaani',
 				'ga' => 'Afaan Ayirishii',
 				'gd' => 'Scots Gaelic',
 				'gl' => 'Afaan Galishii',
 				'gn' => 'Afaan Guarani',
 				'gu' => 'Afaan Gujarati',
 				'he' => 'Afaan Hebrew',
 				'hi' => 'Afaan Hindii',
 				'hr' => 'Afaan Croatian',
 				'hu' => 'Afaan Hangaari',
 				'ia' => 'Interlingua',
 				'id' => 'Afaan Indoneziya',
 				'is' => 'Ayiislandiffaa',
 				'it' => 'Afaan Xaaliyaani',
 				'ja' => 'Afaan Japanii',
 				'jv' => 'Afaan Java',
 				'ka' => 'Afaan Georgian',
 				'kn' => 'Afaan Kannada',
 				'ko' => 'Afaan Korea',
 				'la' => 'Afaan Laatini',
 				'lt' => 'Afaan Liituniyaa',
 				'lv' => 'Afaan Lativiyaa',
 				'mk' => 'Afaan Macedooniyaa',
 				'ml' => 'Malayaalamiffaa',
 				'mr' => 'Afaan Maratii',
 				'ms' => 'Malaayiffaa',
 				'mt' => 'Afaan Maltesii',
 				'ne' => 'Afaan Nepalii',
 				'nl' => 'Afaan Dachii',
 				'nn' => 'Afaan Norwegian',
 				'no' => 'Afaan Norweyii',
 				'oc' => 'Afaan Occit',
 				'om' => 'Oromoo',
 				'pa' => 'Afaan Punjabii',
 				'pl' => 'Afaan Polandii',
 				'pt' => 'Afaan Porchugaal',
 				'pt_BR' => 'Afaan Portugali (Braazil)',
 				'pt_PT' => 'Afaan Protuguese',
 				'ro' => 'Afaan Romaniyaa',
 				'ru' => 'Afaan Rushiyaa',
 				'si' => 'Afaan Sinhalese',
 				'sk' => 'Afaan Slovak',
 				'sl' => 'Afaan Islovaniyaa',
 				'sq' => 'Afaan Albaniyaa',
 				'sr' => 'Afaan Serbiya',
 				'su' => 'Afaan Sudaanii',
 				'sv' => 'Afaan Suwidiin',
 				'sw' => 'Suwahilii',
 				'ta' => 'Afaan Tamilii',
 				'te' => 'Afaan Telugu',
 				'th' => 'Afaan Tayii',
 				'ti' => 'Afaan Tigiree',
 				'tk' => 'Lammii Turkii',
 				'tlh' => 'Afaan Kilingon',
 				'tr' => 'Afaan Turkii',
 				'uk' => 'Afaan Ukreenii',
 				'ur' => 'Afaan Urdu',
 				'uz' => 'Afaan Uzbek',
 				'vi' => 'Afaan Veetinam',
 				'xh' => 'Afaan Xhosa',
 				'zh' => 'Chinese',
 				'zu' => 'Afaan Zuulu',

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
			'Latn' => 'Latin',

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
			'BR' => 'Brazil',
 			'CN' => 'China',
 			'DE' => 'Germany',
 			'ET' => 'Itoophiyaa',
 			'FR' => 'France',
 			'GB' => 'United Kingdom',
 			'IN' => 'India',
 			'IT' => 'Italy',
 			'JP' => 'Japan',
 			'KE' => 'Keeniyaa',
 			'RU' => 'Russia',
 			'US' => 'United States',

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


has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'ethi',
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
		'BRL' => {
			display_name => {
				'currency' => q(Brazilian Real),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese Yuan Renminbi),
			},
		},
		'ETB' => {
			symbol => 'Br',
			display_name => {
				'currency' => q(Itoophiyaa Birrii),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Pound),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indian Rupee),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanese Yen),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian Ruble),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(US Dollar),
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
							'Ama',
							'Gur',
							'Bit',
							'Elb',
							'Cam',
							'Wax',
							'Ado',
							'Hag',
							'Ful',
							'Onk',
							'Sad',
							'Mud'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Amajjii',
							'Guraandhala',
							'Bitooteessa',
							'Elba',
							'Caamsa',
							'Waxabajjii',
							'Adooleessa',
							'Hagayya',
							'Fuulbana',
							'Onkololeessa',
							'Sadaasa',
							'Muddee'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
						mon => 'Wix',
						tue => 'Qib',
						wed => 'Rob',
						thu => 'Kam',
						fri => 'Jim',
						sat => 'San',
						sun => 'Dil'
					},
					wide => {
						mon => 'Wiixata',
						tue => 'Qibxata',
						wed => 'Roobii',
						thu => 'Kamiisa',
						fri => 'Jimaata',
						sat => 'Sanbata',
						sun => 'Dilbata'
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
					wide => {0 => 'Kurmaana 1',
						1 => 'Kurmaana 2',
						2 => 'Kurmaana 3',
						3 => 'Kurmaana 4'
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
					'am' => q{WD},
					'pm' => q{WB},
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
			wide => {
				'0' => 'Dheengadda Jeesu'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{dd MMMM y},
			'medium' => q{dd-MMM-y},
			'short' => q{dd/MM/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
		},
		'gregorian' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
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

no Moo;

1;

# vim: tabstop=4
