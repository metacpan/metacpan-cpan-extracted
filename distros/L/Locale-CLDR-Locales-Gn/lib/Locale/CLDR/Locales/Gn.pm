=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gn - Package for language Guarani

=cut

package Locale::CLDR::Locales::Gn;
# This file auto generated from Data\common\main\gn.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'gn' => 'avañe’ẽ',

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
			'001' => 'yvóra',
 			'002' => 'África',
 			'003' => 'América del Norte',
 			'005' => 'América del Sur',
 			'009' => 'Oceanía',
 			'013' => 'América Central',
 			'019' => 'América',
 			'021' => 'Norteamérica',
 			'029' => 'Caribe',
 			'142' => 'Ásia',
 			'150' => 'Európa',
 			'419' => 'América Latina',
 			'AR' => 'Argentína',
 			'BO' => 'Bolívia',
 			'BR' => 'Brasil',
 			'CL' => 'Chíle',
 			'CO' => 'Colómbia',
 			'EC' => 'Ecuador',
 			'EU' => 'Union Européa',
 			'EZ' => 'Eurozóna',
 			'GF' => 'Guyána Francésa',
 			'GL' => 'Groenlandia',
 			'GY' => 'Guyana',
 			'MX' => 'México',
 			'PE' => 'Peru',
 			'PY' => 'Paraguai',
 			'SR' => 'Surinam',
 			'UN' => 'Naciónes Unídas',
 			'US' => 'Estados Unidos',
 			'US@alt=short' => 'EE. UU.',
 			'UY' => 'Uruguay',
 			'VE' => 'Venezuéla',

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
			auxiliary => qr{[b c d f q w x z]},
			index => ['AÃ', '{CH}', 'EẼ', 'G{G̃}', 'H', 'IĨ', 'J', 'K', 'L', 'M', '{MB}', 'NÑ', '{ND}', '{NG}', '{NT}', 'OÕ', 'P', 'R', '{RR}', 'S', 'T', 'UŨ', 'V', 'YỸ', 'ʼ'],
			main => qr{[aã {ch} eẽ g{g̃} h iĩ j k l m {mb} nñ {nd} {ng} {nt} oõ p r {rr} s t uũ v yỹ ʼ]},
		};
	},
EOT
: sub {
		return { index => ['AÃ', '{CH}', 'EẼ', 'G{G̃}', 'H', 'IĨ', 'J', 'K', 'L', 'M', '{MB}', 'NÑ', '{ND}', '{NG}', '{NT}', 'OÕ', 'P', 'R', '{RR}', 'S', 'T', 'UŨ', 'V', 'YỸ', 'ʼ'], };
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
		'PYG' => {
			symbol => '₲',
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
					wide => {
						nonleap => [
							'Jasyteĩ',
							'Jasykõi',
							'Jasyapy',
							'Jasyrundy',
							'Jasypo',
							'Jasypoteĩ',
							'Jasypokõi',
							'Jasypoapy',
							'Jasyporundy',
							'Jasypa',
							'Jasypateĩ',
							'Jasypakõi'
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
					wide => {
						mon => 'Arakõi',
						tue => 'Araapy',
						wed => 'Ararundy',
						thu => 'Arapo',
						fri => 'Arapoteĩ',
						sat => 'Arapokõi',
						sun => 'Arateĩ'
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
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia óra#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuador óra#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galápagos óra#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela óra#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
