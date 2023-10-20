=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Lkt - Package for language Lakota

=cut

package Locale::CLDR::Locales::Lkt;
# This file auto generated from Data\common\main\lkt.xml
#	on Fri 13 Oct  9:25:28 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
				'ab' => 'Abkhaz Iyápi',
 				'ady' => 'Adyghe Iyápi',
 				'ae' => 'Avestan Iyápi',
 				'af' => 'Afrikaans Iyápi',
 				'alt' => 'Itóǧata Altai Iyápi',
 				'am' => 'Amharic Iyápi',
 				'ar' => 'Arab Iyápi',
 				'arp' => 'Maȟpíya Tȟó Iyápi',
 				'as' => 'Assamese Iyápi',
 				'av' => 'Avaric Iyápi',
 				'az' => 'Azerbaijani Iyápi',
 				'ba' => 'Bashkir Iyápi',
 				'bal' => 'Baluchi Iyápi',
 				'bax' => 'Bamun Iyápi',
 				'be' => 'Belarus Iyápi',
 				'bej' => 'Beja Iyápi',
 				'bg' => 'Bulgar Iyápi',
 				'bn' => 'Bengali Iyápi',
 				'bo' => 'Tibetan Iyápi',
 				'bs' => 'Bosnia Iyápi',
 				'bua' => 'Buriat Iyápi',
 				'ca' => 'Catalan Iyápi',
 				'ce' => 'Chechen Iyápi',
 				'chm' => 'Mari Iyápi',
 				'chr' => 'Cherokee Iyápi',
 				'chy' => 'Šahíyela Iyápi',
 				'cop' => 'Coptic Iyápi',
 				'cr' => 'Maštíŋča Oyáte Iyápi',
 				'crh' => 'Crimean Turkish Iyápi',
 				'cs' => 'Czech Iyápi',
 				'cv' => 'Chuvash Iyápi',
 				'cy' => 'Wales Iyápi',
 				'da' => 'Dane Iyápi',
 				'dak' => 'Dakȟótiyapi',
 				'dar' => 'Dargwa Iyápi',
 				'de' => 'Iyášiča Iyápi',
 				'doi' => 'Dogri Iyápi',
 				'el' => 'Greece Iyápi',
 				'en' => 'Wašíčuiyapi',
 				'en_GB' => 'Šagláša Wašíčuiyapi',
 				'en_US' => 'Mílahaŋska Wašíčuiyapi',
 				'eo' => 'Esperanto Iyápi',
 				'es' => 'Spayóla Iyápi',
 				'es_419' => 'Wiyóȟpeyata Spayóla Iyápi',
 				'es_ES' => 'Spayólaȟča Iyápi',
 				'et' => 'Estonia Iyápi',
 				'eu' => 'Basque Iyápi',
 				'fa' => 'Persian Iyápi',
 				'fi' => 'Finnish Iyápi',
 				'fil' => 'Filipino Iyápi',
 				'fj' => 'Fiji Iyápi',
 				'fo' => 'Faroese Iyápi',
 				'fr' => 'Wašíču Ikčéka Iyápi',
 				'ga' => 'Irish Iyápi',
 				'gba' => 'Gbaya Iyápi',
 				'gl' => 'Galician Iyápi',
 				'gn' => 'Guarani Iyápi',
 				'gu' => 'Gujarati Iyápi',
 				'ha' => 'Hausa Iyápi',
 				'haw' => 'Hawaiian Iyápi',
 				'he' => 'Hebrew Iyápi',
 				'hi' => 'Hindi Iyápi',
 				'hr' => 'Croatian Iyápi',
 				'ht' => 'Haiti Iyápi',
 				'hu' => 'Hungary Iyápi',
 				'hy' => 'Armenia Iyápi',
 				'id' => 'Indonesia Iyápi',
 				'ig' => 'Igbo Iyápi',
 				'inh' => 'Ingush Iyápi',
 				'is' => 'Iceland Iyápi',
 				'it' => 'Italia Iyápi',
 				'ja' => 'Kisúŋla Iyápi',
 				'jv' => 'Java Iyápi',
 				'ka' => 'Georia Iyápi',
 				'kaa' => 'Kara-Kalpak Iyápi',
 				'kbd' => 'Kabardian Iyápi',
 				'kk' => 'Kazakh Iyápi',
 				'km' => 'Khmer Iyápi',
 				'kn' => 'Kannada Iyápi',
 				'ko' => 'Korea Iyápi',
 				'ks' => 'Kashmir Iyápi',
 				'ku' => 'Kurd Iyápi',
 				'ky' => 'Kirghiz Iyápi',
 				'la' => 'Latin Iyápi',
 				'lah' => 'Lahnda Iyápi',
 				'lb' => 'Luxembourg Iyápi',
 				'lkt' => 'Lakȟólʼiyapi',
 				'lo' => 'Lao Iyápi',
 				'lt' => 'Lithuania Iyápilt',
 				'lus' => 'Mizo Iyápi',
 				'lv' => 'Latvia Iyápi',
 				'mg' => 'Malagasy Iyápi',
 				'mi' => 'Maori Iyápi',
 				'mk' => 'Macedonia Iyápi',
 				'ml' => 'Malayalam Iyápi',
 				'mni' => 'Namipuri Iyápi',
 				'mr' => 'Marathi Iyápi',
 				'ms' => 'Malay Iyápi',
 				'mt' => 'Maltese Iyápi',
 				'my' => 'Burmese Iyápi',
 				'ne' => 'Nepal Iyápi',
 				'nl' => 'Dutch Iyápi',
 				'nl_BE' => 'Flemish Iyápi',
 				'nv' => 'Šináglegleǧa Iyápi',
 				'oj' => 'Ȟaȟátȟuŋwaŋ Iyápi',
 				'or' => 'Oriya Iyápi',
 				'pa' => 'Punjabi Iyápi',
 				'pl' => 'Polish Iyápi',
 				'ps' => 'Pashto Iyápi',
 				'pt' => 'Portuguese Iyápi',
 				'qu' => 'Quechua Iyápi',
 				'rm' => 'Romansh Iyápi',
 				'ro' => 'Romanian Iyápi',
 				'ru' => 'Russia Iyápi',
 				'sa' => 'Sanskrit Iyápi',
 				'sd' => 'Sindhi Iyápi',
 				'si' => 'Sinhala Iyápi',
 				'sk' => 'Slovak Iyápi',
 				'sl' => 'Slovenian Iyápi',
 				'so' => 'Somali Iyápi',
 				'sq' => 'Albanian Iyápi',
 				'sr' => 'Serbia Iyápi',
 				'su' => 'Sundanese Iyápi',
 				'sv' => 'Swedish Iyápi',
 				'sw' => 'Swahili Iyápi',
 				'swb' => 'Comonian Iyápi',
 				'ta' => 'Tamil Iyápi',
 				'te' => 'Telugu Iyápi',
 				'tg' => 'Tajik Iyápi',
 				'th' => 'Thai Iyápi',
 				'ti' => 'Tigrinya Iyápi',
 				'tk' => 'Turkmen Iyápi',
 				'to' => 'Tongan Iyápi',
 				'tr' => 'Turkish Iyápi',
 				'tt' => 'Tatar Iyápi',
 				'ug' => 'Uyghur Iyápi',
 				'uk' => 'Ukrain Iyápi',
 				'und' => 'Tukté iyápi tȟaŋíŋ šni',
 				'ur' => 'Urdu Iyápi',
 				'uz' => 'Uzbek Iyápi',
 				'vi' => 'Vietnamese Iyápi',
 				'wo' => 'Wolof Iyápi',
 				'xh' => 'Xhosa Iyápi',
 				'yo' => 'Yoruba Iyápi',
 				'zh' => 'Pȟečhókaŋ Háŋska Iyápi',
 				'zh_Hans' => 'Pȟečhókaŋ Háŋska Iyápi Ikčéka',
 				'zh_Hant' => 'Pȟečhókaŋ Háŋska Iyápi Ȟče',
 				'zu' => 'Zulu Iyápi',
 				'zza' => 'Zaza Iyápi',

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
			'001' => 'Makȟásitomni',
 			'002' => 'Hásapa Makȟáwita',
 			'019' => 'Khéya Wíta',
 			'142' => 'Hazíla Makȟáwita',
 			'150' => 'Wašíču Makȟáwita',
 			'CA' => 'Uŋčíyapi Makȟóčhe',
 			'CN' => 'Pȟečhókaŋhaŋska Makȟóčhe',
 			'DE' => 'Iyášiča Makȟóčhe',
 			'ES' => 'Spayólaȟče Makȟóčhe',
 			'JP' => 'Kisúŋla Makȟóčhe',
 			'MX' => 'Spayóla Makȟóčhe',
 			'US' => 'Mílahaŋska Tȟamákȟočhe',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'US' => q{US},

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
			auxiliary => qr{[c d f {ȟʼ} j q r {sʼ} {šʼ} v x]},
			index => ['A', 'B', 'Č', 'E', 'G', 'Ǧ', 'H', 'Ȟ', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'S', 'Š', 'T', 'U', 'W', 'Y', 'Z', 'Ž'],
			main => qr{[a á {aŋ} b č {čh} {čʼ} e é g ǧ h ȟ i í {iŋ} k {kh} {kȟ} {kʼ} l m n ŋ o ó p {ph} {pȟ} {pʼ} s š t {th} {tȟ} {tʼ} u ú {uŋ} w y z ž ʼ]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . " “ ” ( ) \[ \] @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Č', 'E', 'G', 'Ǧ', 'H', 'Ȟ', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'S', 'Š', 'T', 'U', 'W', 'Y', 'Z', 'Ž'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(-čháŋ),
						'other' => q({0}-čháŋ),
					},
					'foot' => {
						'name' => q(siíyutȟapi),
						'other' => q(siíyutȟapi {0}),
					},
					'hour' => {
						'name' => q(Owápȟe),
						'other' => q(Owápȟe {0}),
					},
					'inch' => {
						'name' => q(oíyutȟe čísčila),
						'other' => q(oíyutȟe čísčila {0}),
					},
					'mile' => {
						'name' => q(makhíyutȟapi),
						'other' => q(makhíyutȟapi {0}),
					},
					'month' => {
						'name' => q(Wíyawapi),
						'other' => q(Wíyawapi {0}),
					},
					'pound' => {
						'name' => q(tkeíyutȟapi),
						'other' => q(tkeíyutȟapi {0}),
					},
					'second' => {
						'name' => q(Okpí),
						'other' => q(Okpí {0}),
					},
					'week' => {
						'name' => q(okó),
						'other' => q(okó {0}),
					},
					'yard' => {
						'name' => q(čhaéglepi),
						'other' => q(čhaéglepi {0}),
					},
					'year' => {
						'name' => q(ómakȟa),
						'other' => q(ómakȟa {0}),
					},
				},
				'narrow' => {
					'celsius' => {
						'other' => q({0}°C),
					},
					'day' => {
						'other' => q({0}-čháŋ),
					},
					'fahrenheit' => {
						'other' => q({0}°),
					},
					'foot' => {
						'other' => q(siíyutȟapi {0}),
					},
					'hour' => {
						'other' => q(Owápȟe {0}),
					},
					'inch' => {
						'other' => q({0}″),
					},
					'mile' => {
						'other' => q({0} makh),
					},
					'month' => {
						'other' => q(Wí {0}),
					},
					'pound' => {
						'other' => q({0}#),
					},
					'second' => {
						'other' => q(Okpí {0}),
					},
					'week' => {
						'other' => q(okó {0}),
					},
					'yard' => {
						'other' => q(čhaéglepi {0}),
					},
					'year' => {
						'other' => q(ómakȟa {0}),
					},
				},
				'short' => {
					'day' => {
						'name' => q(-čháŋ),
						'other' => q({0}-čháŋ),
					},
					'foot' => {
						'name' => q(siíyutȟapi),
						'other' => q(siíyutȟapi {0}),
					},
					'hour' => {
						'name' => q(Owápȟe),
						'other' => q(Owápȟe {0}),
					},
					'inch' => {
						'name' => q(oíyutȟe čísčila),
						'other' => q(oíyutȟe čísčila {0}),
					},
					'mile' => {
						'name' => q(makhíyutȟapi),
						'other' => q(makhíyutȟapi {0}),
					},
					'month' => {
						'name' => q(Wíyawapi),
						'other' => q(Wíyawapi {0}),
					},
					'pound' => {
						'name' => q(tkeíyutȟapi),
						'other' => q(tkeíyutȟapi {0}),
					},
					'second' => {
						'name' => q(Okpí),
						'other' => q(Okpí {0}),
					},
					'week' => {
						'name' => q(okó),
						'other' => q(okó {0}),
					},
					'yard' => {
						'name' => q(čhaéglepi),
						'other' => q(čhaéglepi {0}),
					},
					'year' => {
						'name' => q(ómakȟa),
						'other' => q(ómakȟa {0}),
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
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'USD' => {
			symbol => '$',
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
							'Wiótheȟika Wí',
							'Thiyóȟeyuŋka Wí',
							'Ištáwičhayazaŋ Wí',
							'Pȟežítȟo Wí',
							'Čhaŋwápetȟo Wí',
							'Wípazukȟa-wašté Wí',
							'Čhaŋpȟásapa Wí',
							'Wasútȟuŋ Wí',
							'Čhaŋwápeǧi Wí',
							'Čhaŋwápe-kasná Wí',
							'Waníyetu Wí',
							'Tȟahékapšuŋ Wí'
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
					narrow => {
						mon => 'W',
						tue => 'N',
						wed => 'Y',
						thu => 'T',
						fri => 'Z',
						sat => 'O',
						sun => 'A'
					},
					wide => {
						mon => 'Aŋpétuwaŋži',
						tue => 'Aŋpétunuŋpa',
						wed => 'Aŋpétuyamni',
						thu => 'Aŋpétutopa',
						fri => 'Aŋpétuzaptaŋ',
						sat => 'Owáŋgyužažapi',
						sun => 'Aŋpétuwakȟaŋ'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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

no Moo;

1;

# vim: tabstop=4
