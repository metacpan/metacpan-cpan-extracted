=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Rw - Package for language Kinyarwanda

=cut

package Locale::CLDR::Locales::Rw;
# This file auto generated from Data\common\main\rw.xml
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
				'af' => 'Ikinyafurikaneri',
 				'am' => 'Inyamuhariki',
 				'ar' => 'Icyarabu',
 				'as' => 'Icyasamizi',
 				'az' => 'Inyazeribayijani',
 				'be' => 'Ikibelarusiya',
 				'bg' => 'Urunyabuligariya',
 				'bn' => 'Ikibengali',
 				'br' => 'Inyebiritoni',
 				'bs' => 'Inyebosiniya',
 				'ca' => 'Igikatalani',
 				'cs' => 'Igiceke',
 				'cy' => 'Ikigaluwa',
 				'da' => 'Ikidaninwa',
 				'de' => 'Ikidage',
 				'el' => 'Ikigereki',
 				'en' => 'Icyongereza',
 				'eo' => 'Icyesiperanto',
 				'es' => 'Icyesipanyolo',
 				'et' => 'Icyesitoniya',
 				'eu' => 'Ikibasiki',
 				'fa' => 'Inyeperisi',
 				'fi' => 'Igifinilande',
 				'fil' => 'Ikinyafilipine',
 				'fo' => 'Inyefaroyizi',
 				'fr' => 'Igifaransa',
 				'fy' => 'Igifiriziyani',
 				'ga' => 'Ikirilandi',
 				'gd' => 'Ikigaluwa cy’Igisweduwa',
 				'gl' => 'Ikigalisiya',
 				'gn' => 'Inyaguwarani',
 				'gu' => 'Inyegujarati',
 				'he' => 'Igiheburayo',
 				'hi' => 'Igihindi',
 				'hr' => 'Igikorowasiya',
 				'hu' => 'Igihongiriya',
 				'hy' => 'Ikinyarumeniya',
 				'ia' => 'Ururimi Gahuzamiryango',
 				'id' => 'Ikinyendoziya',
 				'ie' => 'Uruhuzandimi',
 				'is' => 'Igisilande',
 				'it' => 'Igitaliyani',
 				'ja' => 'Ikiyapani',
 				'jv' => 'Inyejava',
 				'ka' => 'Inyejeworujiya',
 				'km' => 'Igikambodiya',
 				'kn' => 'Igikanada',
 				'ko' => 'Igikoreya',
 				'ku' => 'Inyekuridishi',
 				'ky' => 'Inkerigizi',
 				'la' => 'Ikilatini',
 				'ln' => 'Ilingala',
 				'lo' => 'Ikilawotiyani',
 				'lt' => 'Ikilituwaniya',
 				'lv' => 'Ikinyaletoviyani',
 				'mk' => 'Ikimasedoniya',
 				'ml' => 'Ikimalayalami',
 				'mn' => 'Ikimongoli',
 				'mr' => 'Ikimarati',
 				'ms' => 'Ikimalayi',
 				'mt' => 'Ikimaliteze',
 				'ne' => 'Ikinepali',
 				'nl' => 'Ikinerilande',
 				'nn' => 'Inyenoruveji (Nyonorusiki)',
 				'no' => 'Ikinoruveji',
 				'oc' => 'Inyogusitani',
 				'or' => 'Inyoriya',
 				'pa' => 'Igipunjabi',
 				'pl' => 'Igipolone',
 				'ps' => 'Impashito',
 				'pt' => 'Igiporutugali',
 				'pt_BR' => 'Inyeporutigali (Brezili)',
 				'pt_PT' => 'Inyeporutigali (Igiporutigali)',
 				'ro' => 'Ikinyarumaniya',
 				'ru' => 'Ikirusiya',
 				'rw' => 'Ikinyarwanda',
 				'sa' => 'Igisansikiri',
 				'sd' => 'Igisindi',
 				'sh' => 'Inyeseribiya na Korowasiya',
 				'si' => 'Inyesimpaleze',
 				'sk' => 'Igisilovaki',
 				'sl' => 'Ikinyasiloveniya',
 				'so' => 'Igisomali',
 				'sq' => 'Icyalubaniya',
 				'sr' => 'Igiseribe',
 				'st' => 'Inyesesoto',
 				'su' => 'Inyesudani',
 				'sv' => 'Igisuweduwa',
 				'sw' => 'Igiswahili',
 				'ta' => 'Igitamili',
 				'te' => 'Igitelugu',
 				'th' => 'Igitayi',
 				'ti' => 'Inyatigirinya',
 				'tk' => 'Inyeturukimeni',
 				'tlh' => 'Inyekilingoni',
 				'tr' => 'Igiturukiya',
 				'tw' => 'Inyetuwi',
 				'ug' => 'Ikiwiguri',
 				'uk' => 'Ikinyayukereni',
 				'ur' => 'Inyeyurudu',
 				'uz' => 'Inyeyuzubeki',
 				'vi' => 'Ikinyaviyetinamu',
 				'xh' => 'Inyehawusa',
 				'yi' => 'Inyeyidishi',
 				'zu' => 'Inyezulu',

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
			'MK' => 'Masedoniya y’Amajyaruguru',
 			'RW' => 'U Rwanda',
 			'TO' => 'Tonga',

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


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
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
		'RWF' => {
			symbol => 'RF',
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
							'mut.',
							'gas.',
							'wer.',
							'mat.',
							'gic.',
							'kam.',
							'nya.',
							'kan.',
							'nze.',
							'ukw.',
							'ugu.',
							'uku.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mutarama',
							'Gashyantare',
							'Werurwe',
							'Mata',
							'Gicurasi',
							'Kamena',
							'Nyakanga',
							'Kanama',
							'Nzeri',
							'Ukwakira',
							'Ugushyingo',
							'Ukuboza'
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
						mon => 'mbe.',
						tue => 'kab.',
						wed => 'gtu.',
						thu => 'kan.',
						fri => 'gnu.',
						sat => 'gnd.',
						sun => 'cyu.'
					},
					wide => {
						mon => 'Kuwa mbere',
						tue => 'Kuwa kabiri',
						wed => 'Kuwa gatatu',
						thu => 'Kuwa kane',
						fri => 'Kuwa gatanu',
						sat => 'Kuwa gatandatu',
						sun => 'Ku cyumweru'
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
					abbreviated => {0 => 'I1',
						1 => 'I2',
						2 => 'I3',
						3 => 'I4'
					},
					wide => {0 => 'igihembwe cya mbere',
						1 => 'igihembwe cya kabiri',
						2 => 'igihembwe cya gatatu',
						3 => 'igihembwe cya kane'
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
			'full' => q{EEEE, G y MMMM dd},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG yy/MM/dd},
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yMMMd => q{d MMMM y},
			yMd => q{dd-MM-y},
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
		'gregorian' => {
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
