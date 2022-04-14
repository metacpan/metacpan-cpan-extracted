=encoding utf8

=head1

Locale::CLDR::Locales::Sw::Any::Ke - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw::Any::Ke;
# This file auto generated from Data/common/main/sw_KE.xml
#	on Mon 11 Apr  5:38:59 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
				'arq' => 'Kiarabu cha Aljeria',
 				'as' => 'Kiasamisi',
 				'chr' => 'Kicheroki',
 				'cu' => 'Kislovakia cha Kanisa la Jadi',
 				'gaa' => 'Kiga',
 				'grc' => 'Kigiriki cha Kale',
 				'gwi' => 'Kigwichʼin',
 				'hsb' => 'Kisorbia cha Juu',
 				'hup' => 'Kihupa',
 				'hy' => 'Kiamenia',
 				'inh' => 'Kiingushi',
 				'jbo' => 'Kilojbani',
 				'kac' => 'Kikachini',
 				'khq' => 'Kikoyrachiini',
 				'kkj' => 'Kikako',
 				'km' => 'Kikhmeri',
 				'kn' => 'Kikanada',
 				'koi' => 'Kikomipermyak',
 				'kru' => 'Kikurukh',
 				'lag' => 'Kilangi',
 				'lam' => 'Kilamba',
 				'li' => 'Kilimbugishi',
 				'mdf' => 'Kimoksha',
 				'mic' => 'Kimi\'kmak',
 				'mk' => 'Kimasedonia',
 				'moh' => 'Kimohoki',
 				'nnh' => 'Kiingiemboon',
 				'nqo' => 'Kiin’ko',
 				'or' => 'Kiodia',
 				'pcm' => 'Kipijini cha Nigeria',
 				'ses' => 'Kikoyraborosenni',
 				'shu' => 'Kiarabu cha Chadi',
 				'srn' => 'Kisranantongo',
 				'sw_CD' => 'Kiswahili cha Kongo',
 				'swb' => 'Kikomoro',
 				'syr' => 'Kisiria',
 				'tw' => 'Kitwi',
 				'twq' => 'Kitasawak',
 				'udm' => 'Kiudumurti',
 				'ug' => 'Kiuiguri',
 				'zgh' => 'Kitamazighati Sanifu cha Moroko',

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
			'AF' => 'Afghanistani',
 			'AI' => 'Anguila',
 			'AQ' => 'Antaktika',
 			'AZ' => 'Azabajani',
 			'BJ' => 'Benini',
 			'BT' => 'Bhutani',
 			'BY' => 'Belarusi',
 			'CC' => 'Visiwa vya Kokos (Keeling)',
 			'CD' => 'Kongo - Kinshasa',
 			'CI' => 'Ivorikosti',
 			'CY' => 'Saiprasi',
 			'DK' => 'Denmaki',
 			'EA' => 'Keuta na Melilla',
 			'EC' => 'Ekwado',
 			'FM' => 'Mikronesia',
 			'GA' => 'Gaboni',
 			'GL' => 'Grinilandi',
 			'GP' => 'Gwadelupe',
 			'GS' => 'Visiwa vya Jojia ya Kusini na Sandwich ya Kusini',
 			'GU' => 'Guami',
 			'HR' => 'Kroashia',
 			'IO' => 'Himaya ya Uingereza katika Bahari Hindi',
 			'JO' => 'Yordani',
 			'KY' => 'Visiwa vya Kaimani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LI' => 'Lishenteni',
 			'LS' => 'Lesotho',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MK' => 'Masedonia',
 			'MK@alt=variant' => 'Masedonia (FYROM)',
 			'MM' => 'Myama (Burma)',
 			'MO' => 'Makau SAR China',
 			'MO@alt=short' => 'Makau',
 			'MQ' => 'Martiniki',
 			'MS' => 'Montserati',
 			'MV' => 'Maldivi',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nijeri',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'OM' => 'Omani',
 			'PF' => 'Polinesia ya Ufaransa',
 			'PG' => 'Papua Guinea Mpya',
 			'PL' => 'Polandi',
 			'PR' => 'Puetoriko',
 			'PS' => 'Himaya za Palestina',
 			'PY' => 'Paragwai',
 			'QA' => 'Katari',
 			'SG' => 'Singapuri',
 			'SR' => 'Surinamu',
 			'ST' => 'Sao Tome na Prinsipe',
 			'SY' => 'Shamu',
 			'TD' => 'Chadi',
 			'TH' => 'Thailandi',
 			'TM' => 'Turukimenstani',
 			'TW' => 'Taiwani',
 			'UA' => 'Ukreni',
 			'UY' => 'Urugwai',
 			'VA' => 'Mji wa Vatikani',
 			'VG' => 'Visiwa vya Virgin vya Uingereza',
 			'VI' => 'Visiwa vya Virgin vya Marekani',
 			'VN' => 'Vietnamu',
 			'YT' => 'Mayote',

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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
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
