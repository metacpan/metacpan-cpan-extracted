=head1

Locale::CLDR::Locales::Om - Package for language Oromo

=cut

package Locale::CLDR::Locales::Om;
# This file auto generated from Data\common\main\om.xml
#	on Fri 29 Apr  7:20:28 pm GMT

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
			main => qr{(?^u:[a b c d e f g h i j k l m n o p q r s t u v w x y z])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
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
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
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
				'wide' => {
					'pm' => q{WB},
					'am' => q{WD},
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
				'0' => 'KD',
				'1' => 'KB'
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
		'generic' => {
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
		},
		'gregorian' => {
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
	 } }
);
no Moo;

1;

# vim: tabstop=4
