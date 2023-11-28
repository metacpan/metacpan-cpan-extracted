=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sw::Any::Cd - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw::Any::Cd;
# This file auto generated from Data\common\main\sw_CD.xml
#	on Sat  4 Nov  6:25:32 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

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
 				'ar_001' => 'Kiarabu cha Dunia Kilichosanifishwa',
 				'arq' => 'Kiarabu cha Aljeria',
 				'az' => 'Kiazabajani',
 				'gv' => 'Kimanksi',
 				'gwi' => 'Kigwichiin',
 				'hup' => 'Kihupa',
 				'jbo' => 'Kilojban',
 				'kac' => 'Kikachin',
 				'khq' => 'Kikoyra Chiini',
 				'kkj' => 'Kikako',
 				'koi' => 'Kikomipermyak',
 				'kru' => 'Kikurukh',
 				'kum' => 'Kikumyk',
 				'ky' => 'Kikirigizi',
 				'lam' => 'Kilamba',
 				'li' => 'Kilimburgi',
 				'mak' => 'mak',
 				'mdf' => 'Kimoksha',
 				'mic' => 'Kimikmaki',
 				'mk' => 'Kimasedonia',
 				'moh' => 'Kimohoki',
 				'mos' => 'Kimossi',
 				'nnh' => 'Kingiemboon',
 				'nqo' => 'Kiinko',
 				'pcm' => 'Pijini ya Nijeria',
 				'quc' => 'Kikiiche',
 				'shu' => 'Kiarabu cha Chadi',
 				'srn' => 'Kitongo cha Sranan',
 				'swb' => 'Kikomoro',
 				'syr' => 'Kisiria',
 				'udm' => 'Kiudumurti',
 				'yi' => 'Kiyidi',

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
			'030' => 'Asia Mashariki',
 			'AF' => 'Afuganistani',
 			'AZ' => 'Azabajani',
 			'BJ' => 'Benini',
 			'CI' => 'Kodivaa',
 			'CX' => 'Kisiwa cha Christmas',
 			'CY' => 'Saiprasi',
 			'DK' => 'Denmaki',
 			'HR' => 'Kroeshia',
 			'JO' => 'Yordani',
 			'LB' => 'Lebanoni',
 			'LI' => 'Lishenteni',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'MA' => 'Moroko',
 			'MM' => 'Myama',
 			'MV' => 'Maldivi',
 			'NE' => 'Nijeri',
 			'NG' => 'Nijeria',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'OM' => 'Omani',
 			'PR' => 'Puetoriko',
 			'QA' => 'Katari',
 			'SD' => 'Sudani',
 			'ST' => 'Sao Tome na Prinsipe',
 			'TD' => 'Chadi',
 			'TL' => 'Timori ya Mashariki',
 			'VN' => 'Vietnamu',

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
			auxiliary => qr{[q x]},
			main => qr{[a b c d e f g h i j k l m n o p r s t u v w y z]},
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
				'currency' => q(Ugwiya ya Moritania \(1973–2017\)),
			},
		},
		'MRU' => {
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
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
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
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			MMMEd => q{E d MMM},
			ms => q{m:ss},
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
