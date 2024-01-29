=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kw - Package for language Cornish

=cut

package Locale::CLDR::Locales::Kw;
# This file auto generated from Data\common\main\kw.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'Arabek',
 				'ar_001' => 'Arabek Savonek Arnowydh',
 				'br' => 'Bretonek',
 				'cy' => 'Kembrek',
 				'da' => 'Danek',
 				'de' => 'Almaynek',
 				'de_AT' => 'Almaynek (Ostri)',
 				'de_CH' => 'Almaynek Ughel (Pow Swis)',
 				'el' => 'Greka',
 				'en' => 'Sowsnek',
 				'en_AU' => 'Sowsnek (Ostrali)',
 				'en_CA' => 'Sowsnek (Kanada)',
 				'en_GB' => 'Sowsnek (Breten Veur)',
 				'en_GB@alt=short' => 'Sowsnek (RU)',
 				'en_US@alt=short' => 'Sowsnek (SU)',
 				'es' => 'Spaynek',
 				'eu' => 'Baskek',
 				'fr' => 'Frenkek',
 				'fr_CA' => 'Frenkek (Kanada)',
 				'fr_CH' => 'Frenkek (Pow Swis)',
 				'ga' => 'Wordhonek',
 				'gd' => 'Godhalek Alban',
 				'it' => 'Italek',
 				'ja' => 'Japanek',
 				'kw' => 'kernewek',
 				'nl' => 'Iseldiryek',
 				'pt' => 'Portyngalek',
 				'pt_PT' => 'Portyngalek (Ewrop)',
 				'ro_MD' => 'Moldavek',
 				'ru' => 'Russek',
 				'yue' => 'Kantonek',
 				'zh' => 'Chinek',
 				'zh_Hans' => 'Chinek sempelhes',
 				'zh_Hant' => 'Chinek hengovek',

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
			'Arab' => 'Arabek',
 			'Grek' => 'Greka',
 			'Hani' => 'Han',
 			'Hans' => 'Sempelhes',
 			'Hans@alt=stand-alone' => 'Han sempelhes',
 			'Hant' => 'Hengovek',
 			'Hant@alt=stand-alone' => 'Han hengovek',
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
			'001' => 'An Bys',
 			'002' => 'Afrika',
 			'003' => 'Amerika Gledh',
 			'019' => 'An Amerikas',
 			'142' => 'Asi',
 			'150' => 'Europa',
 			'BR' => 'Brasil',
 			'CN' => 'China',
 			'DE' => 'Almayn',
 			'EU' => 'Unyans Europek',
 			'FR' => 'Pow Frenk',
 			'GB' => 'Rywvaneth Unys',
 			'IN' => 'Eynda',
 			'IT' => 'Itali',
 			'JP' => 'Japan',
 			'RU' => 'Russi',
 			'UN' => 'Kenedhlow Unys',
 			'US' => 'Statys Unys',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalans',

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
 				'gregorian' => q{Kalans gregorek},
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
			'language' => 'Taves: {0}',

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
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
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
							'Gen',
							'Hwe',
							'Meu',
							'Ebr',
							'Me',
							'Met',
							'Gor',
							'Est',
							'Gwn',
							'Hed',
							'Du',
							'Kev'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'mis Genver',
							'mis Hwevrer',
							'mis Meurth',
							'mis Ebrel',
							'mis Me',
							'mis Metheven',
							'mis Gortheren',
							'mis Est',
							'mis Gwynngala',
							'mis Hedra',
							'mis Du',
							'mis Kevardhu'
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
						mon => 'Lun',
						tue => 'Mth',
						wed => 'Mhr',
						thu => 'Yow',
						fri => 'Gwe',
						sat => 'Sad',
						sun => 'Sul'
					},
					wide => {
						mon => 'dy Lun',
						tue => 'dy Meurth',
						wed => 'dy Merher',
						thu => 'dy Yow',
						fri => 'dy Gwener',
						sat => 'dy Sadorn',
						sun => 'dy Sul'
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
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
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
				'0' => 'RC',
				'1' => 'AD'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'Etc/Unknown' => {
			exemplarCity => q#Ankoth#,
		},
		'Europe_Central' => {
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Western' => {
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'GMT' => {
			short => {
				'standard' => q#GMT#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
