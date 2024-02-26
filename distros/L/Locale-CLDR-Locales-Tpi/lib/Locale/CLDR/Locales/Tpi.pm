=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tpi - Package for language Tok Pisin

=cut

package Locale::CLDR::Locales::Tpi;
# This file auto generated from Data\common\main\tpi.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
				'de' => 'Jeman',
 				'de_AT' => 'Austria Jeman',
 				'de_CH' => 'Swis Jeman',
 				'en' => 'Inglis',
 				'en_AU' => 'Australian Inglis',
 				'en_CA' => 'Kenedien Inglis',
 				'en_GB' => 'Britis Inglis',
 				'en_US' => 'Amerikan Inglis',
 				'es' => 'Spenis',
 				'es_419' => 'Saut Amerikan Spenis',
 				'es_ES' => 'Spenis (Spein)',
 				'es_MX' => 'Meksikan Spenis',
 				'fr' => 'Frens',
 				'fr_CA' => 'Kenedien Frens',
 				'fr_CH' => 'Swis Frens',
 				'it' => 'Italien',
 				'ja' => 'Japanis',
 				'pt' => 'Potigis',
 				'pt_BR' => 'Brasilien Potigis',
 				'pt_PT' => 'Yurop Potigis',
 				'ru' => 'Rasien',
 				'tpi' => 'Tok Pisin',
 				'und' => 'Tok ples i no stap',
 				'zh' => 'Sainis',
 				'zh_Hans' => 'Isipela Sainis',
 				'zh_Hant' => 'Tredisinol Sainis',

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
			'Arab' => 'Arabik',
 			'Cyrl' => 'Syrilik',
 			'Hans' => 'Han (isipela)',
 			'Hant' => 'Han (tredisinol)',
 			'Latn' => 'Latin',
 			'Zxxx' => 'Tok i no raitim yet',
 			'Zzzz' => 'Tok i no gat kod yet',

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
			'BR' => 'Brasil',
 			'CN' => 'Saina',
 			'DE' => 'Jemani',
 			'FR' => 'Frans',
 			'GB' => 'Yunaited Kingdom',
 			'IN' => 'India',
 			'IT' => 'Itali',
 			'PG' => 'Papua Niugini',
 			'ZZ' => 'Rijen i no stap',

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
 				'gregorian' => q{Gregorien kalenda},
 			},
 			'cf' => {
 				'standard' => q{stendet karensi fomet},
 			},
 			'collation' => {
 				'standard' => q{stendet oda bilong skelim},
 			},
 			'numbers' => {
 				'latn' => q{westen namba},
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
			'language' => 'tok ples: {0}',
 			'script' => 'skript: {0}',
 			'region' => 'rijen: {0}',

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
			auxiliary => qr{[c q v x z]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'],
			main => qr{[a b d e f g h i j k l m n o p r s t u w y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'], };
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
						'positive' => '#,##0.00 ¤',
					},
				},
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
							'Jan',
							'Feb',
							'Mas',
							'Epr',
							'Me',
							'Jun',
							'Jul',
							'Oga',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janueri',
							'Februeri',
							'Mas',
							'Epril',
							'Me',
							'Jun',
							'Julai',
							'Ogas',
							'Septemba',
							'Oktoba',
							'Novemba',
							'Desemba'
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
						mon => 'Man',
						tue => 'Tun',
						wed => 'Tri',
						thu => 'Fon',
						fri => 'Fra',
						sat => 'Sar',
						sun => 'San'
					},
					wide => {
						mon => 'Mande',
						tue => 'Tunde',
						wed => 'Trinde',
						thu => 'Fonde',
						fri => 'Fraide',
						sat => 'Sarere',
						sun => 'Sande'
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
			'full' => q{EEE, dd MMMM y},
			'long' => q{dd MMMM y},
			'medium' => q{dd MMM y},
			'short' => q{dd/MM/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{hh:mm:ss a zzzz},
			'long' => q{hh:mm:ss a zzz},
			'medium' => q{hh:mm:ss a},
			'short' => q{hh:mm a},
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
		'gregorian' => {
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

no Moo;

1;

# vim: tabstop=4
