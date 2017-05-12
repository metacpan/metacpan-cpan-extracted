=head1

Locale::CLDR::Locales::Smn - Package for language Inari Sami

=cut

package Locale::CLDR::Locales::Smn;
# This file auto generated from Data\common\main\smn.xml
#	on Fri 29 Apr  7:25:19 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
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
				'ain' => 'ainukielâ',
 				'ar' => 'arabiakielâ',
 				'be' => 'vielgisruošâkielâ',
 				'bg' => 'bulgariakielâ',
 				'chm' => 'marikielâ',
 				'cs' => 'tšeekikielâ',
 				'cu' => 'kirkkoslaavi',
 				'da' => 'tanskakielâ',
 				'de' => 'saksakielâ',
 				'de_AT' => 'Nuorttâriijkâ saksakielâ',
 				'el' => 'kreikakielâ',
 				'en' => 'engâlâskielâ',
 				'en_AU' => 'Australia engâlâskielâ',
 				'en_CA' => 'Kanada engâlâskielâ',
 				'es' => 'espanjakielâ',
 				'et' => 'eestikielâ',
 				'fi' => 'suomâkielâ',
 				'fr' => 'ranskakielâ',
 				'ga' => 'iirikielâ',
 				'grc' => 'toovláškreikakielâ',
 				'he' => 'hepreakielâ',
 				'hr' => 'kroatiakielâ',
 				'hu' => 'uŋgarkielâ',
 				'hy' => 'armeniakielâ',
 				'is' => 'islandkielâ',
 				'it' => 'italiakielâ',
 				'ja' => 'jaapaankielâ',
 				'ku' => 'kurdikielâ',
 				'kv' => 'komikielâ',
 				'la' => 'läättinkielâ',
 				'lv' => 'latviakielâ',
 				'mdf' => 'mokšâkielâ',
 				'mi' => 'maorikielâ',
 				'mk' => 'makedoniakielâ',
 				'mn' => 'mongoliakielâ',
 				'mrj' => 'viestârmarikielâ',
 				'ne' => 'neepaalkielâ',
 				'nl' => 'hollandkielâ',
 				'nn' => 'tárukielâ nynorsk',
 				'no' => 'tárukielâ',
 				'non' => 'toovláštárukielâ',
 				'pl' => 'puolakielâ',
 				'pt' => 'portugalkielâ',
 				'ro' => 'romaniakielâ',
 				'rom' => 'roomaankielâ',
 				'ru' => 'ruošâkielâ',
 				'sa' => 'sanskritkielâ',
 				'se' => 'tavesämikielâ',
 				'sl' => 'sloveniakielâ',
 				'sma' => 'maadâsämikielâ',
 				'smj' => 'juulevsämikielâ',
 				'smn' => 'anarâškielâ',
 				'sms' => 'nuorttâlâškielâ',
 				'sr' => 'serbiakielâ',
 				'sv' => 'ruotâkielâ',
 				'tr' => 'turkkikielâ',
 				'udm' => 'udmurtkielâ',
 				'uk' => 'ukrainakielâ',
 				'vep' => 'vepsäkielâ',
 				'vi' => 'vietnamkielâ',
 				'yue' => 'kantonkiinakielâ',
 				'zh' => 'kiinakielâ',
 				'zh_Hans' => 'oovtâkiärdánis kiinakielâ',
 				'zh_Hant' => 'ärbivuáválâš kiinakielâ',

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
			'FI' => 'Suomâ',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{metrisâš},
 			'UK' => q{brittilâš},
 			'US' => q{ameriklâš},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'kielâ: {0}',
 			'script' => 'čäällimvuáhádâh: {0}',
 			'region' => 'kuávlu: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{(?^u:[à ç é è í ñ ń ó ò q ú ü w x æ ø å ã ö])},
			index => ['A', 'Â', 'B', 'C', 'Č', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'Š', 'T', 'U', 'V', 'Y', 'Z', 'Ž', 'Ä', 'Á'],
			main => qr{(?^u:[a â b c č d đ e f g h i j k l m n ŋ o p r s š t u v y z ž ä á])},
		};
	},
EOT
: sub {
		return { index => ['A', 'Â', 'B', 'C', 'Č', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'Š', 'T', 'U', 'V', 'Y', 'Z', 'Ž', 'Ä', 'Á'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(peeivih),
					},
					'hour' => {
						'name' => q(tiijmeh),
					},
					'microsecond' => {
						'name' => q(mikrosekunteh),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					'millisecond' => {
						'name' => q(millisekunteh),
					},
					'minute' => {
						'name' => q(minutteh),
					},
					'month' => {
						'name' => q(mánuppajeh),
					},
					'nanosecond' => {
						'name' => q(nanosekunteh),
					},
					'second' => {
						'name' => q(sekunteh),
					},
					'week' => {
						'name' => q(ohoh),
					},
					'year' => {
						'name' => q(iveh),
					},
				},
			} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'nan' => q(epiloho),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => '0 tuhháát',
					'other' => '0 tuhháát',
					'two' => '0 tuhháát',
				},
				'10000' => {
					'one' => '00 tuhháát',
					'other' => '00 tuhháát',
					'two' => '00 tuhháát',
				},
				'100000' => {
					'one' => '000 tuhháát',
					'other' => '000 tuhháát',
					'two' => '000 tuhháát',
				},
				'1000000' => {
					'one' => '0 miljovn',
					'other' => '0 miljovn',
					'two' => '0 miljovn',
				},
				'10000000' => {
					'one' => '00 miljovn',
					'other' => '00 miljovn',
					'two' => '00 miljovn',
				},
				'100000000' => {
					'one' => '000 miljovn',
					'other' => '000 miljovn',
					'two' => '000 miljovn',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljard',
					'two' => '0 miljard',
				},
				'10000000000' => {
					'one' => '00 miljard',
					'other' => '00 miljard',
					'two' => '00 miljard',
				},
				'100000000000' => {
					'one' => '000 miljard',
					'other' => '000 miljard',
					'two' => '000 miljard',
				},
				'1000000000000' => {
					'one' => '0 biljovn',
					'other' => '0 biljovn',
					'two' => '0 biljovn',
				},
				'10000000000000' => {
					'one' => '00 biljovn',
					'other' => '00 biljovn',
					'two' => '00 biljovn',
				},
				'100000000000000' => {
					'one' => '000 biljovn',
					'other' => '000 biljovn',
					'two' => '000 biljovn',
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
		'DKK' => {
			display_name => {
				'currency' => q(Tanska ruvnâ),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Eesti ruvnâ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Suomâ märkki),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Island ruvnâ),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvia ruble),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Taažâ ruvnâ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Ruotâ ruvnâ),
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
				'stand-alone' => {
					wide => {
						nonleap => [
							'uđđâivemáánu',
							'kuovâmáánu',
							'njuhčâmáánu',
							'cuáŋuimáánu',
							'vyesimáánu',
							'kesimáánu',
							'syeinimáánu',
							'porgemáánu',
							'čohčâmáánu',
							'roovvâdmáánu',
							'skammâmáánu',
							'juovlâmáánu'
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
						mon => 'vu',
						tue => 'ma',
						wed => 'ko',
						thu => 'tu',
						fri => 'vá',
						sat => 'lá',
						sun => 'pa'
					},
					narrow => {
						mon => 'V',
						tue => 'M',
						wed => 'K',
						thu => 'T',
						fri => 'V',
						sat => 'L',
						sun => 'P'
					},
					wide => {
						mon => 'vuossaargâ',
						tue => 'majebaargâ',
						wed => 'koskoho',
						thu => 'tuorâstuv',
						fri => 'vástuppeeivi',
						sat => 'lávurduv',
						sun => 'pasepeeivi'
					},
				},
				'stand-alone' => {
					wide => {
						mon => 'vuossargâ',
						tue => 'majebargâ',
						wed => 'koskokko',
						thu => 'tuorâstâh',
						fri => 'vástuppeivi',
						sat => 'lávurdâh',
						sun => 'pasepeivi'
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
					abbreviated => {0 => '1. niälj.',
						1 => '2. niälj.',
						2 => '3. niälj.',
						3 => '4. niälj.'
					},
					wide => {0 => '1. niäljádâs',
						1 => '2. niäljádâs',
						2 => '3. niäljádâs',
						3 => '4. niäljádâs'
					},
				},
				'stand-alone' => {
					wide => {0 => '1. niäljádâs',
						1 => '2. niäljádâs',
						2 => '3. niäljádâs',
						3 => '4. niäljádâs'
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

no Moo;

1;

# vim: tabstop=4
