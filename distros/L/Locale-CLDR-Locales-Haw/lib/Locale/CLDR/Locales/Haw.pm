=head1

Locale::CLDR::Locales::Haw - Package for language Hawaiian

=cut

package Locale::CLDR::Locales::Haw;
# This file auto generated from Data\common\main\haw.xml
#	on Fri 29 Apr  7:06:41 pm GMT

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
			auxiliary => qr{(?^u:[b c d f g j q r s t v x y z])},
			index => ['A', 'E', 'I', 'O', 'U', 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'ʻ', 'X', 'Y', 'Z'],
			main => qr{(?^u:[a ā e ē i ī o ō u ū h k l m n p w ʻ])},
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

has 'eras' => (
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
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
		'Alaska' => {
			short => {
				'daylight' => q(AKDT),
				'generic' => q(AKT),
				'standard' => q(AKST),
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q(HADT),
				'generic' => q(HAT),
				'standard' => q(HAST),
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q(HDT),
				'generic' => q(HST),
				'standard' => q(HST),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
