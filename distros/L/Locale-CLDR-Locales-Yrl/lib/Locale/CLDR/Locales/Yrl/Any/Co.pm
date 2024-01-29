=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Yrl::Any::Co - Package for language Nheengatu

=cut

package Locale::CLDR::Locales::Yrl::Any::Co;
# This file auto generated from Data\common\main\yrl_CO.xml
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

extends('Locale::CLDR::Locales::Yrl::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'br' => 'beretan',
 				'chn' => 'yarigan xinoki',
 				'de' => 'areman',
 				'de_CH' => 'areman iwaté (Suisa)',
 				'gmh' => 'areman iwaté médiu',
 				'goh' => 'areman arkaiku iwaté',
 				'gsw' => 'areman (Suisa)',
 				'lv' => 'retan',
 				'mul' => 'siía ñeẽga',
 				'nds_NL' => 'sakisan yatuka',
 				'und' => 'ũba uyukuau ñeẽga',
 				'wa' => 'waran',
 				'yrl' => 'ñengatú',
 				'zgh' => 'tamasiriti marukinu padran',
 				'zh' => 'xinañeẽga',
 				'zh@alt=menu' => 'xinañeẽga, mãdarĩ',
 				'zh_Hans' => 'xinañeẽga iwasuĩma',
 				'zh_Hans@alt=long' => 'xinañeẽga mãdarĩ (iwasuĩma)',
 				'zh_Hant' => 'xinañeẽga katuwa',
 				'zh_Hant@alt=long' => 'xinañeẽga mãdarĩ (katuwa)',
 				'zxx' => 'ũba aykué ñeẽga sesewaraitá',

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
			'Visp' => 'ñeẽga xipiawera',

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
			'AC' => 'Asesan Kapuãma',
 			'BL' => 'San Batulumeu',
 			'BT' => 'Butan',
 			'CR' => 'Koñta Rika',
 			'GA' => 'Gaban',
 			'KN' => 'San Kirituwan suí Newi',
 			'PM' => 'San Peduru asuí Mikelan',
 			'TA' => 'Tiritan Kũya',
 			'UN' => 'Nasan Yepewasuwaitá',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1606NICT' => 'frãsañeẽga kaxiímawara 1606 upé',
 			'1694ACAD' => 'frãsañeẽga kuiriwara',
 			'AO1990' => 'Kuatiasawasupí Ewakisawa ñeẽga Putugewara 1990',
 			'COLB1945' => 'Kõvẽsan kuatiasawasupí Brasiu-Putugau 1945',
 			'KKCOR' => 'kuatiasawasupí pañé-yara',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'collation' => {
 				'big5han' => q{Xinañẽẽga rikusawarupí muakaresawa - Big5},
 				'gb2312han' => q{Xinañeẽga iwasuĩma muakarewa - GB2312},
 				'search' => q{Sikaisá purusawa pañérupí},
 			},
 			'colstrength' => {
 				'primary' => q{Reyupurawaka letera básika ñũtú},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Ñeẽga: {0}',

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milla kuadaradu-ita),
						'one' => q({0} milla kuadaradu),
						'other' => q({0} milla kuadaradu-ita),
						'per' => q({0} milla kuadaradu rupi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milla kuadaradu-ita),
						'one' => q({0} milla kuadaradu),
						'other' => q({0} milla kuadaradu-ita),
						'per' => q({0} milla kuadaradu rupi),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(pisawera-ita millón rupi),
						'one' => q({0} pisawera millón rupi),
						'other' => q({0} pisawera-ita millón rupi),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(pisawera-ita millón rupi),
						'one' => q({0} pisawera millón rupi),
						'other' => q({0} pisawera-ita millón rupi),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milla-ita karóti rupi),
						'one' => q({0} milla karóti rupi),
						'other' => q({0} milla-ita karóti rupi),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milla-ita karóti rupi),
						'one' => q({0} milla karóti rupi),
						'other' => q({0} milla-ita karóti rupi),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milla-ita karóti ĩperiawa rupi),
						'one' => q({0} milla karóti ĩperiawa rupi),
						'other' => q({0} milla-ita karóti ĩperiawa rupi),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milla-ita karóti ĩperiawa rupi),
						'one' => q({0} milla karóti ĩperiawa rupi),
						'other' => q({0} milla-ita karóti ĩperiawa rupi),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milla-ita),
						'one' => q({0} milla),
						'other' => q({0} milla-ita),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milla-ita),
						'one' => q({0} milla),
						'other' => q({0} milla-ita),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milla esikãdinaua-ita),
						'one' => q({0} milla esikãdinaua),
						'other' => q({0} milla esikãdinaua-ita),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milla esikãdinaua-ita),
						'one' => q({0} milla esikãdinaua),
						'other' => q({0} milla esikãdinaua-ita),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milla paranãuara-ita),
						'one' => q({0} milla paranãuara),
						'other' => q({0} milla paranãuara-ita),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milla paranãuara-ita),
						'one' => q({0} milla paranãuara),
						'other' => q({0} milla paranãuara-ita),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milla-ita hura rupi),
						'one' => q({0} milla hura rupi),
						'other' => q({0} milla-ita hura rupi),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milla-ita hura rupi),
						'one' => q({0} milla hura rupi),
						'other' => q({0} milla-ita hura rupi),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milla kúbika-ita),
						'one' => q({0} milla kúbika),
						'other' => q({0} milla kúbika-ita),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milla kúbika-ita),
						'one' => q({0} milla kúbika),
						'other' => q({0} milla kúbika-ita),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} milla),
						'other' => q({0} milla),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} milla),
						'other' => q({0} milla),
					},
				},
				'short' => {
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milla-itá²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milla-itá²),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(pisawera millón rupi),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(pisawera millón rupi),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milla-itá/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milla-itá/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(millas/gal. imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(millas/gal. imp.),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milla),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milla),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milla-itá/hura),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milla-itá/hura),
					},
				},
			} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000000' => {
					'one' => '0 millón',
					'other' => '0 millón-ita',
				},
				'10000000' => {
					'one' => '00 millón',
					'other' => '00 millón-ita',
				},
				'100000000' => {
					'one' => '000 millón',
					'other' => '000 millón-ita',
				},
				'1000000000' => {
					'one' => '0 billón',
					'other' => '0 billón-ita',
				},
				'10000000000' => {
					'one' => '00 billón',
					'other' => '00 billón-ita',
				},
				'100000000000' => {
					'one' => '000 billón',
					'other' => '000 billón-ita',
				},
				'1000000000000' => {
					'one' => '0 tirillón',
					'other' => '0 tirillón-ita',
				},
				'10000000000000' => {
					'one' => '00 tirillón',
					'other' => '00 tirillón-ita',
				},
				'100000000000000' => {
					'one' => '000 tirillón',
					'other' => '000 tirillón-ita',
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
		'AOR' => {
			display_name => {
				'currency' => q(Kuãsa ãgulawara yumũñãwa yuiri \(1995–1999\)),
				'one' => q(Kuãsa ãgulawara yumuñãwa yuiri \(AOR\)),
				'other' => q(Kuãsa-ita ãgulawara yumuñãwa-itayuiri \(AOR\)),
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
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
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
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'America/St_Kitts' => {
			exemplarCity => q#Sã Kirituwan#,
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan Hurariyu#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sã Peduru asuí Mikiran Kurasí Ara Hurariyu#,
				'generic' => q#Sã Peduru asuí Mikiran Hurariyu#,
				'standard' => q#Sã Peduru asuí Mikiran Hurariyu Retewa#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
