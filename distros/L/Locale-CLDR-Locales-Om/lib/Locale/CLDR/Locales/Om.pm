=encoding utf8

=head1

Locale::CLDR::Locales::Om - Package for language Oromo

=cut

package Locale::CLDR::Locales::Om;
# This file auto generated from Data/common/main/om.xml
#	on Mon 11 Apr  5:35:55 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
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

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
					'accounting' => {
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
					short => {
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
					abbreviated => {
						mon => 'Wix',
						tue => 'Qib',
						wed => 'Rob',
						thu => 'Kam',
						fri => 'Jim',
						sat => 'San',
						sun => 'Dil'
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
					short => {
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Kurmaana 1',
						1 => 'Kurmaana 2',
						2 => 'Kurmaana 3',
						3 => 'Kurmaana 4'
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
				'wide' => {
					'am' => q{WD},
					'pm' => q{WB},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{WD},
					'pm' => q{WB},
				},
				'narrow' => {
					'am' => q{WD},
					'pm' => q{WB},
				},
				'wide' => {
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
			abbreviated => {
				'0' => 'BCE',
				'1' => 'CE'
			},
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
			MMMMW => q{'week' W 'of' MMM},
			MMMMd => q{MMMM d},
			MMMMdd => q{dd MMMM},
			MMMd => q{MMM d},
			MMdd => q{dd/MM},
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
			yMM => q{MM/y},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{MMMM y},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQ y},
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
