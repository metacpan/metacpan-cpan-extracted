=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sr::Latn::Ba - Package for language Serbian

=cut

package Locale::CLDR::Locales::Sr::Latn::Ba;
# This file auto generated from Data\common\main\sr_Latn_BA.xml
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

extends('Locale::CLDR::Locales::Sr::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'be' => 'bjeloruski',
 				'bm' => 'bamanankan',
 				'bn' => 'bangla',
 				'crl' => 'sjeveroistočni kri',
 				'de' => 'njemački',
 				'de_CH' => 'švajcarski visoki njemački',
 				'frr' => 'sjevernofrizijski',
 				'gsw' => 'njemački (Švajcarska)',
 				'ht' => 'haićanski kreolski',
 				'lrc' => 'sjeverni luri',
 				'nd' => 'sjeverni ndebele',
 				'nds' => 'niskonjemački',
 				'nso' => 'sjeverni soto',
 				'ojb' => 'sjeverozapadni odžibva',
 				'se' => 'sjeverni sami',
 				'ttm' => 'sjeverni tučon',

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
			'001' => 'svijet',
 			'003' => 'Sjevernoamerički kontinent',
 			'015' => 'Sjeverna Afrika',
 			'019' => 'Sjeverna i Južna Amerika',
 			'021' => 'Sjeverna Amerika',
 			'154' => 'Sjeverna Evropa',
 			'AC' => 'ostrvo Asension',
 			'AX' => 'Olandska ostrva',
 			'BL' => 'Sen Bartelemi',
 			'BN' => 'Bruneji',
 			'BV' => 'ostrvo Buve',
 			'BY' => 'Bjelorusija',
 			'CC' => 'Kokosova (Kiling) ostrva',
 			'CP' => 'ostrvo Kliperton',
 			'CZ' => 'Češka Republika',
 			'DE' => 'Njemačka',
 			'FK' => 'Foklandska ostrva',
 			'FK@alt=variant' => 'Folklandska (Malvinska) ostrva',
 			'FO' => 'Farska ostrva',
 			'GS' => 'Južna Džordžija i Južna Sendvička ostrva',
 			'GU' => 'Gvam',
 			'GW' => 'Gvineja Bisao',
 			'HK' => 'Hongkong (SAO Kine)',
 			'HM' => 'ostrvo Herd i ostrva Makdonald',
 			'KM' => 'Komori',
 			'KP' => 'Sjeverna Koreja',
 			'MK' => 'Sjeverna Makedonija',
 			'MM' => 'Mjanmar (Burma)',
 			'MP' => 'Sjeverna Marijanska ostrva',
 			'NF' => 'ostrvo Norfok',
 			'NU' => 'Nijue',
 			'PS' => 'palestinske teritorije',
 			'RE' => 'Reunion',
 			'TF' => 'Francuske južne teritorije',
 			'UM' => 'Spoljna ostrva SAD',
 			'VC' => 'Sveti Vinsent i Grenadini',
 			'VG' => 'Britanska Djevičanska ostrva',
 			'VI' => 'Američka Djevičanska ostrva',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'collation' => 'redoslijed sortiranja',
 			'ms' => 'sistem mjernih jedinica',

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
 				'compat' => q{prethodni redoslijed sortiranja, zbog kompatibilnosti},
 				'dictionary' => q{redoslijed sortiranja u rječniku},
 				'ducet' => q{podrazumijevani Unicode redoslijed sortiranja},
 				'phonetic' => q{fonetski redoslijed sortiranja},
 				'search' => q{pretraga opšte namjene},
 				'standard' => q{standardni redoslijed sortiranja},
 				'unihan' => q{redoslijed sortiranja radikalnih poteza},
 			},
 			'numbers' => {
 				'mymr' => q{mjanmarske cifre},
 			},

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
					'1024p8' => {
						'1' => q(jobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(jobi{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(q{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(q{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(Q{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(Q{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0} G),
						'one' => q({0} ge sila),
						'other' => q({0} ge sila),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} G),
						'one' => q({0} ge sila),
						'other' => q({0} ge sila),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'few' => q({0} dijela na milijardu),
						'name' => q(dijelovi na milijardu),
						'one' => q({0} dio na milijardu),
						'other' => q({0} dijelova na milijardu),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'few' => q({0} dijela na milijardu),
						'name' => q(dijelovi na milijardu),
						'one' => q({0} dio na milijardu),
						'other' => q({0} dijelova na milijardu),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} vijeka),
						'name' => q(vijekovi),
						'one' => q({0} vijek),
						'other' => q({0} vijekova),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} vijeka),
						'name' => q(vijekovi),
						'one' => q({0} vijek),
						'other' => q({0} vijekova),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mjeseca),
						'one' => q({0} mjesec),
						'other' => q({0} mjeseci),
						'per' => q({0} mjesečno),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mjeseca),
						'one' => q({0} mjesec),
						'other' => q({0} mjeseci),
						'per' => q({0} mjesečno),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} nedjelje),
						'name' => q(nedjelje),
						'one' => q({0} nedjelja),
						'other' => q({0} nedjelja),
						'per' => q({0} nedjeljno),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} nedjelje),
						'name' => q(nedjelje),
						'one' => q({0} nedjelja),
						'other' => q({0} nedjelja),
						'per' => q({0} nedjeljno),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} mA),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} mA),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kJ),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kJ),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} Hz),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} Hz),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} svjetlosne godine),
						'name' => q(svjetlosne godine),
						'one' => q({0} svjetlosna godina),
						'other' => q({0} svjetlosnih godina),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} svjetlosne godine),
						'name' => q(svjetlosne godine),
						'one' => q({0} svjetlosna godina),
						'other' => q({0} svjetlosnih godina),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grana),
						'one' => q({0} gran),
						'other' => q({0} granova),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grana),
						'one' => q({0} gran),
						'other' => q({0} granova),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inHg),
						'one' => q({0} inč živinog stuba),
						'other' => q({0} inča živinog stuba),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inHg),
						'one' => q({0} inč živinog stuba),
						'other' => q({0} inča živinog stuba),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mbar),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} svjetla),
						'name' => q(svjetlo),
						'one' => q({0} svjetlo),
						'other' => q({0} svjetla),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} svjetla),
						'name' => q(svjetlo),
						'one' => q({0} svjetlo),
						'other' => q({0} svjetla),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} aker stope),
						'one' => q({0} ac ft),
						'other' => q({0} aker stopa),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} aker stope),
						'one' => q({0} ac ft),
						'other' => q({0} aker stopa),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0} imp. galon),
						'other' => q({0} imp. galona),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0} imp. galon),
						'other' => q({0} imp. galona),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(dijelovi/milijarda),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(dijelovi/milijarda),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mjes.),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mjes.),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} s),
						'one' => q({0} sek),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} s),
						'one' => q({0} sek),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} n),
						'one' => q({0} ned.),
						'other' => q({0} n),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} n),
						'one' => q({0} ned.),
						'other' => q({0} n),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} god.),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} god.),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} hp),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} hp),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} svjetla),
						'name' => q(svjetlo),
						'one' => q({0} svjetlo),
						'other' => q({0} svjetala),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} svjetla),
						'name' => q(svjetlo),
						'one' => q({0} svjetlo),
						'other' => q({0} svjetala),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} d. kaš.),
						'name' => q(d. kaš.),
						'one' => q({0} d. kaš.),
						'other' => q({0} d. kaš.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} d. kaš.),
						'name' => q(d. kaš.),
						'one' => q({0} d. kaš.),
						'other' => q({0} d. kaš.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} i. d. k.),
						'name' => q(i. d. k.),
						'one' => q({0} i. d. k.),
						'other' => q({0} i. d. k.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} i. d. k.),
						'name' => q(i. d. k.),
						'one' => q({0} i. d. k.),
						'other' => q({0} i. d. k.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0}/gal Imp),
						'other' => q({0}/gal Imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'one' => q({0}/gal Imp),
						'other' => q({0}/gal Imp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(dijelovi/milijarda),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(dijelovi/milijarda),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mjes.),
						'name' => q(mjeseci),
						'one' => q({0} mjes.),
						'other' => q({0} mjes.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mjes.),
						'name' => q(mjeseci),
						'one' => q({0} mjes.),
						'other' => q({0} mjes.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(svjetlosne god.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(svjetlosne god.),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grana),
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granova),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grana),
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granova),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} svjetla),
						'name' => q(svjetlo),
						'one' => q({0} svjetlo),
						'other' => q({0} svjetala),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} svjetla),
						'name' => q(svjetlo),
						'one' => q({0} svjetlo),
						'other' => q({0} svjetala),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BAM' => {
			display_name => {
				'currency' => q(Bosanskohercegovačka konvertibilna marka),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Bjeloruska rublja),
				'few' => q(bjeloruske rublje),
				'one' => q(bjeloruska rublja),
				'other' => q(bjeloruskih rublji),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Sjevernokorejski von),
				'few' => q(sjevernokorejska vona),
				'one' => q(sjevernokorejski von),
				'other' => q(sjevernokorejskih vona),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragvanska zlatna kordoba),
				'few' => q(nikaragvanske zlatne kordobe),
				'one' => q(nikaragvanska zlatna kordoba),
				'other' => q(nikaragvanskih zlatnih kordoba),
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
						mon => 'pon',
						tue => 'uto',
						wed => 'sri',
						thu => 'čet',
						fri => 'pet',
						sat => 'sub',
						sun => 'ned'
					},
					wide => {
						mon => 'ponedjeljak',
						tue => 'utorak',
						wed => 'srijeda',
						thu => 'četvrtak',
						fri => 'petak',
						sat => 'subota',
						sun => 'nedjelja'
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
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
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
					'am' => q{prije podne},
					'pm' => q{po podne},
				},
				'narrow' => {
					'afternoon1' => q{po podne},
					'evening1' => q{uveče},
					'midnight' => q{ponoć},
					'morning1' => q{ujutro},
					'night1' => q{noću},
					'noon' => q{podne},
				},
				'wide' => {
					'am' => q{prije podne},
					'pm' => q{po podne},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
				},
				'wide' => {
					'am' => q{prije podne},
					'pm' => q{po podne},
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
			wide => {
				'0' => 'prije nove ere'
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
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
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
		regionFormat => q({0}, ljetnje vrijeme),
		regionFormat => q({0}, standardno vrijeme),
		'Afghanistan' => {
			long => {
				'standard' => q#Avganistan vrijeme#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Centralno-afričko vrijeme#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Istočno-afričko vrijeme#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Južno-afričko vrijeme#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Zapadno-afričko ljetnje vrijeme#,
				'generic' => q#Zapadno-afričko vrijeme#,
				'standard' => q#Zapadno-afričko standardno vrijeme#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aljaska, ljetnje vrijeme#,
				'generic' => q#Aljaska#,
				'standard' => q#Aljaska, standardno vrijeme#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon, ljetnje vrijeme#,
				'generic' => q#Amazon vrijeme#,
				'standard' => q#Amazon, standardno vrijeme#,
			},
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vivi, Indijana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsens, Indijana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indijanapolis#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luivil#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Bjula, Sjeverna Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Centar, Sjeverna Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Novi Salem, Sjeverna Dakota#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-o-Prens#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port ov Spejn#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoriko#,
		},
		'America/Regina' => {
			exemplarCity => q#Redžajna#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rezolut#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itokortormit#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sen Bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent Džons#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sent Tomas#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Svift Karent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Sjevernoameričko centralno ljetnje vrijeme#,
				'generic' => q#Sjevernoameričko centralno vrijeme#,
				'standard' => q#Sjevernoameričko centralno standardno vrijeme#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Sjevernoameričko istočno ljetnje vrijeme#,
				'generic' => q#Sjevernoameričko istočno vrijeme#,
				'standard' => q#Sjevernoameričko istočno standardno vrijeme#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Sjevernoameričko planinsko ljetnje vrijeme#,
				'generic' => q#Sjevernoameričko planinsko vrijeme#,
				'standard' => q#Sjevernoameričko planinsko standardno vrijeme#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Sjevernoameričko pacifičko letnje vrijeme#,
				'generic' => q#Sjevernoameričko pacifičko vrijeme#,
				'standard' => q#Sjevernoameričko pacifičko standardno vrijeme#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dimon d’Irvil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makvori#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apija, ljetnje vrijeme#,
				'generic' => q#Apija vrijeme#,
				'standard' => q#Apija, standardno vrijeme#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabijsko ljetnje vrijeme#,
				'generic' => q#Arabijsko vrijeme#,
				'standard' => q#Arabijsko standardno vrijeme#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longjir#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina, ljetnje vrijeme#,
				'generic' => q#Argentina vrijeme#,
				'standard' => q#Argentina, standardno vrijeme#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Zapadna Argentina, ljetnje vrijeme#,
				'generic' => q#Zapadna Argentina vrijeme#,
				'standard' => q#Zapadna Argentina, standardno vrijeme#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Jermenija, ljetnje vrijeme#,
				'generic' => q#Jermenija vrijeme#,
				'standard' => q#Jermenija, standardno vrijeme#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantsko ljetnje vrijeme#,
				'generic' => q#Atlantsko vrijeme#,
				'standard' => q#Atlantsko standardno vrijeme#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australijsko centralno ljetnje vrijeme#,
				'generic' => q#Australijsko centralno vrijeme#,
				'standard' => q#Australijsko centralno standardno vrijeme#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australijsko centralno zapadno ljetnje vrijeme#,
				'generic' => q#Australijsko centralno zapadno vrijeme#,
				'standard' => q#Australijsko centralno zapadno standardno vrijeme#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australijsko istočno ljetnje vrijeme#,
				'generic' => q#Australijsko istočno vrijeme#,
				'standard' => q#Australijsko istočno standardno vrijeme#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australijsko zapadno ljetnje vrijeme#,
				'generic' => q#Australijsko zapadno vrijeme#,
				'standard' => q#Australijsko zapadno standardno vrijeme#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbejdžan, ljetnje vrijeme#,
				'generic' => q#Azerbejdžan vrijeme#,
				'standard' => q#Azerbejdžan, standardno vrijeme#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azori, ljetnje vrijeme#,
				'generic' => q#Azori vrijeme#,
				'standard' => q#Azori, standardno vrijeme#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeš, ljetnje vrijeme#,
				'generic' => q#Bangladeš vrijeme#,
				'standard' => q#Bangladeš, standardno vrijeme#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan vrijeme#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivija vrijeme#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brazilija, ljetnje vrijeme#,
				'generic' => q#Brazilija vrijeme#,
				'standard' => q#Brazilija, standardno vrijeme#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunej Darusalum vrijeme#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Zelenortska Ostrva, ljetnje vrijeme#,
				'generic' => q#Zelenortska Ostrva vrijeme#,
				'standard' => q#Zelenortska Ostrva, standardno vrijeme#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Čamoro vrijeme#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Čatam, ljetnje vrijeme#,
				'generic' => q#Čatam vrijeme#,
				'standard' => q#Čatam, standardno vrijeme#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Čile, ljetnje vrijeme#,
				'generic' => q#Čile vrijeme#,
				'standard' => q#Čile, standardno vrijeme#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kina, ljetnje vrijeme#,
				'generic' => q#Kina vrijeme#,
				'standard' => q#Kinesko standardno vrijeme#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Božićno ostrvo vrijeme#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokosova (Kiling) ostrva vrijeme#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbija, ljetnje vrijeme#,
				'generic' => q#Kolumbija vrijeme#,
				'standard' => q#Kolumbija, standardno vrijeme#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kukova Ostrva, poluljetnje vrijeme#,
				'generic' => q#Kukova Ostrva vrijeme#,
				'standard' => q#Kukova Ostrva, standardno vrijeme#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba, ljetnje vrijeme#,
				'generic' => q#Kuba#,
				'standard' => q#Kuba, standardno vrijeme#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Dejvis vrijeme#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dimon d’Irvil vrijeme#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Istočni Timor vrijeme#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Uskršnja ostrva, ljetnje vrijeme#,
				'generic' => q#Uskršnja ostrva vrijeme#,
				'standard' => q#Uskršnja ostrva, standardno vrijeme#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvador vrijeme#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinisano univerzalno vrijeme#,
			},
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irska, standardno vrijeme#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britanija, ljetnje vrijeme#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Srednjoevropsko ljetnje vrijeme#,
				'generic' => q#Srednjoevropsko vrijeme#,
				'standard' => q#Srednjoevropsko standardno vrijeme#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Istočnoevropsko ljetnje vrijeme#,
				'generic' => q#Istočnoevropsko vrijeme#,
				'standard' => q#Istočnoevropsko standardno vrijeme#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Zapadnoevropsko ljetnje vrijeme#,
				'generic' => q#Zapadnoevropsko vrijeme#,
				'standard' => q#Zapadnoevropsko standardno vrijeme#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklandska Ostrva, ljetnje vrijeme#,
				'generic' => q#Folklandska Ostrva vrijeme#,
				'standard' => q#Folklandska Ostrva, standardno vrijeme#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidži, ljetnje vrijeme#,
				'generic' => q#Fidži vrijeme#,
				'standard' => q#Fidži, standardno vrijeme#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francuska Gvajana vrijeme#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Francusko južno i antarktičko vrijeme#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Srednje vrijeme po Griniču#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos vrijeme#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambije vrijeme#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzija, ljetnje vrijeme#,
				'generic' => q#Gruzija vrijeme#,
				'standard' => q#Gruzija, standardno vrijeme#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbertova ostrva vrijeme#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Istočni Grenland, ljetnje vrijeme#,
				'generic' => q#Istočni Grenland#,
				'standard' => q#Istočni Grenland, standardno vrijeme#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Zapadni Grenland, ljetnje vrijeme#,
				'generic' => q#Zapadni Grenland#,
				'standard' => q#Zapadni Grenland, standardno vrijeme#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Zalivsko vrijeme#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gvajana vrijeme#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havajsko-aleutsko ljetnje vrijeme#,
				'generic' => q#Havajsko-aleutsko vrijeme#,
				'standard' => q#Havajsko-aleutsko standardno vrijeme#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong, ljetnje vrijeme#,
				'generic' => q#Hong Kong vrijeme#,
				'standard' => q#Hong Kong, standardno vrijeme#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd, ljetnje vrijeme#,
				'generic' => q#Hovd vrijeme#,
				'standard' => q#Hovd, standardno vrijeme#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indijsko standardno vrijeme#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indijsko okeansko vrijeme#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokina vrijeme#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Centralno-indonezijsko vrijeme#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Istočno-indonezijsko vrijeme#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Zapadno-indonezijsko vrijeme#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran, ljetnje vrijeme#,
				'generic' => q#Iran vrijeme#,
				'standard' => q#Iran, standardno vrijeme#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkuck, ljetnje vrijeme#,
				'generic' => q#Irkuck vrijeme#,
				'standard' => q#Irkuck, standardno vrijeme#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izraelsko ljetnje vrijeme#,
				'generic' => q#Izraelsko vrijeme#,
				'standard' => q#Izraelsko standardno vrijeme#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japansko ljetnje vrijeme#,
				'generic' => q#Japansko vrijeme#,
				'standard' => q#Japansko standardno vrijeme#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kazahstansko vrijeme#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Istočno-kazahstansko vrijeme#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Zapadno-kazahstansko vrijeme#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejsko ljetnje vrijeme#,
				'generic' => q#Korejsko vrijeme#,
				'standard' => q#Korejsko standardno vrijeme#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Košre vrijeme#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk, ljetnje vrijeme#,
				'generic' => q#Krasnojarsk vrijeme#,
				'standard' => q#Krasnojarsk, standardno vrijeme#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistan vrijeme#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Linijska ostrva vrijeme#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Hov, ljetnje vrijeme#,
				'generic' => q#Lord Hov vrijeme#,
				'standard' => q#Lord Hov, standardno vrijeme#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan, ljetnje vrijeme#,
				'generic' => q#Magadan vrijeme#,
				'standard' => q#Magadan, standardno vrijeme#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malezija vrijeme#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivi vrijeme#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markiz vrijeme#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Maršalska Ostrva vrijeme#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauricijus, ljetnje vrijeme#,
				'generic' => q#Mauricijus vrijeme#,
				'standard' => q#Mauricijus, standardno vrijeme#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Moson vrijeme#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksički Pacifik, ljetnje vrijeme#,
				'generic' => q#Meksički Pacifik#,
				'standard' => q#Meksički Pacifik, standardno vrijeme#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Bator, ljetnje vrijeeme#,
				'generic' => q#Ulan Bator vrijeme#,
				'standard' => q#Ulan Bator, standardno vrijeme#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva, ljetnje vrijeme#,
				'generic' => q#Moskva vrijeme#,
				'standard' => q#Moskva, standardno vrijeme#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mjanmar vrijeme#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru vrijeme#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal vrijeme#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nova Kaledonija, ljetnje vrijeme#,
				'generic' => q#Nova Kaledonija vrijeme#,
				'standard' => q#Nova Kaledonija, standardno vrijeme#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Novi Zeland, ljetnje vrijeme#,
				'generic' => q#Novi Zeland vrijeme#,
				'standard' => q#Novi Zeland, standardno vrijeme#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Njufaundlend, ljetnje vrijeme#,
				'generic' => q#Njufaundlend#,
				'standard' => q#Njufaundlend, standardno vrijeme#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Nijue vrijeme#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ostrvo Norfolk, ljetnje vrijeme#,
				'generic' => q#ostrvo Norfolk vrijeme#,
				'standard' => q#ostrvo Norfolk, standardno vrijeme#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronja, ljetnje vrijeme#,
				'generic' => q#Fernando de Noronja vrijeme#,
				'standard' => q#Fernando de Noronja, standardno vrijeme#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk, ljetnje vrijeme#,
				'generic' => q#Novosibirsk vrijeme#,
				'standard' => q#Novosibirsk, standardno vrijeme#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk, ljetnje vrijeme#,
				'generic' => q#Omsk vrijeme#,
				'standard' => q#Omsk, standardno vrijeme#,
			},
		},
		'Pacific/Niue' => {
			exemplarCity => q#Nijue#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan, ljetnje vrijeme#,
				'generic' => q#Pakistan vrijeme#,
				'standard' => q#Pakistan, standardno vrijeme#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau vrijeme#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Nova Gvineja vrijeme#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragvaj, ljetnje vrijeme#,
				'generic' => q#Paragvaj vrijeme#,
				'standard' => q#Paragvaj, standardno vrijeme#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru, ljetnje vrijeme#,
				'generic' => q#Peru vrijeme#,
				'standard' => q#Peru, standardno vrijeme#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipini, ljetnje vrijeme#,
				'generic' => q#Filipini vrijeme#,
				'standard' => q#Filipini, standardno vrijeme#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Feniks ostrva vrijeme#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sen Pjer i Mikelon, ljetnje vrijeme#,
				'generic' => q#Sen Pjer i Mikelon#,
				'standard' => q#Sen Pjer i Mikelon, standardno vrijeme#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkern vrijeme#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponpej vrijeme#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjongjanško vrijeme#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunion vrijeme#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera vrijeme#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalin, ljetnje vrijeme#,
				'generic' => q#Sahalin vrijeme#,
				'standard' => q#Sahalin, standardno vrijeme#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa, ljetnje vrijeme#,
				'generic' => q#Samoa vrijeme#,
				'standard' => q#Samoa, standardno vrijeme#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Sejšeli vrijeme#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur, standardno vrijeme#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomonska Ostrva vrijeme#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Južna Džordžija vrijeme#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam vrijeme#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Šova vrijeme#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti vrijeme#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tajpej, ljetnje vrijeme#,
				'generic' => q#Tajpej vrijeme#,
				'standard' => q#Tajpej, standardno vrijeme#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistan vrijeme#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau vrijeme#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga, ljetnje vrijeme#,
				'generic' => q#Tonga vrijeme#,
				'standard' => q#Tonga, standardno vrijeme#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Čuk vrijeme#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan, ljetnje vrijeme#,
				'generic' => q#Turkmenistan vrijeme#,
				'standard' => q#Turkmenistan, standardno vrijeme#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu vrijeme#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugvaj, ljetnje vrijeme#,
				'generic' => q#Urugvaj vrijeme#,
				'standard' => q#Urugvaj, standardno vrijeme#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistan, ljetnje vrijeme#,
				'generic' => q#Uzbekistan vrijeme#,
				'standard' => q#Uzbekistan, standardno vrijeme#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu, ljetnje vrijeme#,
				'generic' => q#Vanuatu vrijeme#,
				'standard' => q#Vanuatu, standardno vrijeme#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venecuela vrijeme#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok, ljetnje vrijeme#,
				'generic' => q#Vladivostok vrijeme#,
				'standard' => q#Vladivostok, standardno vrijeme#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd, ljetnje vrijeme#,
				'generic' => q#Volgograd vrijeme#,
				'standard' => q#Volgograd, standardno vrijeme#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok vrijeme#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ostrvo Vejk vrijeme#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ostrva Valis i Futuna vrijeme#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk, ljetnje vrijeme#,
				'generic' => q#Jakutsk vrijeme#,
				'standard' => q#Jakutsk, standardno vrijeme#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg, ljetnje vrijeme#,
				'generic' => q#Jekaterinburg vrijeme#,
				'standard' => q#Jekaterinburg, standardno vrijeme#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
