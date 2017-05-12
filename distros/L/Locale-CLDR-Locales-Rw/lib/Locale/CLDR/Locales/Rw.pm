=head1

Locale::CLDR::Locales::Rw - Package for language Kinyarwanda

=cut

package Locale::CLDR::Locales::Rw;
# This file auto generated from Data\common\main\rw.xml
#	on Fri 29 Apr  7:23:50 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
 				'mk' => 'Ikimasedoniyani',
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
 				'rw' => 'Kinyarwanda',
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

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'RW' => 'Rwanda',
 			'TO' => 'Igitonga',

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
			main => qr{(?^u:[a b c d e f g h i j k l m n o p q r s t u v w x y z])},
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

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
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
							'Gicuransi',
							'Kamena',
							'Nyakanga',
							'Kanama',
							'Nzeli',
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
			'full' => q{EEEE, y MMMM dd},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{yy/MM/dd},
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
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
	 } }
);
no Moo;

1;

# vim: tabstop=4
