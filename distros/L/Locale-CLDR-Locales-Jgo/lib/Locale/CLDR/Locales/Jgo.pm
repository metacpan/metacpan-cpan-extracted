=head1

Locale::CLDR::Locales::Jgo - Package for language Ngomba

=cut

package Locale::CLDR::Locales::Jgo;
# This file auto generated from Data\common\main\jgo.xml
#	on Fri 29 Apr  7:11:03 pm GMT

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
				'ar' => 'Alâbɛ',
 				'de' => 'Njáman',
 				'el' => 'Ŋgɛlɛ̂k',
 				'en' => 'Aŋgɛlúshi',
 				'fr' => 'Fɛlánci',
 				'jgo' => 'Ndaꞌa',
 				'und' => 'cú-pʉɔ yi pɛ́ ká kɛ́ jí',
 				'zh' => 'Shinwâ',

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
			'Latn' => 'mík -ŋwaꞌnɛ yi ɛ́ líŋɛ́nɛ Latɛ̂ŋ',
 			'Zxxx' => 'ntúu yi pɛ́ ká ŋwaꞌnε',
 			'Zzzz' => 'ntɛ-ŋwaꞌnɛ yí pɛ́ ká kɛ́ jí',

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
			'001' => 'Mbí',
 			'002' => 'Afɛlîk',
 			'019' => 'Amɛlîk',
 			'142' => 'Azî',
 			'150' => 'Ʉlôp',
 			'AO' => 'Aŋgɔ́la',
 			'AR' => 'Ajɛntîn',
 			'BF' => 'Mbulukína Fásɔ',
 			'BI' => 'Mbulundí',
 			'BJ' => 'Mbɛnɛ̂ŋ',
 			'BO' => 'Mbɔlivî',
 			'BR' => 'Mbɛlazîl',
 			'BW' => 'Mbɔtswána',
 			'CA' => 'Kanadâ',
 			'CD' => 'Kɔ́ŋgɔ-Kinshása',
 			'CG' => 'Kɔ́ŋgɔ-Mbɛlazavîl',
 			'CH' => 'Sẅísɛ',
 			'CI' => 'Kɔ́t Ndivwâ',
 			'CL' => 'Cíllɛ',
 			'CM' => 'Kamɛlûn',
 			'CN' => 'Shîn',
 			'CO' => 'Kɔllɔmbî',
 			'CU' => 'Kúba',
 			'DE' => 'Njáman',
 			'DJ' => 'Njimbúti',
 			'DZ' => 'Aljɛlî',
 			'EC' => 'Ɛkwandɔ̂',
 			'EG' => 'Ɛjíptɛ',
 			'ER' => 'Ɛlitɛlɛ́ya',
 			'ES' => 'Ɛspániya',
 			'ET' => 'Ɛtiyɔpî',
 			'FR' => 'Fɛlánci',
 			'GA' => 'Ŋgabɔ̂ŋ',
 			'GH' => 'Ŋgána',
 			'GM' => 'Ŋgambî',
 			'GN' => 'Ŋginɛ̂',
 			'GQ' => 'Ŋginɛ̂ Ɛkwatɔliyâl',
 			'GR' => 'Ŋgɛlɛ̂k',
 			'GW' => 'Ŋginɛ̂ Mbisáwu',
 			'IL' => 'Islayɛ̂l',
 			'IN' => 'Ándɛ',
 			'IQ' => 'Ilâk',
 			'IT' => 'Italî',
 			'JP' => 'Japɔ̂n',
 			'KE' => 'Kɛ́nya',
 			'KM' => 'Kɔmɔ́lɔshi',
 			'LR' => 'Libɛrî',
 			'LS' => 'Lɛsɔ́tɔ',
 			'LY' => 'Libî',
 			'MA' => 'Mɔlɔ̂k',
 			'MG' => 'Mándaŋgasɛkâ',
 			'ML' => 'Malî',
 			'MR' => 'Mɔlitanî',
 			'MW' => 'Maláwi',
 			'MX' => 'Mɛksîk',
 			'MZ' => 'Mɔzambîk',
 			'NA' => 'Namimbî',
 			'NE' => 'Nijɛ̂',
 			'NG' => 'Ninjɛliyâ',
 			'NO' => 'Nɔlɛvɛ́jɛ',
 			'PE' => 'Pɛlû',
 			'RE' => 'Lɛ́uniyɔ̂n',
 			'RS' => 'Sɛlɛbî',
 			'RU' => 'Lusî',
 			'RW' => 'Luwánda',
 			'SC' => 'Pɛsɛ́shɛl',
 			'SD' => 'Sundân',
 			'SL' => 'Siyɛ́la Lɛɔ̂n',
 			'SN' => 'Sɛnɛgâl',
 			'SO' => 'Sɔmalî',
 			'ST' => 'Sáwɔŋ Tɔmɛ́ nɛ́ Pɛlínsipɛ',
 			'SZ' => 'Swazilân',
 			'TD' => 'Cât',
 			'TG' => 'Tɔ́ŋgɔ',
 			'TN' => 'Tunizî',
 			'TZ' => 'Tanzanî',
 			'UG' => 'Uŋgánda',
 			'VE' => 'Vɛnɛzwɛ́la',
 			'YT' => 'Mayɔ̂t',
 			'ZM' => 'Zambî',
 			'ZW' => 'Zimbámbwɛ',
 			'ZZ' => 'ŋgɔŋ yi pɛ́ ká kɛ́ jʉɔ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'currency' => 'Ŋkáp',
 			'numbers' => 'Pɛnɔ́mba',

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
 				'gregorian' => q{mɛlɛ́ꞌ-mɛkát},
 			},
 			'numbers' => {
 				'latn' => q{pɛnɔ́mba},
 			},

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
			auxiliary => qr{(?^u:[e o q r x])},
			index => ['A', 'B', 'C', 'D', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'Ɔ', 'P', '{Pf}', 'S', '{Sh}', 'T', '{Ts}', 'U', 'Ʉ', '{Ʉ\u0308}', 'V', 'W', 'Ẅ', 'Y', 'Z', 'Ꞌ'],
			main => qr{(?^u:[a á â ǎ b c d ɛ {ɛ́} {ɛ̀} {ɛ̂} {ɛ̌} {ɛ̄} f g h i í î ǐ j k l m ḿ {m̀} {m̄} n ń ǹ {n̄} ŋ {ŋ́} {ŋ̀} {ŋ̄} ɔ {ɔ́} {ɔ̂} {ɔ̌} p {pf} s {sh} t {ts} u ú û ǔ ʉ {ʉ́} {ʉ̂} {ʉ̌} {ʉ̈} v w ẅ y z ꞌ])},
			punctuation => qr{(?^u:[\- , ; \: ! ? . ‹ › « »])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'Ɔ', 'P', '{Pf}', 'S', '{Sh}', 'T', '{Ts}', 'U', 'Ʉ', '{Ʉ\u0308}', 'V', 'W', 'Ẅ', 'Y', 'Z', 'Ꞌ'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
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
	default		=> qq{‹},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{›},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(lɛ́Ꞌ),
						'one' => q({0} lɛ́Ꞌ),
						'other' => q({0} lɛ́Ꞌ),
					},
					'hour' => {
						'name' => q(háwa),
						'one' => q({0} háwa),
						'other' => q({0} háwa),
					},
					'minute' => {
						'name' => q(minút),
						'one' => q({0} minút),
						'other' => q({0} minút),
					},
					'month' => {
						'name' => q(pɛsaŋ),
						'one' => q(pɛsaŋ {0}),
						'other' => q(pɛsaŋ {0}),
					},
					'year' => {
						'name' => q(ŋguꞋ),
						'one' => q(ŋguꞋ {0}),
						'other' => q(ŋguꞋ {0}),
					},
				},
				'short' => {
					'day' => {
						'name' => q(lɛ́Ꞌ),
					},
					'hour' => {
						'name' => q(háwa),
					},
					'minute' => {
						'name' => q(minút),
					},
					'month' => {
						'name' => q(pɛsaŋ),
					},
					'year' => {
						'name' => q(ŋguꞋ),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ɔ́ŋ|ɔ́|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ŋgáŋ|ŋ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, ŋ́gɛ {1}),
				middle => q({0}, ŋ́gɛ {1}),
				end => q({0}, ḿbɛn ŋ́gɛ {1}),
				2 => q({0} pɔp {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
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
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
					'' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'' => '#E0',
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
		'CAD' => {
			display_name => {
				'currency' => q(Ndɔ́la-Kanandâ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Ʉ́lɔ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Ndɔ́la-Amɛlîk),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Fɛlâŋ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ntɛ-ŋkáp yi pɛ́ ká kɛ́ jínɛ),
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
							'Nduŋmbi Saŋ',
							'Pɛsaŋ Pɛ́pá',
							'Pɛsaŋ Pɛ́tát',
							'Pɛsaŋ Pɛ́nɛ́kwa',
							'Pɛsaŋ Pataa',
							'Pɛsaŋ Pɛ́nɛ́ntúkú',
							'Pɛsaŋ Saambá',
							'Pɛsaŋ Pɛ́nɛ́fɔm',
							'Pɛsaŋ Pɛ́nɛ́pfúꞋú',
							'Pɛsaŋ Nɛgɛ́m',
							'Pɛsaŋ Ntsɔ̌pmɔ́',
							'Pɛsaŋ Ntsɔ̌ppá'
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
							'Nduŋmbi Saŋ',
							'Pɛsaŋ Pɛ́pá',
							'Pɛsaŋ Pɛ́tát',
							'Pɛsaŋ Pɛ́nɛ́kwa',
							'Pɛsaŋ Pataa',
							'Pɛsaŋ Pɛ́nɛ́ntúkú',
							'Pɛsaŋ Saambá',
							'Pɛsaŋ Pɛ́nɛ́fɔm',
							'Pɛsaŋ Pɛ́nɛ́pfúꞋú',
							'Pɛsaŋ Nɛgɛ́m',
							'Pɛsaŋ Ntsɔ̌pmɔ́',
							'Pɛsaŋ Ntsɔ̌ppá'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Nduŋmbi Saŋ',
							'Pɛsaŋ Pɛ́pá',
							'Pɛsaŋ Pɛ́tát',
							'Pɛsaŋ Pɛ́nɛ́kwa',
							'Pɛsaŋ Pataa',
							'Pɛsaŋ Pɛ́nɛ́ntúkú',
							'Pɛsaŋ Saambá',
							'Pɛsaŋ Pɛ́nɛ́fɔm',
							'Pɛsaŋ Pɛ́nɛ́pfúꞋú',
							'Pɛsaŋ Nɛgɛ́m',
							'Pɛsaŋ Ntsɔ̌pmɔ́',
							'Pɛsaŋ Ntsɔ̌ppá'
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
							'Nduŋmbi Saŋ',
							'Pɛsaŋ Pɛ́pá',
							'Pɛsaŋ Pɛ́tát',
							'Pɛsaŋ Pɛ́nɛ́kwa',
							'Pɛsaŋ Pataa',
							'Pɛsaŋ Pɛ́nɛ́ntúkú',
							'Pɛsaŋ Saambá',
							'Pɛsaŋ Pɛ́nɛ́fɔm',
							'Pɛsaŋ Pɛ́nɛ́pfúꞋú',
							'Pɛsaŋ Nɛgɛ́m',
							'Pɛsaŋ Ntsɔ̌pmɔ́',
							'Pɛsaŋ Ntsɔ̌ppá'
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
						mon => 'Mɔ́ndi',
						tue => 'Ápta Mɔ́ndi',
						wed => 'Wɛ́nɛsɛdɛ',
						thu => 'Tɔ́sɛdɛ',
						fri => 'Fɛlâyɛdɛ',
						sat => 'Sásidɛ',
						sun => 'Sɔ́ndi'
					},
					narrow => {
						mon => 'Mɔ́',
						tue => 'ÁM',
						wed => 'Wɛ́',
						thu => 'Tɔ́',
						fri => 'Fɛ',
						sat => 'Sá',
						sun => 'Sɔ́'
					},
					wide => {
						mon => 'Mɔ́ndi',
						tue => 'Ápta Mɔ́ndi',
						wed => 'Wɛ́nɛsɛdɛ',
						thu => 'Tɔ́sɛdɛ',
						fri => 'Fɛlâyɛdɛ',
						sat => 'Sásidɛ',
						sun => 'Sɔ́ndi'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mɔ́ndi',
						tue => 'Ápta Mɔ́ndi',
						wed => 'Wɛ́nɛsɛdɛ',
						thu => 'Tɔ́sɛdɛ',
						fri => 'Fɛlâyɛdɛ',
						sat => 'Sásidɛ',
						sun => 'Sɔ́ndi'
					},
					narrow => {
						mon => 'Mɔ́',
						tue => 'ÁM',
						wed => 'Wɛ́',
						thu => 'Tɔ́',
						fri => 'Fɛ',
						sat => 'Sá',
						sun => 'Sɔ́'
					},
					wide => {
						mon => 'Mɔ́ndi',
						tue => 'Ápta Mɔ́ndi',
						wed => 'Wɛ́nɛsɛdɛ',
						thu => 'Tɔ́sɛdɛ',
						fri => 'Fɛlâyɛdɛ',
						sat => 'Sásidɛ',
						sun => 'Sɔ́ndi'
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
					'pm' => q{ŋka mbɔ́t nji},
					'am' => q{mbaꞌmbaꞌ},
				},
				'wide' => {
					'am' => q{mbaꞌmbaꞌ},
					'pm' => q{ŋka mbɔ́t nji},
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
				'0' => 'tsɛttsɛt mɛŋguꞌ mi ɛ́ lɛɛnɛ Kɛlísɛtɔ gɔ ńɔ́',
				'1' => 'tsɛttsɛt mɛŋguꞌ mi ɛ́ fúnɛ Kɛlísɛtɔ tɔ́ mɔ́'
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
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, y MMMM dd},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
		'generic' => {
			Ed => q{E d},
			MEd => q{E, d.M},
			Md => q{d.M},
			yyyyMd => q{M.d.y G},
		},
		'gregorian' => {
			Ed => q{E d},
			MEd => q{E, d.M},
			Md => q{d.M},
			yMd => q{M.d.y},
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
		'generic' => {
			fallback => '{0} – {1}',
		},
		'gregorian' => {
			fallback => '{0} – {1}',
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
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		fallbackFormat => q({1} ({0})),
	 } }
);
no Moo;

1;

# vim: tabstop=4
