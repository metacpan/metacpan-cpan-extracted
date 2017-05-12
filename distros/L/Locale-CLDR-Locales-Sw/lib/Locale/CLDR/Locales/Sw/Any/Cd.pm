=head1

Locale::CLDR::Locales::Sw::Any::Cd - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw::Any::Cd;
# This file auto generated from Data\common\main\sw_CD.xml
#	on Fri 29 Apr  7:27:39 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Sw::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ak' => 'Kiakan',
 				'bn' => 'Kibangla',
 				'cs' => 'Kichecki',
 				'en' => 'Kingereza',
 				'sw_CD' => 'Kiswahili ya Kongo',

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
			'AF' => 'Afuganistani',
 			'BJ' => 'Benini',
 			'CG' => 'Kongo',
 			'CI' => 'Kodivaa',
 			'CY' => 'Kuprosi',
 			'IR' => 'Uajemi',
 			'LI' => 'Lishenteni',
 			'MG' => 'Bukini',
 			'MM' => 'Myama',
 			'NF' => 'Kisiwa cha Norfok',
 			'NG' => 'Nijeria',
 			'TL' => 'Timori ya Mashariki',

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
			auxiliary => qr{(?^u:[q x])},
			main => qr{(?^u:[a b c d e f g h i j k l m n o p r s t u v w y z])},
		};
	},
EOT
: sub {
		return {};
},
);


has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CDF' => {
			symbol => 'FC',
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Renminbi ya China),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bir ya Uhabeshi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Sarafu ya Kijapani),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary ya Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya ya Moritania),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia ya Shelisheli),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga CFA BCEAO),
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
							'mkw',
							'mpi',
							'mtu',
							'min',
							'mtn',
							'mst',
							'msb',
							'mun',
							'mts',
							'mku',
							'mkm',
							'mkb'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'mwezi ya kwanja',
							'mwezi ya pili',
							'mwezi ya tatu',
							'mwezi ya ine',
							'mwezi ya tanu',
							'mwezi ya sita',
							'mwezi ya saba',
							'mwezi ya munane',
							'mwezi ya tisa',
							'mwezi ya kumi',
							'mwezi ya kumi na moya',
							'mwezi ya kumi ya mbili'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'k',
							'p',
							't',
							'i',
							't',
							's',
							's',
							'm',
							't',
							'k',
							'm',
							'm'
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
						mon => 'kwa',
						tue => 'pil',
						wed => 'tat',
						thu => 'ine',
						fri => 'tan',
						sat => 'sit',
						sun => 'yen'
					},
					wide => {
						mon => 'siku ya kwanza',
						tue => 'siku ya pili',
						wed => 'siku ya tatu',
						thu => 'siku ya ine',
						fri => 'siku ya tanu',
						sat => 'siku ya sita',
						sun => 'siku ya yenga'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'k',
						tue => 'p',
						wed => 't',
						thu => 'i',
						fri => 't',
						sat => 's',
						sun => 'y'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 700;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 700;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
	my ($orig, $self) = @_;
	return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'wide' => {
					'am' => q{ya asubuyi},
					'pm' => q{ya muchana},
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
			'full' => q{EEEE d MMMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'short' => q{d/M/y},
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
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			ms => q{m:ss},
			yMEd => q{E d/M/y},
			yMMMEd => q{E d MMM y},
		},
		'generic' => {
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			Md => q{d/M},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
