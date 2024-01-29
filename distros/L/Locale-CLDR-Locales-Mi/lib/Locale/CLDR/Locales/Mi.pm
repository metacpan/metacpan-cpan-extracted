=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mi - Package for language Māori

=cut

package Locale::CLDR::Locales::Mi;
# This file auto generated from Data\common\main\mi.xml
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
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'de' => 'Tiamana',
 				'de_AT' => 'Tiamana Atiria',
 				'de_CH' => 'Tiamana Ōkawa Huiterangi',
 				'en' => 'Ingarihi',
 				'en_AU' => 'Ingarihi Ahitereiriana',
 				'en_CA' => 'Ingarihi Kānata',
 				'en_GB' => 'Ingarihi Piritene',
 				'en_GB@alt=short' => 'Ingarihi UK',
 				'en_US' => 'Ingarihi Amerikana',
 				'en_US@alt=short' => 'Ingarihi US',
 				'es' => 'Paniora',
 				'es_419' => 'Paniora Amerika ki te Tonga',
 				'es_ES' => 'Paniora Uropi',
 				'es_MX' => 'Paniora Mēhikana',
 				'fr' => 'Wīwī',
 				'fr_CA' => 'Wīwī Kānata',
 				'fr_CH' => 'Wīwī Huiterangi',
 				'it' => 'Ītariana',
 				'ja' => 'Hapanihi',
 				'mi' => 'te reo Māori',
 				'pt' => 'Pōtukīhi',
 				'pt_BR' => 'Pōtukīhi Parahi',
 				'pt_PT' => 'Pōtukīhi Uropi',
 				'ru' => 'Ruhiana',
 				'und' => 'Reo Tē Mōhiotia',
 				'zh' => 'Hainamana',
 				'zh@alt=menu' => 'Hainamana Manarini',
 				'zh_Hans' => 'Hainamana Māmā',
 				'zh_Hant' => 'Hainamana Tukuiho',

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
			'Arab' => 'Arapika',
 			'Cyrl' => 'Hīririki',
 			'Hans' => 'Māmā',
 			'Hans@alt=stand-alone' => 'Hana Māmā',
 			'Hant' => 'Tukuiho',
 			'Hant@alt=stand-alone' => 'Hana Tukuiho',
 			'Latn' => 'Rātina',
 			'Zxxx' => 'Tuhikore',
 			'Zzzz' => 'Momotuhi Tē Mōhiotia',

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
			'BR' => 'Parahi',
 			'CN' => 'Haina',
 			'DE' => 'Tiamana',
 			'FR' => 'Wīwī',
 			'GB' => 'Hononga o Piritene',
 			'IN' => 'Inia',
 			'IT' => 'Itāria',
 			'JP' => 'Hapani',
 			'MK' => 'Makerōnia ki te Raki',
 			'NZ' => 'Aotearoa',
 			'RU' => 'Rūhia',
 			'US' => 'Hononga o Amerika',
 			'ZZ' => 'Rohe Tē Mōhiotia',

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
 				'gregorian' => q{Maramataka Pākehā},
 			},
 			'collation' => {
 				'standard' => q{Raupapa Kōmaka Arowhānui},
 			},
 			'numbers' => {
 				'latn' => q{Ngā Mati Pākehā},
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
			'metric' => q{Ngahuru},
 			'UK' => q{UK},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Reo: {0}',
 			'script' => 'Momotuhi: {0}',
 			'region' => 'Rohe: {0}',

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
			auxiliary => qr{[b c d f g j l q s v x y z]},
			index => ['A', 'E', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'R', 'T', 'U', 'W'],
			main => qr{[a ā e ē h i ī k m n {ng} o ō p r t u ū w {wh}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'E', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'R', 'T', 'U', 'W'], };
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

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:āe|ā|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:kāo|k|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
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
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
				'currency' => q(Real Parahi),
				'other' => q(real Parahi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Haina),
				'other' => q(yuan Haina),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pāuna Piritene),
				'other' => q(pāuna Piritene),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupī Iniana),
				'other' => q(rupī Iniana),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen Hapanihi),
				'other' => q(yen Hapanihi),
			},
		},
		'NZD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Tāra o Aotearoa),
				'other' => q(tāra o Aotearoa),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rūpera Ruhiana),
				'other' => q(rūpera Ruhiana),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Tāra US),
				'other' => q(tāra US),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Moni Tē Mōhiotia),
				'other' => q(\(moni tē mōhiotia\)),
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
							'Kohi',
							'Hui',
							'Pou',
							'Pae',
							'Hara',
							'Pipi',
							'Hōngo',
							'Here',
							'Mahu',
							'Nuku',
							'Rangi',
							'Haki'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'K',
							'H',
							'P',
							'P',
							'H',
							'P',
							'H',
							'H',
							'M',
							'N',
							'R',
							'H'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Kohitātea',
							'Huitanguru',
							'Poutūterangi',
							'Paengawhāwhā',
							'Haratua',
							'Pipiri',
							'Hōngongoi',
							'Hereturikōkā',
							'Mahuru',
							'Whiringa-ā-nuku',
							'Whiringa-ā-rangi',
							'Hakihea'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Kohi',
							'Hui',
							'Pou',
							'Pae',
							'Hara',
							'Pipi',
							'Hōngo',
							'Here',
							'Mahu',
							'Nuku',
							'Rangi',
							'Haki'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'K',
							'H',
							'P',
							'P',
							'H',
							'P',
							'H',
							'H',
							'M',
							'N',
							'R',
							'H'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Kohitātea',
							'Huitanguru',
							'Poutūterangi',
							'Paengawhāwhā',
							'Haratua',
							'Pipiri',
							'Hōngongoi',
							'Hereturikōkā',
							'Mahuru',
							'Whiringa-ā-nuku',
							'Whiringa-ā-rangi',
							'Hakihea'
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
						mon => 'Hin',
						tue => 'Tū',
						wed => 'Apa',
						thu => 'Par',
						fri => 'Mer',
						sat => 'Hor',
						sun => 'Tap'
					},
					narrow => {
						mon => 'H',
						tue => 'T',
						wed => 'A',
						thu => 'P',
						fri => 'M',
						sat => 'H',
						sun => 'T'
					},
					short => {
						mon => 'Hin',
						tue => 'Tū',
						wed => 'Apa',
						thu => 'Par',
						fri => 'Mer',
						sat => 'Hor',
						sun => 'Tap'
					},
					wide => {
						mon => 'Rāhina',
						tue => 'Rātū',
						wed => 'Rāapa',
						thu => 'Rāpare',
						fri => 'Rāmere',
						sat => 'Rāhoroi',
						sun => 'Rātapu'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Hin',
						tue => 'Tū',
						wed => 'Apa',
						thu => 'Par',
						fri => 'Mer',
						sat => 'Hor',
						sun => 'Tap'
					},
					narrow => {
						mon => 'H',
						tue => 'T',
						wed => 'A',
						thu => 'P',
						fri => 'M',
						sat => 'H',
						sun => 'T'
					},
					short => {
						mon => 'Hin',
						tue => 'Tū',
						wed => 'Apa',
						thu => 'Par',
						fri => 'Mer',
						sat => 'Hor',
						sun => 'Tap'
					},
					wide => {
						mon => 'Rāhina',
						tue => 'Rātū',
						wed => 'Rāapa',
						thu => 'Rāpare',
						fri => 'Rāmere',
						sat => 'Rāhoroi',
						sun => 'Rātapu'
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
					abbreviated => {0 => 'HW1',
						1 => 'HW2',
						2 => 'HW3',
						3 => 'HW4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Hauwhā tuatahi',
						1 => 'Hauwhā tuarua',
						2 => 'Hauwhā tuatoru',
						3 => 'Hauwhā tuawhā'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'HW1',
						1 => 'HW2',
						2 => 'HW3',
						3 => 'HW4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Hauwhā tuatahi',
						1 => 'Hauwhā tuarua',
						2 => 'Hauwhā tuatoru',
						3 => 'Hauwhā tuawhā'
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
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
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
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'wiki' W 'o' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'wiki' w 'o' Y},
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
			fallback => '{0} ki te {1}',
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'gregorian' => {
			fallback => '{0} ki te {1}',
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
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Wā Awatea Waenga#,
				'generic' => q#Wā Waenga#,
				'standard' => q#Wā Arowhānui Waenga#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Wā Awatea Rāwhiti#,
				'generic' => q#Wā Rāwhiti#,
				'standard' => q#Wā Arowhānui Rāwhiti#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Wā Awatea Maunga#,
				'generic' => q#Wā Maunga#,
				'standard' => q#Wā Arowhānui Maunga#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Wā Awatea Kiwa#,
				'generic' => q#Wā Kiwa#,
				'standard' => q#Wā Arowhānui Kiwa#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Wā Awatea Ranatiki#,
				'generic' => q#Wā Ranatiki#,
				'standard' => q#Wā Arowhānui Ranatiki#,
			},
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Wā Aonui Kōtuitui#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Tāone Tē Mōhiotia#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Wā Raumati Uropi Waenga#,
				'generic' => q#Wā Uropi Waenga#,
				'standard' => q#Wā Arowhānui Uropi Waenga#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Wā Raumati Uropi Rāwhiti#,
				'generic' => q#Wā Uropi Rāwhiti#,
				'standard' => q#Wā Arowhānui Uropi Rāwhiti#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wā Raumati Uropi Uru#,
				'generic' => q#Wā Uropi Uru#,
				'standard' => q#Wā Arowhānui Uropi Uru#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Wā Toharite Greenwich#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Tāmaki Makaurau#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Rēkohu#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
