=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Trv - Package for language Taroko

=cut

package Locale::CLDR::Locales::Trv;
# This file auto generated from Data\common\main\trv.xml
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
				'bn' => 'patas Monchiara',
 				'de' => 'patas Towjih',
 				'en' => 'patas Ingrisi',
 				'es' => 'patas Espanniu',
 				'fr' => 'patas Bosey',
 				'hi' => 'patas Heyti',
 				'it' => 'patas Itariya',
 				'ja' => 'patas Nihong',
 				'pt' => 'patas Bowdu',
 				'pt_BR' => 'patas Pajey',
 				'ru' => 'patas Ruski',
 				'sr' => 'patas Srpian',
 				'trv' => 'patas Taroko',
 				'und' => 'Ini klayna patas ni',
 				'ur' => 'patas Yurtu',
 				'zh' => 'patas Ipaw',
 				'zh_Hans' => 'Qantan Ipaw patas',
 				'zh_Hant' => 'Baday Ipaw patas',

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
			'Arab' => 'tasan Arapit',
 			'Cyrl' => 'tasan Sirorik',
 			'Hans' => 'Qantan tasan Ipaw',
 			'Hant' => 'Baday tasan Ipaw',
 			'Latn' => 'tasan Ratin',
 			'Zxxx' => 'Unat tasan',
 			'Zzzz' => 'ini klayi tasan ni',

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
			'AQ' => 'alang Nanci',
 			'BA' => 'alang Posniya',
 			'BR' => 'alang Pajey',
 			'BV' => 'alang Puwei',
 			'CH' => 'alang Switjrrant',
 			'CN' => 'alang Ipaw',
 			'DE' => 'alang Towjih',
 			'FR' => 'alang Posey',
 			'GB' => 'alang Inglis',
 			'GS' => 'alang Nanjiouya ni Nansanminji',
 			'HM' => 'alang Htee ni Mayktan',
 			'HR' => 'alang Krowtia',
 			'IN' => 'alang Intu',
 			'IO' => 'alang Inglis niq Intu',
 			'IT' => 'alang Itariya',
 			'JP' => 'alang Nihong',
 			'ME' => 'alang Mondineygrw',
 			'RS' => 'alang Srbia',
 			'RU' => 'alang Ruski',
 			'SM' => 'alang Snmarinow',
 			'TF' => 'alang Posey niq Nan',
 			'US' => 'alang Amarika',
 			'ZZ' => 'ini klayi na alang ni',

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
 				'gregorian' => q{Jiyax Yisu Thulang},
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
			'metric' => q{Snamrika},
 			'US' => q{Snyunaydi},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Kari: {0}',
 			'script' => 'Patas: {0}',
 			'region' => 'Alang: {0}',

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
			auxiliary => qr{[ḏ f ɨ ḻ ṟ ṯ ʉ v z ʼ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e g h i j k l m n {ng} o p q r s t u w x y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} Jiyax),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} Jiyax),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} Tuki),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} Tuki),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0} spngan),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0} spngan),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} Idas),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} Idas),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} Seykn),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} Seykn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} Jiyax iyax sngayan),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} Jiyax iyax sngayan),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} Hnkawas),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} Hnkawas),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yiru|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:mnan|m|no|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AUD' => {
			display_name => {
				'currency' => q(pila Autaria),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(pila Pajey),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(pila Ipaw),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(pila Irow),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(pila Inglis),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(pila Hong Kong),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(pila Intia),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(pila Nihong),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pila Macao),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(pila Nowey),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(pila Ruski),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(pila Taiwan),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(pila America),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ini klayi pila ni),
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
							'Kii',
							'Dhi',
							'Tri',
							'Spi',
							'Rii',
							'Mti',
							'Emi',
							'Mai',
							'Mni',
							'Mxi',
							'Mxk',
							'Mxd'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Kingal idas',
							'Dha idas',
							'Tru idas',
							'Spat idas',
							'Rima idas',
							'Mataru idas',
							'Empitu idas',
							'Maspat idas',
							'Mngari idas',
							'Maxal idas',
							'Maxal kingal idas',
							'Maxal dha idas'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'K',
							'D',
							'T',
							'S',
							'R',
							'M',
							'E',
							'P',
							'A',
							'M',
							'K',
							'D'
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
						mon => 'Kin',
						tue => 'Dha',
						wed => 'Tru',
						thu => 'Spa',
						fri => 'Rim',
						sat => 'Mat',
						sun => 'Emp'
					},
					wide => {
						mon => 'tgKingal jiyax iyax sngayan',
						tue => 'tgDha jiyax iyax sngayan',
						wed => 'tgTru jiyax iyax sngayan',
						thu => 'tgSpac jiyax iyax sngayan',
						fri => 'tgRima jiyax iyax sngayan',
						sat => 'tgMataru jiyax iyax sngayan',
						sun => 'Jiyax sngayan'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'K',
						tue => 'D',
						wed => 'T',
						thu => 'S',
						fri => 'R',
						sat => 'M',
						sun => 'E'
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
					abbreviated => {0 => 'mn1',
						1 => 'mn2',
						2 => 'mn3',
						3 => 'mn4'
					},
					wide => {0 => 'mnprxan',
						1 => 'mndha',
						2 => 'mntru',
						3 => 'mnspat'
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
					'am' => q{Brax kndaax},
					'pm' => q{Baubau kndaax},
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
				'0' => 'BRY',
				'1' => 'BUY'
			},
			wide => {
				'0' => 'Brah jikan Yisu Thulang',
				'1' => 'Bukuy jikan Yisu Thulang'
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
		'generic' => {
			Hm => q{H:mm},
			MEd => q{E, M-d},
			MMMEd => q{E MMM d},
			MMMMEd => q{E MMMM d},
			Md => q{M-d},
			y => q{y},
			yM => q{y-M},
			yMEd => q{E, y-M-d},
			yMMM => q{y MMM},
			yMMMEd => q{E, y MMM d},
			yMMMM => q{y MMMM},
			yQ => q{y Q},
			yQQQ => q{y QQQ},
		},
		'gregorian' => {
			Hm => q{H:mm},
			MEd => q{E, M-d},
			MMMEd => q{E MMM d},
			MMMMEd => q{E MMMM d},
			Md => q{M-d},
			yM => q{y-M},
			yMEd => q{E, y-M-d},
			yMMMEd => q{E, y MMM d},
			yQ => q{y Q},
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
		gmtFormat => q(JQG{0}),
		regionFormat => q(Jikan {0}),
		'America/Anchorage' => {
			exemplarCity => q#Jikan alang Ankriji#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Jikan alang Grad#,
		},
		'America/Chicago' => {
			exemplarCity => q#Jikan alang Jiciak#,
		},
		'America/Denver' => {
			exemplarCity => q#Jikan alang Tanbo#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Jikan alang Intiannaporis#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Jikan alang Rosanci#,
		},
		'America/New_York' => {
			exemplarCity => q#Jikan alang Niuyue#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Jikan alang Bonhuan#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Jikan alang Purank#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Jikan alang Snpaurow#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Jikan Con-Amarika o Karat Rbagan#,
				'generic' => q#Jikan Con-Amarika#,
				'standard' => q#Snegun Jikan Con-Amarika#,
			},
			short => {
				'daylight' => q#JCAKR#,
				'generic' => q#JCA#,
				'standard' => q#SJCA#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Jikan Ton-Amarika o Karat Rbagan#,
				'generic' => q#Jikan Ton-Amarika#,
				'standard' => q#Snegun Jikan Ton-Amarika#,
			},
			short => {
				'daylight' => q#JTAKR#,
				'generic' => q#JTA#,
				'standard' => q#SJTA#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Jikan Hidaw niq Yama-Amarika#,
				'generic' => q#Jikan Yama-Amarika#,
				'standard' => q#Snegun Jikan Yama-Amarika#,
			},
			short => {
				'daylight' => q#JHYA#,
				'generic' => q#JYA#,
				'standard' => q#SJYA#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Jikan Amarika-Daybinyan o Karat Rbagan#,
				'generic' => q#Jikan Daybinyan#,
				'standard' => q#Snegun Jikan Amarika-Daybinyan#,
			},
			short => {
				'daylight' => q#JADKR#,
				'generic' => q#JD#,
				'standard' => q#SJAD#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Jikan Yayun Tasiyan o Karat Rbagan#,
				'generic' => q#Jikan Yayun Tasiyan#,
				'standard' => q#Snegun Jikan Yayun Tasiyan#,
			},
			short => {
				'daylight' => q#JYTKR#,
				'generic' => q#JYT#,
				'standard' => q#SJYT#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ini klayi ka Jikan hini#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Jikan Conow o Karat Rbagan#,
				'generic' => q#Jikan Conow#,
				'standard' => q#Snegun Jikan Conow#,
			},
			short => {
				'daylight' => q#JCKR#,
				'generic' => q#JC#,
				'standard' => q#JC#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Jikan Tonow o Karat Rbagan#,
				'generic' => q#Jikan Tonow#,
				'standard' => q#Snegun Jikan Tonow#,
			},
			short => {
				'daylight' => q#JTKR#,
				'generic' => q#JT#,
				'standard' => q#JT#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Jikan Siow o Karat Rbagan#,
				'generic' => q#Jikan Siow#,
				'standard' => q#Snegun Jikan Siow#,
			},
			short => {
				'daylight' => q#JSKR#,
				'generic' => q#JS#,
				'standard' => q#JS#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Jikan Quri Grinweyji#,
			},
			short => {
				'standard' => q#JQG#,
			},
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Jikan alang Honoruru#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
