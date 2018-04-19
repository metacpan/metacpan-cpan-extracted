=head1

Locale::CLDR::Locales::Sw::Any::Ke - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw::Any::Ke;
# This file auto generated from Data\common\main\sw_KE.xml
#	on Fri 13 Apr  7:30:11 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
				'ain' => 'Ainu',
 				'ar_001' => 'Kiarabu cha Sasa Kilichosanifishwa',
 				'arq' => 'Kiarabu cha Aljeria',
 				'az' => 'Kiazabajani',
 				'bug' => 'Kibugini',
 				'ckb' => 'Kikurdi cha Kati',
 				'dsb' => 'Kisorbian cha Chini',
 				'grc' => 'Kigiriki cha Kale',
 				'hsb' => 'Kisorbia cha Juu',
 				'inh' => 'Kingushi',
 				'jbo' => 'Kilojbani',
 				'kac' => 'Kikachin',
 				'khq' => 'Kikoyra Chiini',
 				'kkj' => 'Kikako',
 				'koi' => 'Kikomipermyak',
 				'kru' => 'Kikurukh',
 				'lam' => 'Kilamba',
 				'li' => 'Kilimbugish',
 				'mdf' => 'Kimoksha',
 				'mic' => 'Kimicmac',
 				'mk' => 'Kimasedonia',
 				'moh' => 'Kimohoki',
 				'nnh' => 'Kiingiemboon',
 				'nqo' => 'Kiin’ko',
 				'or' => 'Kiodia',
 				'pcm' => 'Pijini ya Nijeria',
 				'root' => 'Kiroot',
 				'sco' => 'sco',
 				'ses' => 'Kikoyraboro Senni',
 				'shu' => 'Kiarabu cha Chadi',
 				'srn' => 'Kiscran Tongo',
 				'swb' => 'Kicomoro',
 				'syr' => 'Kisyria',
 				'tw' => 'Kitwi',
 				'tzm' => 'Lugha ya Central Atlas Tamazight',
 				'udm' => 'Kiudumurti',
 				'wa' => 'Kiwaloon',
 				'wae' => 'Kiwalser',
 				'zgh' => 'Tamazight Sanifu ya Moroko',

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
			'AQ' => 'Antaktika',
 			'AZ' => 'Azabajani',
 			'CI' => 'Ivorikosti',
 			'CX' => 'Kisiwa cha Christmas',
 			'CY' => 'Saiprasi',
 			'FM' => 'Mikronesia',
 			'GP' => 'Gwadelupe',
 			'JO' => 'Yordani',
 			'LB' => 'Lebanoni',
 			'LI' => 'Lishtensteni',
 			'LS' => 'Lesotho',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'MV' => 'Maldivi',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nijer',
 			'NG' => 'Nijeria',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'OM' => 'Omani',
 			'PF' => 'Polinesia ya Ufaransa',
 			'PR' => 'Puetoriko',
 			'QA' => 'Katari',
 			'ST' => 'Sao Tome na Prinsipe',
 			'TD' => 'Chadi',
 			'VN' => 'Vietnamu',

		}
	},
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
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning2' if $time >= 700
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 700;
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
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning2' if $time >= 700
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 700;
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
		},
		'gregorian' => {
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
			'full' => q{{1} 'saa' {0}},
			'long' => q{{1} 'saa' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'saa' {0}},
			'long' => q{{1} 'saa' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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

no Moo;

1;

# vim: tabstop=4
