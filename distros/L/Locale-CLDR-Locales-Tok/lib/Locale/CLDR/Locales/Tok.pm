=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tok - Package for language Toki Pona

=cut

package Locale::CLDR::Locales::Tok;
# This file auto generated from Data\common\main\tok.xml
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
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} pi {1}';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0} pi {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'toki Alapi',
 				'bn' => 'toki Panla',
 				'de' => 'toki Tosi',
 				'en' => 'toki Inli',
 				'en_CA' => 'toki Inli pi ma Kanata',
 				'en_GB' => 'toki Inli pi ma Piten',
 				'en_GB@alt=short' => 'toki Inli pi ma Juke',
 				'es' => 'toki Epanja',
 				'es_419' => 'toki Epanja pi ma Amelika',
 				'fr' => 'toki Kanse',
 				'fr_CA' => 'toki Kanse pi ma Kanata',
 				'hi' => 'toki Insi',
 				'id' => 'toki Intonesija',
 				'it' => 'toki Italija',
 				'ja' => 'toki Nijon',
 				'ko' => 'toki Anku',
 				'nl' => 'toki Netelan',
 				'pl' => 'toki Posuka',
 				'pt' => 'toki Potuke',
 				'ru' => 'toki Lusi',
 				'th' => 'toki Tawi',
 				'tok' => 'toki pona',
 				'tr' => 'toki Tuki',
 				'und' => 'toki ante',
 				'uz' => 'toki Opeki',
 				'zh' => 'toki Sonko',

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
			'Arab' => 'sitelen Alapi',
 			'Cyrl' => 'sitelen Kililita',
 			'Hans' => 'sitelen Sonko',
 			'Jpan' => 'sitelen Nijon',
 			'Kore' => 'sitelen Anku',
 			'Latn' => 'sitelen Lasina',
 			'Zxxx' => 'sitelen ala',
 			'Zzzz' => 'sitelen ante',

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
			'001' => 'ma ale',
 			'002' => 'ma Apika',
 			'009' => 'ma Osijanija',
 			'019' => 'ma Amelika',
 			'142' => 'ma Asija',
 			'150' => 'ma Elopa',
 			'AD' => 'ma Antola',
 			'AF' => 'ma Akanisan',
 			'AL' => 'ma Sipe',
 			'AM' => 'ma Aja',
 			'AO' => 'ma Ankola',
 			'AQ' => 'ma Antasika',
 			'AR' => 'ma Alensina',
 			'AT' => 'ma Esalasi',
 			'AU' => 'ma Oselija',
 			'BA' => 'ma Posan',
 			'BD' => 'ma Panla',
 			'BE' => 'ma Pesije',
 			'BF' => 'ma Pukinapaso',
 			'BG' => 'toki Pokasi',
 			'BH' => 'ma Palani',
 			'BJ' => 'ma Penen',
 			'BR' => 'ma Pasiju',
 			'BW' => 'ma Posuwana',
 			'BY' => 'ma Pelalusi',
 			'CD' => 'ma Konko pi ma tomo Kinsasa',
 			'CF' => 'ma Santapiken',
 			'CG' => 'ma Konko pi ma tomo Pasapi',
 			'CH' => 'ma Suwasi',
 			'CI' => 'ma Kosiwa',
 			'CL' => 'ma Sile',
 			'CM' => 'ma Kamelun',
 			'CN' => 'ma Sonko',
 			'CO' => 'ma Kolonpija',
 			'CY' => 'ma Kiposi',
 			'CZ' => 'ma Seki',
 			'DE' => 'ma Tosi',
 			'DJ' => 'ma Sipusi',
 			'DK' => 'ma Tansi',
 			'DZ' => 'ma Sasali',
 			'EC' => 'ma Ekato',
 			'EE' => 'ma Esi',
 			'EG' => 'ma Masu',
 			'ER' => 'ma Eliteja',
 			'ES' => 'ma Epanja',
 			'ET' => 'ma Isijopija',
 			'EU' => 'kulupu ma Elopa',
 			'FI' => 'ma Sumi',
 			'FJ' => 'ma Pisi',
 			'FR' => 'ma Kanse',
 			'GA' => 'ma Kapon',
 			'GE' => 'ma Katelo',
 			'GH' => 'ma Kana',
 			'GM' => 'ma Kanpija',
 			'GN' => 'ma Kine',
 			'GQ' => 'ma Kinejekatolija',
 			'GR' => 'ma Elena',
 			'GW' => 'ma Kinepisa',
 			'HK' => 'ma Onkon',
 			'HR' => 'ma Lowasi',
 			'HU' => 'ma Mosijo',
 			'ID' => 'ma Intonesija',
 			'IE' => 'ma Alan',
 			'IL' => 'ma Isale',
 			'IN' => 'ma Palata',
 			'IQ' => 'ma Ilakija',
 			'IR' => 'ma Ilan',
 			'IS' => 'ma Isilan',
 			'IT' => 'ma Italija',
 			'JO' => 'ma Utun',
 			'JP' => 'ma Nijon',
 			'KE' => 'ma Kenja',
 			'KH' => 'ma Kanpusi',
 			'KI' => 'ma Kilipasi',
 			'KM' => 'ma Komo',
 			'KP' => 'ma Anku',
 			'KR' => 'ma Soson',
 			'KW' => 'ma Kuwasi',
 			'LB' => 'ma Lunpan',
 			'LI' => 'ma Lisensan',
 			'LK' => 'ma Lanka',
 			'LR' => 'ma Lapewija',
 			'LS' => 'ma Lesoto',
 			'LT' => 'ma Lijatuwa',
 			'LU' => 'ma Lusepu',
 			'LV' => 'ma Lawi',
 			'LY' => 'ma Lipija',
 			'MA' => 'ma Malipe',
 			'MD' => 'ma Motowa',
 			'MG' => 'ma Malakasi',
 			'MK' => 'ma Maketonija',
 			'ML' => 'ma Mali',
 			'MM' => 'ma Mijama',
 			'MR' => 'ma Mulitanija',
 			'MU' => 'ma Mowisi',
 			'MW' => 'ma Malawi',
 			'MX' => 'ma Mesiko',
 			'MY' => 'ma Malasija',
 			'MZ' => 'ma Mosanpi',
 			'NA' => 'ma Namipija',
 			'NE' => 'ma Nise',
 			'NG' => 'ma Naselija',
 			'NL' => 'ma Netelan',
 			'NO' => 'ma Nosiki',
 			'NZ' => 'ma Nusilan',
 			'OM' => 'ma Uman',
 			'PE' => 'ma Pelu',
 			'PG' => 'ma Papuwanijukini',
 			'PH' => 'ma Pilipina',
 			'PK' => 'ma Pakisan',
 			'PL' => 'ma Posuka',
 			'PS' => 'ma Pilisin',
 			'PT' => 'ma Potuke',
 			'RO' => 'ma Lomani',
 			'RS' => 'ma Sopisi',
 			'RU' => 'ma Lusi',
 			'RW' => 'ma Luwanta',
 			'SA' => 'ma Sawusi',
 			'SD' => 'ma Sutan',
 			'SE' => 'ma Sensa',
 			'SG' => 'ma Sinkapo',
 			'SI' => 'ma Lowensina',
 			'SK' => 'ma Lowenki',
 			'SL' => 'ma Sijelalijon',
 			'SM' => 'ma Samalino',
 			'SN' => 'ma Seneka',
 			'SO' => 'ma Somalija',
 			'SS' => 'ma Sasutan',
 			'SY' => 'ma Sulija',
 			'SZ' => 'ma Sawasi',
 			'TD' => 'ma Sate',
 			'TG' => 'ma Toko',
 			'TH' => 'ma Tawi',
 			'TN' => 'ma Tunisi',
 			'TO' => 'ma Tona',
 			'TR' => 'ma Tuki',
 			'TV' => 'ma Tuwalu',
 			'TZ' => 'ma Tansanija',
 			'UA' => 'ma Ukawina',
 			'UG' => 'ma Ukanta',
 			'UN' => 'kulupu pi ma ale',
 			'US' => 'ma Mewika',
 			'UZ' => 'ma Opekisan',
 			'VA' => 'ma Wasikano',
 			'VE' => 'ma Penesuwela',
 			'VN' => 'ma Wije',
 			'VU' => 'ma Wanuwatu',
 			'WS' => 'ma Samowa',
 			'YE' => 'ma Jamanija',
 			'ZA' => 'ma Setapika',
 			'ZM' => 'ma Sanpija',
 			'ZW' => 'ma Sinpapuwe',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'numbers' => {
 				'arab' => q{sitelen nanpa Alapi},
 				'latn' => q{sitelen nanpa Lasina},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{nasin pi ma ale},
 			'UK' => q{nasin pi ma Juke},
 			'US' => q{nasin pi ma Mewika},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'toki li {0}',
 			'script' => 'sitelen li {0}',
 			'region' => 'ma li {0}',

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
			auxiliary => qr{[b c d f g h q r v x y z]},
			index => ['A', 'E', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'S', 'T', 'U', 'W'],
			main => qr{[a e i j k l m n o p s t u w]},
			numbers => qr{[\- ‑ / # % + 0 1 2 3 5 6 7 8 9]},
			punctuation => qr{[\- ‑ , ; \: ! ? . '‘’ "“” ( ) \[ \] @ * / #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'E', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'S', 'T', 'U', 'W'], };
},
);


has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
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
					'default' => '#,#0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '%#,#0',
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
					'standard' => {
						'positive' => '¤#,#0.00',
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
					wide => {
						nonleap => [
							'mun #1',
							'mun #2',
							'mun #3',
							'mun #4',
							'mun #5',
							'mun #6',
							'mun #7',
							'mun #8',
							'mun #9',
							'mun #10',
							'mun #11',
							'mun #12'
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
						mon => 'suno esun #1',
						tue => 'suno esun #2',
						wed => 'suno esun #3',
						thu => 'suno esun #4',
						fri => 'suno esun #5',
						sat => 'suno esun #6',
						sun => 'suno esun #7'
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
				'wide' => {
					'am' => q{pi open suno},
					'pm' => q{pi pini suno},
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
		'gregorian' => {
			Hm => q{#HH:mm},
			Hms => q{#HH:mm:ss},
			Hmsv => q{#HH:mm:ss 'lon' v},
			hm => q{#h:mm a},
			hms => q{#h:mm:ss a},
			hmsv => q{#h:mm:ss a 'lon' v},
			yMMMd => q{'sike' #y ) #M ) #d},
			yMd => q{#y)#M)#d},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(tenpo UTC{0}),
		gmtZeroFormat => q(tenpo UTC),
		regionFormat => q(tenpo pi {0}),
		regionFormat => q(tenpo seli suno pi {0}),
		regionFormat => q(tenpo pi {0}),
		'GMT' => {
			long => {
				'standard' => q#tenpo pi ma Keni#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
