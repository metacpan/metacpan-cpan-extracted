=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Jgo - Package for language Ngomba

=cut

package Locale::CLDR::Locales::Jgo;
# This file auto generated from Data\common\main\jgo.xml
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
			auxiliary => qr{[e o q r x]},
			index => ['A', 'B', 'C', 'D', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'Ɔ', 'P', '{Pf}', 'S', '{Sh}', 'T', '{Ts}', 'U', 'Ʉ{Ʉ̈}', 'V', 'WẄ', 'Y', 'Z', 'Ꞌ'],
			main => qr{[aáâǎ b c d ɛ{ɛ́}{ɛ̀}{ɛ̂}{ɛ̌}{ɛ̄} f g h iíîǐ j k l mḿ{m̀}{m̄} nńǹ{n̄} ŋ{ŋ́}{ŋ̀}{ŋ̄} ɔ{ɔ́}{ɔ̂}{ɔ̌} p {pf} s {sh} t {ts} uúûǔ ʉ{ʉ́}{ʉ̂}{ʉ̌}{ʉ̈} v wẅ y z ꞌ]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ‹ › « »]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'Ɔ', 'P', '{Pf}', 'S', '{Sh}', 'T', '{Ts}', 'U', 'Ʉ{Ʉ̈}', 'V', 'WẄ', 'Y', 'Z', 'Ꞌ'], };
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
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} lɛ́Ꞌ),
						'other' => q({0} lɛ́Ꞌ),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} lɛ́Ꞌ),
						'other' => q({0} lɛ́Ꞌ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} háwa),
						'other' => q({0} háwa),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} háwa),
						'other' => q({0} háwa),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} minút),
						'other' => q({0} minút),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} minút),
						'other' => q({0} minút),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q(pɛsaŋ {0}),
						'other' => q(pɛsaŋ {0}),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q(pɛsaŋ {0}),
						'other' => q(pɛsaŋ {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q(ŋguꞋ {0}),
						'other' => q(ŋguꞋ {0}),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q(ŋguꞋ {0}),
						'other' => q(ŋguꞋ {0}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(lɛ́Ꞌ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(lɛ́Ꞌ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(háwa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(háwa),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minút),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minút),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(pɛsaŋ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(pɛsaŋ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ŋguꞋ),
					},
					# Core Unit Identifier
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
					narrow => {
						mon => 'Mɔ́',
						tue => 'ÁM',
						wed => 'Wɛ́',
						thu => 'Tɔ́',
						fri => 'Fɛ',
						sat => 'Sá',
						sun => 'Sɔ́'
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
					'am' => q{mbaꞌmbaꞌ},
					'pm' => q{ŋka mbɔ́t nji},
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
	} },
);

no Moo;

1;

# vim: tabstop=4
