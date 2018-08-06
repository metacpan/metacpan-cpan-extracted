=head1

Locale::CLDR::Locales::Rw - Package for language Kinyarwanda

=cut

package Locale::CLDR::Locales::Rw;
# This file auto generated from Data\common\main\rw.xml
#	on Sun  5 Aug  6:20:06 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
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

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
				'stand-alone' => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
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
				'stand-alone' => {
					abbreviated => {
						mon => 'mbe.',
						tue => 'kab.',
						wed => 'gtu.',
						thu => 'kan.',
						fri => 'gnu.',
						sat => 'gnd.',
						sun => 'cyu.'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'igihembwe cya mbere',
						1 => 'igihembwe cya kabiri',
						2 => 'igihembwe cya gatatu',
						3 => 'igihembwe cya kane'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'I1',
						1 => 'I2',
						2 => 'I3',
						3 => 'I4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
				'wide' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
				'wide' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
				'narrow' => {
					'am' => q{AM},
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
			abbreviated => {
				'0' => 'BCE',
				'1' => 'CE'
			},
			wide => {
				'0' => 'BCE',
				'1' => 'CE'
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
			'full' => q{EEEE, G y MMMM dd},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG yy/MM/dd},
		},
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{'week' W 'of' MMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{'week' w 'of' y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
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
