=encoding utf8

=head1

Locale::CLDR::Locales::Haw - Package for language Hawaiian

=cut

package Locale::CLDR::Locales::Haw;
# This file auto generated from Data\common\main\haw.xml
#	on Sun  3 Feb  1:54:25 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
				'ar' => 'ʻAlapia',
 				'cy' => 'Wale',
 				'da' => 'Kenemaka',
 				'de' => 'Kelemānia',
 				'el' => 'Helene',
 				'en' => 'Pelekānia',
 				'en_AU' => 'Pelekāne Nū Hōlani',
 				'en_CA' => 'Pelekāne Kanakā',
 				'en_GB' => 'Pelekānia Pekekāne',
 				'en_US' => 'Pelekānia ʻAmelika',
 				'es' => 'Paniolo',
 				'fj' => 'Pīkī',
 				'fr' => 'Palani',
 				'fr_CA' => 'Palani Kanakā',
 				'fr_CH' => 'Kuikilani',
 				'ga' => 'ʻAiliki',
 				'gsw' => 'Kuikilani Kelemānia',
 				'haw' => 'ʻŌlelo Hawaiʻi',
 				'he' => 'Hebera',
 				'it' => 'ʻĪkālia',
 				'ja' => 'Kepanī',
 				'ko' => 'Kōlea',
 				'la' => 'Lākina',
 				'mi' => 'Māori',
 				'nl' => 'Hōlani',
 				'pt' => 'Pukikī',
 				'pt_BR' => 'Pukikī Palakila',
 				'ru' => 'Lūkia',
 				'sm' => 'Kāmoa',
 				'sv' => 'Kuekene',
 				'to' => 'Tonga',
 				'ty' => 'Polapola',
 				'und' => 'ʻIke ʻole ‘ia a kūpono ʻole paha ka ʻōlelo',
 				'vi' => 'Wiekanama',
 				'zh' => 'Pākē',
 				'zh_Hans' => 'Pākē Hoʻomaʻalahi ʻia',
 				'zh_Hant' => 'Pākē Kuʻuna',

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
			'AU' => 'Nūhōlani',
 			'CA' => 'Kanakā',
 			'CN' => 'Kina',
 			'DE' => 'Kelemānia',
 			'DK' => 'Kenemaka',
 			'ES' => 'Kepania',
 			'FR' => 'Palani',
 			'GB' => 'Aupuni Mōʻī Hui Pū ʻIa',
 			'GR' => 'Helene',
 			'IE' => 'ʻIlelani',
 			'IL' => 'ʻIseraʻela',
 			'IN' => 'ʻĪnia',
 			'IT' => 'ʻĪkālia',
 			'JP' => 'Iāpana',
 			'MX' => 'Mekiko',
 			'NL' => 'Hōlani',
 			'NZ' => 'Aotearoa',
 			'PH' => 'ʻĀina Pilipino',
 			'RU' => 'Lūkia',
 			'US' => 'ʻAmelika Hui Pū ʻIa',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{Mekalika},
 			'US' => q{ʻAmelika Hui Pū ʻIa},

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
			auxiliary => qr{[b c d f g j q r s t v x y z]},
			index => ['A', 'E', 'I', 'O', 'U', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'ʻ', 'X', 'Y', 'Z'],
			main => qr{[a ā e ē i ī o ō u ū h k l m n p w ʻ]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'E', 'I', 'O', 'U', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'ʻ', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(lā),
						'one' => q({0} lā),
						'other' => q({0} lā),
					},
					'hour' => {
						'name' => q(hola),
						'one' => q({0} hola),
						'other' => q({0} hola),
					},
					'minute' => {
						'name' => q(minuke),
						'one' => q({0} minuke),
						'other' => q({0} minuke),
					},
					'month' => {
						'name' => q(mahina),
						'one' => q({0} mahina),
						'other' => q({0} mahina),
					},
					'second' => {
						'name' => q(kekona),
						'one' => q({0} kekona),
						'other' => q({0} kekona),
					},
					'week' => {
						'name' => q(pule),
						'one' => q({0} pule),
						'other' => q({0} pule),
					},
					'year' => {
						'name' => q(makahiki),
						'one' => q({0} makahiki),
						'other' => q({0} makahiki),
					},
				},
				'narrow' => {
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
				'short' => {
					'day' => {
						'name' => q(lā),
					},
					'hour' => {
						'name' => q(hola),
					},
					'minute' => {
						'name' => q(minuke),
					},
					'month' => {
						'name' => q(mahina),
					},
					'second' => {
						'name' => q(kekona),
					},
					'week' => {
						'name' => q(pule),
					},
					'year' => {
						'name' => q(makahiki),
					},
				},
			} }
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
		'USD' => {
			symbol => '$',
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
							'Ian.',
							'Pep.',
							'Mal.',
							'ʻAp.',
							'Mei',
							'Iun.',
							'Iul.',
							'ʻAu.',
							'Kep.',
							'ʻOk.',
							'Now.',
							'Kek.'
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
							'Ianuali',
							'Pepeluali',
							'Malaki',
							'ʻApelila',
							'Mei',
							'Iune',
							'Iulai',
							'ʻAukake',
							'Kepakemapa',
							'ʻOkakopa',
							'Nowemapa',
							'Kekemapa'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ian.',
							'Pep.',
							'Mal.',
							'ʻAp.',
							'Mei',
							'Iun.',
							'Iul.',
							'ʻAu.',
							'Kep.',
							'ʻOk.',
							'Now.',
							'Kek.'
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
							'Ianuali',
							'Pepeluali',
							'Malaki',
							'ʻApelila',
							'Mei',
							'Iune',
							'Iulai',
							'ʻAukake',
							'Kepakemapa',
							'ʻOkakopa',
							'Nowemapa',
							'Kekemapa'
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
						mon => 'P1',
						tue => 'P2',
						wed => 'P3',
						thu => 'P4',
						fri => 'P5',
						sat => 'P6',
						sun => 'LP'
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
						mon => 'P1',
						tue => 'P2',
						wed => 'P3',
						thu => 'P4',
						fri => 'P5',
						sat => 'P6',
						sun => 'LP'
					},
					wide => {
						mon => 'Poʻakahi',
						tue => 'Poʻalua',
						wed => 'Poʻakolu',
						thu => 'Poʻahā',
						fri => 'Poʻalima',
						sat => 'Poʻaono',
						sun => 'Lāpule'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'P1',
						tue => 'P2',
						wed => 'P3',
						thu => 'P4',
						fri => 'P5',
						sat => 'P6',
						sun => 'LP'
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
						mon => 'P1',
						tue => 'P2',
						wed => 'P3',
						thu => 'P4',
						fri => 'P5',
						sat => 'P6',
						sun => 'LP'
					},
					wide => {
						mon => 'Poʻakahi',
						tue => 'Poʻalua',
						wed => 'Poʻakolu',
						thu => 'Poʻahā',
						fri => 'Poʻalima',
						sat => 'Poʻaono',
						sun => 'Lāpule'
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
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'wide' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
				'narrow' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
				'abbreviated' => {
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'BCE',
				'1' => 'CE'
			},
			wide => {
				'0' => 'BCE',
				'1' => 'CE'
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
			'short' => q{d/M/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'week' W 'of' MMM},
			MMMMd => q{MMMM d},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{y MMMM},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Alaska' => {
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
